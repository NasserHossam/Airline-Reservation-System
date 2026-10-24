// server.js - COMPLETE VERSION WITH ALL ENDPOINTS
require('dotenv').config();

const express = require('express');
const mysql = require('mysql2');
const bcrypt = require('bcrypt');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { body, validationResult } = require('express-validator');
const crypto = require('crypto');
const { sendBookingConfirmationEmail, sendPasswordResetEmail } = require('./mailer');

// Fail fast with a clear message if required env vars are missing,
// instead of silently connecting with `undefined` values.
const REQUIRED_ENV_VARS = ['DB_HOST', 'DB_USER', 'DB_PASSWORD', 'DB_NAME', 'JWT_SECRET', 'FRONTEND_URL'];
const missingEnvVars = REQUIRED_ENV_VARS.filter((key) => !process.env[key]);
if (missingEnvVars.length > 0) {
    console.error(`Missing required environment variables: ${missingEnvVars.join(', ')}`);
    console.error('Copy Backend/.env.example to Backend/.env and fill in real values.');
    process.exit(1);
}

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors({ origin: process.env.FRONTEND_URL }));
app.use(express.json());

// Basic brute-force protection on auth endpoints
const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 20,
    message: { message: 'Too many attempts, please try again later.' }
});
app.use(['/api/login', '/api/signup', '/api/auth/forgot-password'], authLimiter);

// MySQL Database Connection
const db = mysql.createConnection({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME
});

// Connect to MySQL
db.connect((err) => {
    if (err) {
        console.error('Error connecting to MySQL:', err);
        return;
    }
    console.log(`Connected to ${process.env.DB_NAME} database`);
});

// JWT Secret Key
const JWT_SECRET = process.env.JWT_SECRET;
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '2h';

// ==================== AUTH MIDDLEWARE ====================
// Verifies the JWT sent in the Authorization header and attaches the
// decoded payload to req.user. Any route that needs to know "who is
// making this request" should use this instead of trusting a userId
// that came from the URL or the request body.
function authenticateToken(req, res, next) {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.startsWith('Bearer ') ? authHeader.split(' ')[1] : null;

    if (!token) {
        return res.status(401).json({ message: 'Access token is required' });
    }

    jwt.verify(token, JWT_SECRET, (err, decoded) => {
        if (err) {
            return res.status(403).json({ message: 'Invalid or expired token' });
        }
        req.user = decoded; // { id, email, role }
        next();
    });
}

// Gatekeeps admin-only endpoints (flight/aircraft management, all-bookings view,
// dashboard stats). Must run AFTER authenticateToken so req.user is populated.
function requireAdmin(req, res, next) {
    if (!req.user || req.user.role !== 'Admin') {
        return res.status(403).json({ message: 'Admin access required' });
    }
    next();
}

// ==================== SIGNUP ENDPOINT - CREATES BOTH USER AND PASSENGER ====================
app.post('/api/signup',
  [
    body('name').trim().isLength({ min: 2, max: 100 }).withMessage('Name must be between 2 and 100 characters'),
    body('email').trim().isEmail().withMessage('Please enter a valid email address').normalizeEmail(),
    body('password').isLength({ min: 8 }).withMessage('Password must be at least 8 characters')
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ message: errors.array()[0].msg });
    }

    const { name, email, password } = req.body;

    const nameParts = name.trim().split(' ');
    const fname = nameParts[0];
    const lname = nameParts.slice(1).join(' ') || nameParts[0];

    // Check if email exists in User table
    const checkEmailQuery = 'SELECT * FROM User WHERE Email = ?';
    db.query(checkEmailQuery, [email], async (err, results) => {
        if (err) {
            console.error('Database error:', err);
            return res.status(500).json({ message: 'Server error' });
        }

        if (results.length > 0) {
            return res.status(400).json({ message: 'Email already exists' });
        }

        try {
            const hashedPassword = await bcrypt.hash(password, 10);

            // Start transaction to create both User and Passenger records
            db.beginTransaction((err) => {
                if (err) {
                    console.error('Transaction error:', err);
                    return res.status(500).json({ message: 'Server error' });
                }

                // Step 1: Insert into User table
                const insertUserQuery = 'INSERT INTO User (Fname, Lname, Email, Password, Role) VALUES (?, ?, ?, ?, ?)';
                db.query(insertUserQuery, [fname, lname, email, hashedPassword, 'User'], (err, userResult) => {
                    if (err) {
                        console.error('Insert user error:', err);
                        return db.rollback(() => {
                            res.status(500).json({ message: 'Error creating account' });
                        });
                    }

                    const userId = userResult.insertId;

                    // Note: we deliberately do NOT create a Passenger record here.
                    // A Passenger represents a traveler with real DOB/nationality/
                    // passport info, which we don't have at signup time. Creating
                    // one here previously used fake placeholder values
                    // ('2000-01-01', 'Unknown', a generated TEMP passport number),
                    // which polluted the Passenger table with junk data.
                    // The real Passenger record is created later, with real data
                    // the user types in, via POST /api/passengers/create during
                    // the booking flow (see Passenger/passanger.html).

                    // Commit transaction
                    db.commit((err) => {
                        if (err) {
                            console.error('Commit error:', err);
                            return db.rollback(() => {
                                res.status(500).json({ message: 'Error committing transaction' });
                            });
                        }

                        // Get user data
                        const getUserQuery = 'SELECT UserID, Fname, Lname, Email, Phone, Date_of_Birth, CreatedAt, Role FROM User WHERE UserID = ?';
                        db.query(getUserQuery, [userId], (err, userResults) => {
                            if (err) {
                                console.error('Fetch user error:', err);
                                return res.status(500).json({ message: 'Error fetching user data' });
                            }

                            const user = userResults[0];
                            const token = jwt.sign(
                                { id: user.UserID, email: user.Email, role: user.Role },
                                JWT_SECRET,
                                { expiresIn: JWT_EXPIRES_IN }
                            );

                            console.log(`✅ SUCCESS! Created User (ID: ${userId}) for ${email}`);

                            res.status(201).json({
                                message: 'Account created successfully',
                                user: {
                                    id: user.UserID,
                                    name: `${user.Fname} ${user.Lname}`,
                                    email: user.Email,
                                    phone: user.Phone,
                                    date_of_birth: user.Date_of_Birth,
                                    created_at: user.CreatedAt,
                                    role: user.Role
                                },
                                token: token
                            });
                        });
                    });
                });
            });
        } catch (error) {
            console.error('Hashing error:', error);
            res.status(500).json({ message: 'Server error' });
        }
    });
});



