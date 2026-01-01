// server.js - COMPLETE VERSION WITH ALL ENDPOINTS
const express = require('express');
const mysql = require('mysql2');
const bcrypt = require('bcrypt');
const cors = require('cors');
const jwt = require('jsonwebtoken');

const app = express();
const PORT = 3000;

// Middleware
app.use(cors());
app.use(express.json());

// MySQL Database Connection
const db = mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: 'Nasser270805',
    database: 'airlines_aid'
});

// Connect to MySQL
db.connect((err) => {
    if (err) {
        console.error('Error connecting to MySQL:', err);
        return;
    }
    console.log('Connected to airlines_aid database');
});

// JWT Secret Key
const JWT_SECRET = 'your-secret-key-here-change-this';

// ==================== SIGNUP ENDPOINT - CREATES BOTH USER AND PASSENGER ====================
app.post('/api/signup', async (req, res) => {
    const { name, email, password } = req.body;

    if (!name || !email || !password) {
        return res.status(400).json({ message: 'All fields are required' });
    }

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

                    // Step 2: Insert into Passenger table with required fields
                    const insertPassengerQuery = `
                        INSERT INTO Passenger (
                            Fname, 
                            Lname, 
                            Email, 
                            Date_of_Birth, 
                            Nationality, 
                            Passport_Number, 
                            Gender
                        ) 
                        VALUES (?, ?, ?, '2000-01-01', 'Unknown', ?, 'U')
                    `;

                    // Generate unique passport number using timestamp and random number
                    const uniquePassport = `TEMP${Date.now()}${Math.floor(Math.random() * 1000)}`;

                    db.query(insertPassengerQuery, [fname, lname, email, uniquePassport], (err, passengerResult) => {
                        if (err) {
                            console.error('Insert passenger error:', err);
                            return db.rollback(() => {
                                res.status(500).json({ message: 'Error creating passenger record' });
                            });
                        }

                        const passengerId = passengerResult.insertId;

                        // Commit transaction
                        db.commit((err) => {
                            if (err) {
                                console.error('Commit error:', err);
                                return db.rollback(() => {
                                    res.status(500).json({ message: 'Error committing transaction' });
                                });
                            }

                            // Get user data
                            const getUserQuery = 'SELECT UserID, Fname, Lname, Email, Phone, Date_of_Birth, CreatedAt FROM User WHERE UserID = ?';
                            db.query(getUserQuery, [userId], (err, userResults) => {
                                if (err) {
                                    console.error('Fetch user error:', err);
                                    return res.status(500).json({ message: 'Error fetching user data' });
                                }

                                const user = userResults[0];
                                const token = jwt.sign(
                                    { id: user.UserID, email: user.Email },
                                    JWT_SECRET,
                                    { expiresIn: '24h' }
                                );

                                console.log(`✅ SUCCESS! Created User (ID: ${userId}) and Passenger (ID: ${passengerId}) for ${email}`);

                                res.status(201).json({
                                    message: 'Account created successfully',
                                    user: {
                                        id: user.UserID,
                                        name: `${user.Fname} ${user.Lname}`,
                                        email: user.Email,
                                        phone: user.Phone,
                                        date_of_birth: user.Date_of_Birth,
                                        created_at: user.CreatedAt
                                    },
                                    token: token
                                });
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
app.post('/api/login', (req, res) => {
    const { email, password } = req.body;

    if (!email || !password) {
        return res.status(400).json({ message: 'Email and password are required' });
    }

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

            const getUserQuery = 'SELECT UserID, Fname, Lname, Email, Phone, Date_of_Birth, CreatedAt FROM User WHERE UserID = ?';
            db.query(getUserQuery, [user.UserID], (err, userResults) => {
                if (err) {
                    console.error('Fetch user error:', err);
                    return res.status(500).json({ message: 'Error fetching user data' });
                }

                const userData = userResults[0];
                const token = jwt.sign(
                    { id: userData.UserID, email: userData.Email },
                    JWT_SECRET,
                    { expiresIn: '24h' }
                );

                res.status(200).json({
                    message: 'Login successful',
                    user: {
                        id: userData.UserID,
                        name: `${userData.Fname} ${userData.Lname}`,
                        email: userData.Email,
                        phone: userData.Phone,
                        date_of_birth: userData.Date_of_Birth,
                        created_at: userData.CreatedAt
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

// ==================== GET USER PROFILE ====================
app.get('/api/profile/:userId', (req, res) => {
    const { userId } = req.params;

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
app.put('/api/profile/update', (req, res) => {
    const { userId, name, phone, dob } = req.body;

    if (!userId || !name) {
        return res.status(400).json({ message: 'User ID and name are required' });
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
app.put('/api/profile/change-password', async (req, res) => {
    const { userId, currentPassword, newPassword } = req.body;

    if (!userId || !currentPassword || !newPassword) {
        return res.status(400).json({ message: 'All fields are required' });
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
app.get('/api/profile/stats/:userId', (req, res) => {
    const { userId } = req.params;

    // Get user email first
    const getUserEmailQuery = 'SELECT Email FROM User WHERE UserID = ?';
    db.query(getUserEmailQuery, [userId], (err, userResults) => {
        if (err || userResults.length === 0) {
            return res.status(404).json({ message: 'User not found' });
        }

        const userEmail = userResults[0].Email;

        // Get statistics using the user's email to match with passenger records
        const statsQuery = `
            SELECT 
                COUNT(DISTINCT b.BookingID) as total_bookings,
                COUNT(DISTINCT CASE WHEN b.Booking_Status IN ('Confirmed', 'Pending') THEN b.BookingID END) as active_bookings,
                COALESCE(SUM(CASE WHEN b.Booking_Status = 'Confirmed' THEN b.Total_Amount ELSE 0 END), 0) as total_spent,
                COUNT(DISTINCT CASE WHEN b.Booking_Status = 'Completed' THEN b.BookingID END) as completed_flights
            FROM Passenger p
            LEFT JOIN Booking b ON p.PassengerID = b.PassengerID
            WHERE p.Email = ?
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
app.post('/api/passengers/create', (req, res) => {
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
app.get('/api/passengers/by-email/:email', (req, res) => {
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
app.post('/api/bookings/create', (req, res) => {
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
                                                    s.Seat_Number,
                                                    tt.Type_Name,
                                                    pay.TransactionID
                                                FROM Booking b
                                                INNER JOIN Passenger p ON b.PassengerID = p.PassengerID
                                                INNER JOIN Flight f ON b.FlightID = f.FlightID
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


// ==================== TEST ENDPOINT ====================
app.get('/api/test', (req, res) => {
    res.json({ message: 'Backend is working with airlines_aid database!' });
});

// Start server
app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}`);
    console.log(`Connected to database: airlines_aid`);
});