// ==================== LOGIN ENDPOINT ====================
app.post('/api/login',
  [
    body('email').trim().isEmail().withMessage('Please enter a valid email address').normalizeEmail(),
    body('password').notEmpty().withMessage('Password is required')
  ],
  (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ message: errors.array()[0].msg });
    }

    const { email, password } = req.body;

    const query = 'SELECT * FROM User WHERE Email = ?';
    db.query(query, [email], async (err, results) => {
        if (err) {
            console.error('Database error:', err);
            return res.status(500).json({ message: 'Server error' });
        }

        if (results.length === 0) {
            return res.status(401).json({ message: 'Invalid email or password' });
        }

        const user = results[0];

        try {
            const isPasswordValid = await bcrypt.compare(password, user.Password);

            if (!isPasswordValid) {
                return res.status(401).json({ message: 'Invalid email or password' });
            }

            const updateLoginQuery = 'UPDATE User SET Last_Login = NOW() WHERE UserID = ?';
            db.query(updateLoginQuery, [user.UserID]);

            const getUserQuery = 'SELECT UserID, Fname, Lname, Email, Phone, Date_of_Birth, CreatedAt, Role FROM User WHERE UserID = ?';
            db.query(getUserQuery, [user.UserID], (err, userResults) => {
                if (err) {
                    console.error('Fetch user error:', err);
                    return res.status(500).json({ message: 'Error fetching user data' });
                }

                const userData = userResults[0];
                const token = jwt.sign(
                    { id: userData.UserID, email: userData.Email, role: userData.Role },
                    JWT_SECRET,
                    { expiresIn: JWT_EXPIRES_IN }
                );

                res.status(200).json({
                    message: 'Login successful',
                    user: {
                        id: userData.UserID,
                        name: `${userData.Fname} ${userData.Lname}`,
                        email: userData.Email,
                        phone: userData.Phone,
                        date_of_birth: userData.Date_of_Birth,
                        created_at: userData.CreatedAt,
                        role: userData.Role
                    },
                    token: token
                });
            });
        } catch (error) {
            console.error('Password comparison error:', error);
            res.status(500).json({ message: 'Server error' });
        }
    });
});

// ==================== FORGOT PASSWORD ENDPOINT ====================
// Always responds with the same generic message whether or not the email
// exists in the database — this prevents an attacker from using this
// endpoint to discover which emails are registered (user enumeration).
app.post('/api/auth/forgot-password',
  [
    body('email').trim().isEmail().withMessage('Please enter a valid email address').normalizeEmail()
  ],
  (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ message: errors.array()[0].msg });
    }

    const { email } = req.body;
    const genericMessage = { message: 'If an account exists for that email, a password reset link has been sent.' };

    const query = 'SELECT UserID, Fname, Email FROM User WHERE Email = ?';
    db.query(query, [email], (err, results) => {
        if (err) {
            console.error('Database error:', err);
            return res.status(500).json({ message: 'Server error' });
        }

        // Respond immediately either way — don't let the client tell whether
        // the email matched a real account based on response timing/content.
        res.status(200).json(genericMessage);

        if (results.length === 0) {
            return; // no account with this email — silently do nothing further
        }

        const user = results[0];

        // Generate a random token. Only its SHA-256 hash is stored in the
        // database, so even if the DB were leaked, the raw tokens (which
        // are what's needed to actually reset a password) aren't exposed.
        const rawToken = crypto.randomBytes(32).toString('hex');
        const tokenHash = crypto.createHash('sha256').update(rawToken).digest('hex');
        const expiresAt = new Date(Date.now() + 60 * 60 * 1000); // 1 hour from now

        const updateQuery = 'UPDATE User SET ResetPasswordToken = ?, ResetPasswordExpires = ? WHERE UserID = ?';
        db.query(updateQuery, [tokenHash, expiresAt, user.UserID], (updateErr) => {
            if (updateErr) {
                console.error('Failed to store reset token:', updateErr);
                return;
            }

            const resetLink = `${process.env.FRONTEND_URL}/Login/reset-password.html?token=${rawToken}`;
            sendPasswordResetEmail({ Fname: user.Fname, Email: user.Email }, resetLink);
        });
    });
});

// ==================== RESET PASSWORD ENDPOINT ====================
app.post('/api/auth/reset-password',
  [
    body('token').notEmpty().withMessage('Reset token is required'),
    body('newPassword').isLength({ min: 8 }).withMessage('Password must be at least 8 characters long')
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ message: errors.array()[0].msg });
    }

    const { token, newPassword } = req.body;
    const tokenHash = crypto.createHash('sha256').update(token).digest('hex');

    const findQuery = 'SELECT UserID FROM User WHERE ResetPasswordToken = ? AND ResetPasswordExpires > NOW()';
    db.query(findQuery, [tokenHash], async (err, results) => {
        if (err) {
            console.error('Database error:', err);
            return res.status(500).json({ message: 'Server error' });
        }

        if (results.length === 0) {
            return res.status(400).json({ message: 'This reset link is invalid or has expired. Please request a new one.' });
        }

        const userId = results[0].UserID;

        try {
            const hashedPassword = await bcrypt.hash(newPassword, 10);
            const updateQuery = 'UPDATE User SET Password = ?, ResetPasswordToken = NULL, ResetPasswordExpires = NULL WHERE UserID = ?';
            db.query(updateQuery, [hashedPassword, userId], (updateErr) => {
                if (updateErr) {
                    console.error('Failed to update password:', updateErr);
                    return res.status(500).json({ message: 'Server error' });
                }
                res.status(200).json({ message: 'Your password has been reset successfully. You can now log in.' });
            });
        } catch (hashError) {
            console.error('Password hashing error:', hashError);
            res.status(500).json({ message: 'Server error' });
        }
    });
});

// ==================== GET USER PROFILE ====================
app.get('/api/profile/:userId', authenticateToken, (req, res) => {
    const { userId } = req.params;

    // Ownership check: a logged-in user can only view their own profile,
    // not anyone else's just by changing the ID in the URL.
    if (parseInt(userId, 10) !== req.user.id) {
        return res.status(403).json({ message: 'Forbidden' });
    }

    const query = 'SELECT UserID, Fname, Lname, Email, Phone, Date_of_Birth, CreatedAt FROM User WHERE UserID = ?';
    db.query(query, [userId], (err, results) => {
        if (err) {
            console.error('Database error:', err);
            return res.status(500).json({ message: 'Server error' });
        }

        if (results.length === 0) {
            return res.status(404).json({ message: 'User not found' });
        }

        const user = results[0];
        res.status(200).json({
            user: {
                id: user.UserID,
                name: `${user.Fname} ${user.Lname}`,
                email: user.Email,
                phone: user.Phone,
                date_of_birth: user.Date_of_Birth,
                created_at: user.CreatedAt
            }
        });
    });
});

// ==================== UPDATE PROFILE ENDPOINT ====================
app.put('/api/profile/update', authenticateToken, (req, res) => {
    const { userId, name, phone, dob } = req.body;

    if (!userId || !name) {
        return res.status(400).json({ message: 'User ID and name are required' });
    }

    if (parseInt(userId, 10) !== req.user.id) {
        return res.status(403).json({ message: 'Forbidden' });
    }

    const nameParts = name.trim().split(' ');
    const fname = nameParts[0];
    const lname = nameParts.slice(1).join(' ') || nameParts[0];

    // Handle empty date of birth - convert empty string to NULL
    const dateOfBirth = dob && dob.trim() !== '' ? dob : null;
    const phoneNumber = phone && phone.trim() !== '' ? phone : null;

    const updateQuery = 'UPDATE User SET Fname = ?, Lname = ?, Phone = ?, Date_of_Birth = ? WHERE UserID = ?';
    db.query(updateQuery, [fname, lname, phoneNumber, dateOfBirth, userId], (err, result) => {
        if (err) {
            console.error('Update error:', err);
            return res.status(500).json({ message: 'Error updating profile' });
        }

        if (result.affectedRows === 0) {
            return res.status(404).json({ message: 'User not found' });
        }

        const getUserQuery = 'SELECT UserID, Fname, Lname, Email, Phone, Date_of_Birth, CreatedAt FROM User WHERE UserID = ?';
        db.query(getUserQuery, [userId], (err, results) => {
            if (err) {
                console.error('Fetch error:', err);
                return res.status(500).json({ message: 'Error fetching updated data' });
            }

            const user = results[0];

            res.status(200).json({
                message: 'Profile updated successfully',
                user: {
                    id: user.UserID,
                    name: `${user.Fname} ${user.Lname}`,
                    email: user.Email,
                    phone: user.Phone,
                    date_of_birth: user.Date_of_Birth,
                    created_at: user.CreatedAt
                }
            });
        });
    });
});

// ==================== CHANGE PASSWORD ENDPOINT ====================
app.put('/api/profile/change-password', authenticateToken, async (req, res) => {
    const { userId, currentPassword, newPassword } = req.body;

    if (!userId || !currentPassword || !newPassword) {
        return res.status(400).json({ message: 'All fields are required' });
    }

    if (parseInt(userId, 10) !== req.user.id) {
        return res.status(403).json({ message: 'Forbidden' });
    }

    if (newPassword.length < 6) {
        return res.status(400).json({ message: 'Password must be at least 6 characters long' });
    }

    const getUserQuery = 'SELECT Password FROM User WHERE UserID = ?';
    db.query(getUserQuery, [userId], async (err, results) => {
        if (err) {
            console.error('Database error:', err);
            return res.status(500).json({ message: 'Server error' });
        }

        if (results.length === 0) {
            return res.status(404).json({ message: 'User not found' });
        }

        const user = results[0];

        try {
            const isPasswordValid = await bcrypt.compare(currentPassword, user.Password);

            if (!isPasswordValid) {
                return res.status(401).json({ message: 'Current password is incorrect' });
            }

            const hashedPassword = await bcrypt.hash(newPassword, 10);

            const updateQuery = 'UPDATE User SET Password = ? WHERE UserID = ?';
            db.query(updateQuery, [hashedPassword, userId], (err, result) => {
                if (err) {
                    console.error('Update error:', err);
                    return res.status(500).json({ message: 'Error updating password' });
                }

                res.status(200).json({
                    message: 'Password changed successfully'
                });
            });
        } catch (error) {
            console.error('Password error:', error);
            res.status(500).json({ message: 'Server error' });
        }
    });
});

// ==================== GET USER STATISTICS ====================
app.get('/api/profile/stats/:userId', authenticateToken, (req, res) => {
    const { userId } = req.params;

    if (parseInt(userId, 10) !== req.user.id) {
        return res.status(403).json({ message: 'Forbidden' });
    }

    // Get user email first
    const getUserEmailQuery = 'SELECT Email FROM User WHERE UserID = ?';
    db.query(getUserEmailQuery, [userId], (err, userResults) => {
        if (err || userResults.length === 0) {
            return res.status(404).json({ message: 'User not found' });
        }

        const userEmail = userResults[0].Email;

        // Get statistics using the user's email to match with passenger records.
        // Uses a LEFT JOIN starting FROM a one-row constant so this still
        // returns a (zeroed) row for brand-new users who haven't gone through
        // the booking flow yet and therefore have no Passenger record at all
        // (previously a Passenger row was auto-created at signup with fake
        // data; now it's only created for real during booking).
        const statsQuery = `
            SELECT 
                COUNT(DISTINCT b.BookingID) as total_bookings,
                COUNT(DISTINCT CASE WHEN b.Booking_Status IN ('Confirmed', 'Pending') THEN b.BookingID END) as active_bookings,
                COALESCE(SUM(CASE WHEN b.Booking_Status = 'Confirmed' THEN b.Total_Amount ELSE 0 END), 0) as total_spent,
                COUNT(DISTINCT CASE WHEN b.Booking_Status = 'Completed' THEN b.BookingID END) as completed_flights
            FROM (SELECT 1) AS dummy
            LEFT JOIN Passenger p ON p.Email = ?
            LEFT JOIN Booking b ON p.PassengerID = b.PassengerID
        `;

        db.query(statsQuery, [userEmail], (err, statsResults) => {
            if (err) {
                console.error('Stats error:', err);
                return res.status(500).json({ message: 'Error fetching statistics' });
            }

            const stats = statsResults[0];
            
            res.status(200).json({
                stats: {
                    total_flights: parseInt(stats.completed_flights) || 0,
                    active_bookings: parseInt(stats.active_bookings) || 0,
                    total_spent: parseFloat(stats.total_spent) || 0,
                    loyalty_points: Math.floor(parseFloat(stats.total_spent) / 10) || 0
                }
            });
        });
    });
});

// ==================== SEARCH FLIGHTS ENDPOINT ====================
app.get('/api/flights/search', (req, res) => {
    const { origin, destination, date, class: flightClass } = req.query;

    let query = `
        SELECT 
            f.FlightID,
            f.Flight_Number,
            f.Departure_Time,
            f.Arrival_Time,
            f.Flight_Date,
            orig.City AS Origin_City,
            orig.IATA_Code AS Origin_Code,
            dest.City AS Destination_City,
            dest.IATA_Code AS Destination_Code,
            a.Model AS Aircraft_Model,
            fs.Status_Name AS Flight_Status,
            tt.Type_Name AS Ticket_Type,
            tt.Base_Fare,
            tt.TicketTypeID,
            COUNT(CASE WHEN fls.Is_Booked = 0 THEN 1 END) AS Available_Seats
        FROM Flight f
        INNER JOIN Route r ON f.RouteID = r.RouteID
        INNER JOIN Airport orig ON r.Origin_AirportID = orig.AirportID
        INNER JOIN Airport dest ON r.Destination_AirportID = dest.AirportID
        INNER JOIN Aircraft a ON f.AircraftID = a.AircraftID
        INNER JOIN Flight_Status fs ON f.FlightStatusID = fs.FlightStatusID
        INNER JOIN Flight_Seat fls ON f.FlightID = fls.FlightID
        CROSS JOIN Ticket_Type tt
        WHERE fs.Status_Name IN ('Scheduled', 'Boarding')
    `;

    const params = [];

    if (origin && origin.trim() !== '') {
        query += ' AND (orig.City LIKE ? OR orig.IATA_Code LIKE ? OR orig.Airport_Name LIKE ?)';
        const searchTerm = `%${origin.trim()}%`;
        params.push(searchTerm, searchTerm, searchTerm);
    }

    if (destination && destination.trim() !== '') {
        query += ' AND (dest.City LIKE ? OR dest.IATA_Code LIKE ? OR dest.Airport_Name LIKE ?)';
        const searchTerm = `%${destination.trim()}%`;
        params.push(searchTerm, searchTerm, searchTerm);
    }

    if (date && date.trim() !== '') {
        query += ' AND f.Flight_Date = ?';
        params.push(date);
    }

    if (flightClass && flightClass.trim() !== '') {
        query += ' AND tt.Type_Name = ?';
        params.push(flightClass);
    }

    query += ` 
        GROUP BY f.FlightID, f.Flight_Number, f.Departure_Time, f.Arrival_Time, 
                 f.Flight_Date, orig.City, orig.IATA_Code, dest.City, dest.IATA_Code,
                 a.Model, fs.Status_Name, tt.Type_Name, tt.Base_Fare, tt.TicketTypeID
        HAVING Available_Seats > 0
        ORDER BY f.Departure_Time
    `;

    db.query(query, params, (err, results) => {
        if (err) {
            console.error('Search error:', err);
            return res.status(500).json({ message: 'Error searching flights' });
        }

        res.status(200).json({
            flights: results,
            count: results.length
        });
    });
});

// ==================== GET AVAILABLE SEATS FOR FLIGHT - UPDATED ====================
// Replace the existing endpoint in your server.js with this updated version

app.get('/api/flights/:flightId/seats', (req, res) => {
    const { flightId } = req.params;
    const { class: seatClass } = req.query;

    // First, get the aircraft for this flight
    const getAircraftQuery = `
        SELECT AircraftID 
        FROM Flight 
        WHERE FlightID = ?
    `;

    db.query(getAircraftQuery, [flightId], (err, flightResults) => {
        if (err) {
            console.error('Error fetching flight:', err);
            return res.status(500).json({ message: 'Error fetching flight' });
        }

        if (flightResults.length === 0) {
            return res.status(404).json({ message: 'Flight not found' });
        }

        const aircraftId = flightResults[0].AircraftID;

        // Get all seats for this aircraft with their booking status for this flight
        let query = `
            SELECT 
                s.SeatID,
                s.Seat_Number,
                s.Seat_Class,
                COALESCE(fs.Is_Booked, 0) AS Is_Booked
            FROM Seat s
            LEFT JOIN Flight_Seat fs ON s.SeatID = fs.SeatID AND fs.FlightID = ?
            WHERE s.AircraftID = ?
        `;

        const params = [flightId, aircraftId];

        if (seatClass) {
            query += ' AND s.Seat_Class = ?';
            params.push(seatClass);
        }

        query += ' ORDER BY s.Seat_Number';

        db.query(query, params, (err, results) => {
            if (err) {
                console.error('Seats error:', err);
                return res.status(500).json({ message: 'Error fetching seats' });
            }

            console.log(`Found ${results.length} seats for flight ${flightId}`);
            
            res.status(200).json({
                seats: results
            });
        });
    });
});

// ==================== GET AIRPORTS ====================
app.get('/api/airports', (req, res) => {
    const query = 'SELECT * FROM Airport ORDER BY City';
    
    db.query(query, (err, results) => {
        if (err) {
            console.error('Database error:', err);
            return res.status(500).json({ message: 'Error fetching airports' });
        }

        res.status(200).json({
            airports: results
        });
    });
});

// ==================== CREATE PASSENGER ENDPOINT ====================
app.post('/api/passengers/create', authenticateToken, (req, res) => {
    const { fname, lname, email, phone, dob, nationality, passport, gender } = req.body;

    if (!fname || !lname || !dob || !nationality || !passport || !gender) {
        return res.status(400).json({ message: 'All required fields must be provided' });
    }

    const checkQuery = 'SELECT * FROM Passenger WHERE Passport_Number = ?';
    db.query(checkQuery, [passport], (err, results) => {
        if (err) {
            console.error('Database error:', err);
            return res.status(500).json({ message: 'Server error' });
        }

        if (results.length > 0) {
            return res.status(200).json({
                message: 'Passenger already exists',
                passenger: results[0]
            });
        }

        const insertQuery = `
            INSERT INTO Passenger (Fname, Lname, Email, Phone, Date_of_Birth, Nationality, Passport_Number, Gender)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        `;
        
        db.query(insertQuery, [fname, lname, email, phone, dob, nationality, passport, gender], (err, result) => {
            if (err) {
                console.error('Insert error:', err);
                return res.status(500).json({ message: 'Error creating passenger' });
            }

            const getQuery = 'SELECT * FROM Passenger WHERE PassengerID = ?';
            db.query(getQuery, [result.insertId], (err, passengerResults) => {
                if (err) {
                    console.error('Fetch error:', err);
                    return res.status(500).json({ message: 'Error fetching passenger data' });
                }

                res.status(201).json({
                    message: 'Passenger created successfully',
                    passenger: passengerResults[0]
                });
            });
        });
    });
});

// ==================== GET PASSENGER BY EMAIL - ADD THIS HERE ====================
app.get('/api/passengers/by-email/:email', authenticateToken, (req, res) => {
    const { email } = req.params;
    
    const query = 'SELECT PassengerID, Fname, Lname, Email FROM Passenger WHERE Email = ?';
    db.query(query, [email], (err, results) => {
        if (err) {
            console.error('Database error:', err);
            return res.status(500).json({ message: 'Server error' });
        }

        if (results.length === 0) {
            return res.status(404).json({ message: 'Passenger not found' });
        }

        res.status(200).json({
            passenger: results[0]
        });
    });
});

// ==================== CREATE BOOKING ENDPOINT - FIXED ====================
app.post('/api/bookings/create', authenticateToken, (req, res) => {
    const { passengerId, flightId, seatId, ticketTypeId, paymentMethodId } = req.body;

    console.log('📥 Booking request received:', { passengerId, flightId, seatId, ticketTypeId, paymentMethodId });

    if (!passengerId || !flightId || !seatId || !ticketTypeId || !paymentMethodId) {
        return res.status(400).json({ message: 'All fields are required' });
    }

    db.beginTransaction((err) => {
        if (err) {
            console.error('Transaction error:', err);
            return res.status(500).json({ message: 'Transaction error' });
        }

        // Check if seat exists in Flight_Seat table, if not create it
        const checkOrCreateSeatQuery = `
            INSERT INTO Flight_Seat (FlightID, SeatID, Is_Booked)
            SELECT ?, ?, 0
            WHERE NOT EXISTS (
                SELECT 1 FROM Flight_Seat WHERE FlightID = ? AND SeatID = ?
            )
        `;

        db.query(checkOrCreateSeatQuery, [flightId, seatId, flightId, seatId], (err) => {
            if (err) {
                console.error('Error creating flight seat:', err);
                return db.rollback(() => {
                    res.status(500).json({ message: 'Error checking seat availability' });
                });
            }

            // Now check if the seat is available
            const checkSeatQuery = 'SELECT Is_Booked FROM Flight_Seat WHERE FlightID = ? AND SeatID = ?';
            db.query(checkSeatQuery, [flightId, seatId], (err, seatResults) => {
                if (err) {
                    console.error('Error checking seat:', err);
                    return db.rollback(() => {
                        res.status(500).json({ message: 'Error checking seat availability' });
                    });
                }

                if (seatResults.length === 0) {
                    console.error('❌ Seat not found in Flight_Seat table');
                    return db.rollback(() => {
                        res.status(400).json({ message: 'Seat not found for this flight' });
                    });
                }

                if (seatResults[0].Is_Booked === 1) {
                    console.error('❌ Seat is already booked');
                    return db.rollback(() => {
                        res.status(400).json({ message: 'Seat is already booked' });
                    });
                }

                // Get price
                const getPriceQuery = 'SELECT Base_Fare FROM Ticket_Type WHERE TicketTypeID = ?';
                db.query(getPriceQuery, [ticketTypeId], (err, priceResults) => {
                    if (err) {
                        console.error('Price error:', err);
                        return db.rollback(() => {
                            res.status(500).json({ message: 'Error fetching price' });
                        });
                    }

                    const totalAmount = priceResults[0].Base_Fare + 25.00; // Adding taxes

                    // Create booking
                    const createBookingQuery = `
                        INSERT INTO Booking (PassengerID, FlightID, Booking_Status, Total_Amount, TicketTypeID)
                        VALUES (?, ?, 'Pending', ?, ?)
                    `;
                    
                    db.query(createBookingQuery, [passengerId, flightId, totalAmount, ticketTypeId], (err, bookingResult) => {
                        if (err) {
                            console.error('Booking error:', err);
                            return db.rollback(() => {
                                res.status(500).json({ message: 'Error creating booking' });
                            });
                        }

                        const bookingId = bookingResult.insertId;
                        console.log('✅ Booking created:', bookingId);

                        // Link seat to booking
                        const linkSeatQuery = 'INSERT INTO Booking_Seat (BookingID, SeatID) VALUES (?, ?)';
                        db.query(linkSeatQuery, [bookingId, seatId], (err) => {
                            if (err) {
                                console.error('Link seat error:', err);
                                return db.rollback(() => {
                                    res.status(500).json({ message: 'Error linking seat' });
                                });
                            }

                            // Update seat status
                            const updateSeatQuery = 'UPDATE Flight_Seat SET Is_Booked = 1 WHERE FlightID = ? AND SeatID = ?';
                            db.query(updateSeatQuery, [flightId, seatId], (err) => {
                                if (err) {
                                    console.error('Update seat error:', err);
                                    return db.rollback(() => {
                                        res.status(500).json({ message: 'Error updating seat' });
                                    });
                                }

                                // Create payment
                                const transactionId = `TXN-${Date.now()}-${bookingId}`;
                                const createPaymentQuery = `
                                    INSERT INTO Payment (BookingID, Amount, PaymentMethodID, TransactionID, Payment_Status)
                                    VALUES (?, ?, ?, ?, 'Completed')
                                `;
                                
                                db.query(createPaymentQuery, [bookingId, totalAmount, paymentMethodId, transactionId], (err) => {
                                    if (err) {
                                        console.error('Payment error:', err);
                                        return db.rollback(() => {
                                            res.status(500).json({ message: 'Error processing payment' });
                                        });
                                    }

                                    // Confirm booking
                                    const updateBookingQuery = 'UPDATE Booking SET Booking_Status = "Confirmed" WHERE BookingID = ?';
                                    db.query(updateBookingQuery, [bookingId], (err) => {
                                        if (err) {
                                            console.error('Confirm booking error:', err);
                                            return db.rollback(() => {
                                                res.status(500).json({ message: 'Error confirming booking' });
                                            });
                                        }

                                        // Commit transaction
                                        db.commit((err) => {
                                            if (err) {
                                                console.error('Commit error:', err);
                                                return db.rollback(() => {
                                                    res.status(500).json({ message: 'Error committing transaction' });
                                                });
                                            }

                                            // Get booking details
                                            const getBookingQuery = `
                                                SELECT 
                                                    b.BookingID,
                                                    b.Booking_Date,
                                                    b.Booking_Status,
                                                    b.Total_Amount,
                                                    p.Fname, 
                                                    p.Lname, 
                                                    p.Email,
                                                    f.Flight_Number,
                                                    f.Flight_Date,
                                                    f.Departure_Time,
                                                    orig.IATA_Code AS Origin,
                                                    dest.IATA_Code AS Destination,
                                                    s.Seat_Number,
                                                    tt.Type_Name,
                                                    pay.TransactionID
                                                FROM Booking b
                                                INNER JOIN Passenger p ON b.PassengerID = p.PassengerID
                                                INNER JOIN Flight f ON b.FlightID = f.FlightID
                                                INNER JOIN Route r ON f.RouteID = r.RouteID
                                                INNER JOIN Airport orig ON r.Origin_AirportID = orig.AirportID
                                                INNER JOIN Airport dest ON r.Destination_AirportID = dest.AirportID
                                                INNER JOIN Booking_Seat bs ON b.BookingID = bs.BookingID
                                                INNER JOIN Seat s ON bs.SeatID = s.SeatID
                                                INNER JOIN Ticket_Type tt ON b.TicketTypeID = tt.TicketTypeID
                                                INNER JOIN Payment pay ON b.BookingID = pay.BookingID
                                                WHERE b.BookingID = ?
                                            `;

                                            db.query(getBookingQuery, [bookingId], (err, bookingDetails) => {
                                                if (err) {
                                                    console.error('Fetch booking error:', err);
                                                    return res.status(500).json({ message: 'Booking created but error fetching details' });
                                                }

                                                console.log('🎉 Booking completed successfully:', bookingDetails[0]);

                                                // Fire-and-forget: email sending never blocks or fails the booking response.
                                                sendBookingConfirmationEmail({
                                                    ...bookingDetails[0],
                                                    Email: req.user.email || bookingDetails[0].Email
                                                });

                                                res.status(201).json({
                                                    message: 'Booking created successfully',
                                                    booking: bookingDetails[0]
                                                });
                                            });
                                        });
                                    });
                                });
                            });
                        });
                    });
                });
            });
        });
    });
});



// ==================== GET BOOKINGS FOR A PASSENGER (BOOKING HISTORY) ====================
app.get('/api/bookings/passenger/:passengerId', authenticateToken, (req, res) => {
    const { passengerId } = req.params;

    const query = `
        SELECT
            b.BookingID,
            b.Booking_Date,
            b.Booking_Status,
            b.Total_Amount,
            f.FlightID,
            f.Flight_Number,
            f.Departure_Time,
            f.Arrival_Time,
            f.Flight_Date,
            origin.IATA_Code AS Origin,
            dest.IATA_Code AS Destination,
            s.Seat_Number,
            tt.Type_Name,
            pay.Payment_Status,
            pay.TransactionID
        FROM Booking b
        INNER JOIN Flight f ON b.FlightID = f.FlightID
        INNER JOIN Route r ON f.RouteID = r.RouteID
        INNER JOIN Airport origin ON r.Origin_AirportID = origin.AirportID
        INNER JOIN Airport dest ON r.Destination_AirportID = dest.AirportID
        LEFT JOIN Booking_Seat bs ON b.BookingID = bs.BookingID
        LEFT JOIN Seat s ON bs.SeatID = s.SeatID
        INNER JOIN Ticket_Type tt ON b.TicketTypeID = tt.TicketTypeID
        LEFT JOIN Payment pay ON b.BookingID = pay.BookingID
        WHERE b.PassengerID = ?
        ORDER BY b.Booking_Date DESC
    `;

    db.query(query, [passengerId], (err, results) => {
        if (err) {
            console.error('Error fetching bookings:', err);
            return res.status(500).json({ message: 'Error fetching bookings' });
        }
        res.status(200).json({ bookings: results });
    });
});

// ==================== CANCEL A BOOKING ====================
// Marks the booking Cancelled, releases the associated seat(s) back to
// availability, and marks any related payment as Refunded.
app.put('/api/bookings/:bookingId/cancel', authenticateToken, (req, res) => {
    const { bookingId } = req.params;

    db.beginTransaction((err) => {
        if (err) {
            console.error('Transaction error:', err);
            return res.status(500).json({ message: 'Transaction error' });
        }

        const getBookingQuery = 'SELECT * FROM Booking WHERE BookingID = ?';
        db.query(getBookingQuery, [bookingId], (err, bookingResults) => {
            if (err) {
                console.error('Error fetching booking:', err);
                return db.rollback(() => res.status(500).json({ message: 'Error fetching booking' }));
            }

            if (bookingResults.length === 0) {
                return db.rollback(() => res.status(404).json({ message: 'Booking not found' }));
            }

            const booking = bookingResults[0];

            if (booking.Booking_Status === 'Cancelled') {
                return db.rollback(() => res.status(400).json({ message: 'Booking is already cancelled' }));
            }

            const updateBookingQuery = "UPDATE Booking SET Booking_Status = 'Cancelled' WHERE BookingID = ?";
            db.query(updateBookingQuery, [bookingId], (err) => {
                if (err) {
                    console.error('Error cancelling booking:', err);
                    return db.rollback(() => res.status(500).json({ message: 'Error cancelling booking' }));
                }

                const getSeatsQuery = 'SELECT SeatID FROM Booking_Seat WHERE BookingID = ?';
                db.query(getSeatsQuery, [bookingId], (err, seatRows) => {
                    if (err) {
                        console.error('Error fetching booked seats:', err);
                        return db.rollback(() => res.status(500).json({ message: 'Error fetching booked seats' }));
                    }

                    const seatIds = seatRows.map(r => r.SeatID);

                    const releaseSeats = (callback) => {
                        if (seatIds.length === 0) return callback(null);
                        const releaseSeatsQuery = `
                            UPDATE Flight_Seat SET Is_Booked = 0
                            WHERE FlightID = ? AND SeatID IN (${seatIds.map(() => '?').join(',')})
                        `;
                        db.query(releaseSeatsQuery, [booking.FlightID, ...seatIds], callback);
                    };

                    releaseSeats((err) => {
                        if (err) {
                            console.error('Error releasing seats:', err);
                            return db.rollback(() => res.status(500).json({ message: 'Error releasing seats' }));
                        }

                        const updatePaymentQuery = "UPDATE Payment SET Payment_Status = 'Refunded' WHERE BookingID = ?";
                        db.query(updatePaymentQuery, [bookingId], (err) => {
                            if (err) {
                                console.error('Error updating payment status:', err);
                                return db.rollback(() => res.status(500).json({ message: 'Error updating payment status' }));
                            }

                            db.commit((err) => {
                                if (err) {
                                    console.error('Commit error:', err);
                                    return db.rollback(() => res.status(500).json({ message: 'Error committing transaction' }));
                                }
                                res.status(200).json({ message: 'Booking cancelled successfully' });
                            });
                        });
                    });
                });
            });
        });
    });
});

// ==================== DASHBOARD - STATISTICS ====================
app.get('/api/dashboard/stats', (req, res) => {
    const statsQuery = `
        SELECT 
            (SELECT COUNT(*) FROM Flight) AS totalFlights,
            (SELECT COUNT(*) FROM Booking WHERE Booking_Status IN ('Confirmed', 'Pending')) AS activeBookings
    `;

    db.query(statsQuery, (err, results) => {
        if (err) {
            console.error('Dashboard stats error:', err);
            return res.status(500).json({ message: 'Error loading dashboard stats' });
        }

        const stats = results[0];
        res.status(200).json({
            totalFlights: stats.totalFlights,
            activeBookings: stats.activeBookings
        });
    });
});


// ==================== DASHBOARD - RECENT FLIGHTS ====================
app.get('/api/dashboard/recent-flights', (req, res) => {
    const query = `
        SELECT 
            f.FlightID,
            f.Flight_Number,
            f.Departure_Time,
            f.Arrival_Time,
            orig.City AS Origin_City,
            dest.City AS Destination_City,
            fs.Status_Name AS Flight_Status
        FROM Flight f
        INNER JOIN Route r ON f.RouteID = r.RouteID
        INNER JOIN Airport orig ON r.Origin_AirportID = orig.AirportID
        INNER JOIN Airport dest ON r.Destination_AirportID = dest.AirportID
        INNER JOIN Flight_Status fs ON f.FlightStatusID = fs.FlightStatusID
        ORDER BY f.Departure_Time DESC
        LIMIT 5
    `;

    db.query(query, (err, results) => {
        if (err) {
            console.error('Recent flights error:', err);
            return res.status(500).json({ message: 'Error loading recent flights' });
        }

        res.status(200).json({
            flights: results
        });
    });
});


// ==================== ADMIN: LOOKUPS FOR FLIGHT FORM ====================
// Used to populate route/aircraft/status dropdowns in the admin panel.
app.get('/api/admin/lookups', authenticateToken, requireAdmin, (req, res) => {
    const routesQuery = `
        SELECT r.RouteID, orig.IATA_Code AS Origin, dest.IATA_Code AS Destination
        FROM Route r
        INNER JOIN Airport orig ON r.Origin_AirportID = orig.AirportID
        INNER JOIN Airport dest ON r.Destination_AirportID = dest.AirportID
        ORDER BY orig.IATA_Code, dest.IATA_Code
    `;
    const aircraftQuery = 'SELECT AircraftID, Model, Registration_Number, Total_Seats FROM Aircraft ORDER BY Model';
    const statusesQuery = 'SELECT FlightStatusID, Status_Name FROM Flight_Status ORDER BY FlightStatusID';

    db.query(routesQuery, (err, routes) => {
        if (err) return res.status(500).json({ message: 'Error loading routes' });
        db.query(aircraftQuery, (err, aircraft) => {
            if (err) return res.status(500).json({ message: 'Error loading aircraft' });
            db.query(statusesQuery, (err, statuses) => {
                if (err) return res.status(500).json({ message: 'Error loading statuses' });
                res.status(200).json({ routes, aircraft, statuses });
            });
        });
    });
});

// ==================== ADMIN: LIST ALL FLIGHTS ====================
app.get('/api/admin/flights', authenticateToken, requireAdmin, (req, res) => {
    const query = `
        SELECT
            f.FlightID,
            f.Flight_Number,
            f.Departure_Time,
            f.Arrival_Time,
            f.Flight_Date,
            f.Gate_Number,
            f.RouteID,
            f.AircraftID,
            f.FlightStatusID,
            orig.IATA_Code AS Origin,
            dest.IATA_Code AS Destination,
            a.Model AS Aircraft_Model,
            fs.Status_Name AS Flight_Status,
            COUNT(CASE WHEN fls.Is_Booked = 1 THEN 1 END) AS Booked_Seats,
            COUNT(fls.FlightSeatID) AS Total_Seats_Tracked
        FROM Flight f
        INNER JOIN Route r ON f.RouteID = r.RouteID
        INNER JOIN Airport orig ON r.Origin_AirportID = orig.AirportID
        INNER JOIN Airport dest ON r.Destination_AirportID = dest.AirportID
        INNER JOIN Aircraft a ON f.AircraftID = a.AircraftID
        INNER JOIN Flight_Status fs ON f.FlightStatusID = fs.FlightStatusID
        LEFT JOIN Flight_Seat fls ON f.FlightID = fls.FlightID
        GROUP BY f.FlightID, f.Flight_Number, f.Departure_Time, f.Arrival_Time, f.Flight_Date,
                 f.Gate_Number, f.RouteID, f.AircraftID, f.FlightStatusID,
                 orig.IATA_Code, dest.IATA_Code, a.Model, fs.Status_Name
        ORDER BY f.Flight_Date DESC, f.Departure_Time DESC
    `;

    db.query(query, (err, results) => {
        if (err) {
            console.error('Admin list flights error:', err);
            return res.status(500).json({ message: 'Error loading flights' });
        }
        res.status(200).json({ flights: results });
    });
});

// ==================== ADMIN: CREATE FLIGHT ====================
app.post('/api/admin/flights', authenticateToken, requireAdmin, (req, res) => {
    const {
        flightNumber, routeId, aircraftId, departureTime,
        arrivalTime, flightDate, flightStatusId, gateNumber
    } = req.body;

    if (!flightNumber || !routeId || !aircraftId || !departureTime || !arrivalTime || !flightDate || !flightStatusId) {
        return res.status(400).json({ message: 'All flight fields except gate number are required' });
    }

    const insertQuery = `
        INSERT INTO Flight (Flight_Number, RouteID, AircraftID, Departure_Time, Arrival_Time, Flight_Date, FlightStatusID, Gate_Number)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `;

    db.query(insertQuery, [flightNumber, routeId, aircraftId, departureTime, arrivalTime, flightDate, flightStatusId, gateNumber || null], (err, result) => {
        if (err) {
            console.error('Admin create flight error:', err);
            if (err.code === 'ER_DUP_ENTRY') {
                return res.status(409).json({ message: 'A flight with this number already exists on this date' });
            }
            return res.status(500).json({ message: 'Error creating flight' });
        }

        const flightId = result.insertId;

        // Pre-populate Flight_Seat rows for every seat on the assigned aircraft,
        // so the seat map is fully available as soon as the flight is created.
        const seedSeatsQuery = `
            INSERT INTO Flight_Seat (FlightID, SeatID, Is_Booked)
            SELECT ?, SeatID, 0 FROM Seat WHERE AircraftID = ?
        `;
        db.query(seedSeatsQuery, [flightId, aircraftId], (err) => {
            if (err) {
                console.error('Error seeding flight seats:', err);
                // Flight was created; seat seeding failure is non-fatal, seats
                // will be lazily created on first booking attempt as a fallback.
            }
            res.status(201).json({ message: 'Flight created successfully', flightId });
        });
    });
});

// ==================== ADMIN: UPDATE FLIGHT ====================
app.put('/api/admin/flights/:flightId', authenticateToken, requireAdmin, (req, res) => {
    const { flightId } = req.params;
    const {
        flightNumber, routeId, aircraftId, departureTime,
        arrivalTime, flightDate, flightStatusId, gateNumber
    } = req.body;

    const updateQuery = `
        UPDATE Flight SET
            Flight_Number = ?, RouteID = ?, AircraftID = ?, Departure_Time = ?,
            Arrival_Time = ?, Flight_Date = ?, FlightStatusID = ?, Gate_Number = ?
        WHERE FlightID = ?
    `;

    db.query(updateQuery, [flightNumber, routeId, aircraftId, departureTime, arrivalTime, flightDate, flightStatusId, gateNumber || null, flightId], (err, result) => {
        if (err) {
            console.error('Admin update flight error:', err);
            return res.status(500).json({ message: 'Error updating flight' });
        }
        if (result.affectedRows === 0) {
            return res.status(404).json({ message: 'Flight not found' });
        }
        res.status(200).json({ message: 'Flight updated successfully' });
    });
});

// ==================== ADMIN: DELETE FLIGHT ====================
app.delete('/api/admin/flights/:flightId', authenticateToken, requireAdmin, (req, res) => {
    const { flightId } = req.params;

    // Refuse to delete a flight that already has bookings against it — the
    // Booking table has no ON DELETE CASCADE for FlightID on purpose, so this
    // would otherwise fail with an opaque FK constraint error.
    const checkBookingsQuery = 'SELECT COUNT(*) AS count FROM Booking WHERE FlightID = ?';
    db.query(checkBookingsQuery, [flightId], (err, results) => {
        if (err) {
            console.error('Error checking bookings before delete:', err);
            return res.status(500).json({ message: 'Error checking existing bookings' });
        }

        if (results[0].count > 0) {
            return res.status(409).json({
                message: `Cannot delete: this flight has ${results[0].count} existing booking(s). Cancel or reassign them first.`
            });
        }

        const deleteQuery = 'DELETE FROM Flight WHERE FlightID = ?';
        db.query(deleteQuery, [flightId], (err, result) => {
            if (err) {
                console.error('Admin delete flight error:', err);
                return res.status(500).json({ message: 'Error deleting flight' });
            }
            if (result.affectedRows === 0) {
                return res.status(404).json({ message: 'Flight not found' });
            }
            res.status(200).json({ message: 'Flight deleted successfully' });
        });
    });
});

// ==================== ADMIN: VIEW ALL BOOKINGS ====================
app.get('/api/admin/bookings', authenticateToken, requireAdmin, (req, res) => {
    const query = `
        SELECT
            b.BookingID,
            b.Booking_Date,
            b.Booking_Status,
            b.Total_Amount,
            p.Fname, p.Lname, p.Email,
            f.Flight_Number, f.Flight_Date,
            s.Seat_Number,
            tt.Type_Name,
            pay.Payment_Status
        FROM Booking b
        INNER JOIN Passenger p ON b.PassengerID = p.PassengerID
        INNER JOIN Flight f ON b.FlightID = f.FlightID
        LEFT JOIN Booking_Seat bs ON b.BookingID = bs.BookingID
        LEFT JOIN Seat s ON bs.SeatID = s.SeatID
        INNER JOIN Ticket_Type tt ON b.TicketTypeID = tt.TicketTypeID
        LEFT JOIN Payment pay ON b.BookingID = pay.BookingID
        ORDER BY b.Booking_Date DESC
        LIMIT 200
    `;

    db.query(query, (err, results) => {
        if (err) {
            console.error('Admin list bookings error:', err);
            return res.status(500).json({ message: 'Error loading bookings' });
        }
        res.status(200).json({ bookings: results });
    });
});

// ==================== ADMIN: VIEW ALL USERS ====================
app.get('/api/admin/users', authenticateToken, requireAdmin, (req, res) => {
    const query = `
        SELECT UserID, Fname, Lname, Email, Phone, Role, Last_Login, CreatedAt
        FROM User
        ORDER BY CreatedAt DESC
        LIMIT 200
    `;

    db.query(query, (err, results) => {
        if (err) {
            console.error('Admin list users error:', err);
            return res.status(500).json({ message: 'Error loading users' });
        }
        res.status(200).json({ users: results });
    });
});

// ==================== TEST ENDPOINT ====================
app.get('/api/test', (req, res) => {
    res.json({ message: 'Backend is working with airlines_aid database!' });
});

// Start server
app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}`);
    console.log(`Connected to database: airlines_aid`);
});