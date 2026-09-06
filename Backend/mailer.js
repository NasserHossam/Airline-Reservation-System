// mailer.js
//
// Sends transactional emails (currently just booking confirmations) via
// SMTP using Nodemailer. Designed to fail SAFE: if SMTP isn't configured,
// or if sending fails for any reason, this logs a warning and returns
// without throwing — a broken/misconfigured mail server should never take
// down the booking flow itself.
//
// Configure via Backend/.env (see .env.example):
//   SMTP_HOST, SMTP_PORT, SMTP_SECURE, SMTP_USER, SMTP_PASS, SMTP_FROM
//
// Quick setup with a real Gmail account:
//   1. Enable 2-Step Verification on the Google account.
//   2. Create an "App Password" at https://myaccount.google.com/apppasswords
//   3. SMTP_HOST=smtp.gmail.com, SMTP_PORT=587, SMTP_SECURE=false,
//      SMTP_USER=youraddress@gmail.com, SMTP_PASS=<the 16-char app password>

const nodemailer = require('nodemailer');

let transporter = null;
let isConfigured = false;

function initTransporter() {
    const { SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS } = process.env;

    if (!SMTP_HOST || !SMTP_PORT || !SMTP_USER || !SMTP_PASS) {
        console.warn('⚠️  Email not configured (missing SMTP_* vars in .env) — booking confirmation emails will be skipped.');
        return;
    }

    transporter = nodemailer.createTransport({
        host: SMTP_HOST,
        port: parseInt(SMTP_PORT, 10),
        secure: process.env.SMTP_SECURE === 'true', // true for port 465, false for 587/others
        auth: {
            user: SMTP_USER,
            pass: SMTP_PASS
        }
    });

    isConfigured = true;
}

initTransporter();

function formatDate(dateValue) {
    if (!dateValue) return '';
    return new Date(dateValue).toLocaleDateString('en-US', {
        weekday: 'long', year: 'numeric', month: 'long', day: 'numeric'
    });
}

function formatTime(dateValue) {
    if (!dateValue) return '';
    return new Date(dateValue).toLocaleTimeString('en-US', {
        hour: '2-digit', minute: '2-digit'
    });
}

/**
 * Sends a booking confirmation email. Never throws — logs and resolves on
 * any failure so a booking is never rolled back or blocked because of email.
 *
 * @param {object} booking - a row shaped like the result of the booking
 *   confirmation query in POST /api/bookings/create (Fname, Lname, Email,
 *   Flight_Number, Origin, Destination, Flight_Date, Departure_Time,
 *   Seat_Number, Type_Name, Total_Amount, BookingID, TransactionID).
 */
async function sendBookingConfirmationEmail(booking) {
    if (!isConfigured) {
        console.log(`ℹ️  Skipping confirmation email for booking #${booking.BookingID} (email not configured).`);
        return;
    }

    if (!booking.Email) {
        console.warn(`⚠️  Booking #${booking.BookingID} has no passenger email on file — skipping confirmation email.`);
        return;
    }

    const fromAddress = process.env.SMTP_FROM || process.env.SMTP_USER;

    const html = `
        <div style="font-family: 'Segoe UI', Arial, sans-serif; max-width: 560px; margin: 0 auto; color: #2d3748;">
            <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 28px 32px; border-radius: 12px 12px 0 0;">
                <h1 style="color: white; margin: 0; font-size: 22px;">✈️ Booking Confirmed</h1>
            </div>
            <div style="border: 1px solid #e2e8f0; border-top: none; padding: 28px 32px; border-radius: 0 0 12px 12px;">
                <p>Hi ${booking.Fname},</p>
                <p>Your booking is confirmed. Here are the details:</p>

                <table style="width: 100%; border-collapse: collapse; margin: 20px 0;">
                    <tr>
                        <td style="padding: 8px 0; color: #718096;">Booking Reference</td>
                        <td style="padding: 8px 0; text-align: right; font-weight: 600;">#${booking.BookingID}</td>
                    </tr>
                    <tr>
                        <td style="padding: 8px 0; color: #718096;">Flight</td>
                        <td style="padding: 8px 0; text-align: right; font-weight: 600;">${booking.Flight_Number}</td>
                    </tr>
                    <tr>
                        <td style="padding: 8px 0; color: #718096;">Route</td>
                        <td style="padding: 8px 0; text-align: right; font-weight: 600;">${booking.Origin || ''} → ${booking.Destination || ''}</td>
                    </tr>
                    <tr>
                        <td style="padding: 8px 0; color: #718096;">Date</td>
                        <td style="padding: 8px 0; text-align: right; font-weight: 600;">${formatDate(booking.Flight_Date)}</td>
                    </tr>
                    <tr>
                        <td style="padding: 8px 0; color: #718096;">Departure</td>
                        <td style="padding: 8px 0; text-align: right; font-weight: 600;">${formatTime(booking.Departure_Time)}</td>
                    </tr>
                    <tr>
                        <td style="padding: 8px 0; color: #718096;">Seat</td>
                        <td style="padding: 8px 0; text-align: right; font-weight: 600;">${booking.Seat_Number || 'N/A'} (${booking.Type_Name})</td>
                    </tr>
                    <tr>
                        <td style="padding: 12px 0 0 0; color: #718096; border-top: 1px solid #e2e8f0;">Total Paid</td>
                        <td style="padding: 12px 0 0 0; text-align: right; font-weight: 700; font-size: 18px; color: #667eea; border-top: 1px solid #e2e8f0;">
                            $${Number(booking.Total_Amount).toFixed(2)}
                        </td>
                    </tr>
                </table>

                <p style="color: #718096; font-size: 13px;">
                    This is a demo confirmation from the AeroBooker project — no real payment was processed.
                </p>
                <p>Thanks for booking with AeroBooker!</p>
            </div>
        </div>
    `;

    try {
        await transporter.sendMail({
            from: `"AeroBooker" <${fromAddress}>`,
            to: booking.Email,
            subject: `Booking Confirmed — Flight ${booking.Flight_Number} (#${booking.BookingID})`,
            html
        });
        console.log(`✅ Confirmation email sent to ${booking.Email} for booking #${booking.BookingID}`);
    } catch (error) {
        // Deliberately swallowed: a failed email should never fail the booking.
        console.error(`⚠️  Failed to send confirmation email for booking #${booking.BookingID}:`, error.message);
    }
}

/**
 * Sends a password reset email with a link containing the raw reset token.
 * Never throws — logs and resolves on any failure, same as the booking
 * confirmation email, so a mail server issue never blocks the API response
 * (the forgot-password endpoint already responds before this is called).
 *
 * @param {object} user - { Fname, Email }
 * @param {string} resetLink - full URL the user clicks to reset their password
 */
async function sendPasswordResetEmail(user, resetLink) {
    if (!isConfigured) {
        console.log(`ℹ️  Skipping password reset email to ${user.Email} (email not configured).`);
        return;
    }

    const fromAddress = process.env.SMTP_FROM || process.env.SMTP_USER;

    const html = `
        <div style="font-family: 'Segoe UI', Arial, sans-serif; max-width: 560px; margin: 0 auto; color: #2d3748;">
            <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 28px 32px; border-radius: 12px 12px 0 0;">
                <h1 style="color: white; margin: 0; font-size: 22px;">🔑 Reset Your Password</h1>
            </div>
            <div style="border: 1px solid #e2e8f0; border-top: none; padding: 28px 32px; border-radius: 0 0 12px 12px;">
                <p>Hi ${user.Fname},</p>
                <p>We received a request to reset your AeroBooker password. Click the button below to choose a new one. This link expires in 1 hour.</p>

                <div style="text-align: center; margin: 28px 0;">
                    <a href="${resetLink}" style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; text-decoration: none; padding: 12px 28px; border-radius: 8px; font-weight: 600; display: inline-block;">
                        Reset Password
                    </a>
                </div>

                <p style="color: #718096; font-size: 13px;">
                    If you didn't request this, you can safely ignore this email — your password won't change.
                </p>
                <p style="color: #718096; font-size: 13px;">
                    If the button doesn't work, copy and paste this link into your browser:<br>
                    <span style="word-break: break-all;">${resetLink}</span>
                </p>
            </div>
        </div>
    `;

    try {
        await transporter.sendMail({
            from: `"AeroBooker" <${fromAddress}>`,
            to: user.Email,
            subject: 'Reset Your AeroBooker Password',
            html
        });
        console.log(`✅ Password reset email sent to ${user.Email}`);
    } catch (error) {
        console.error(`⚠️  Failed to send password reset email to ${user.Email}:`, error.message);
    }
}

module.exports = { sendBookingConfirmationEmail, sendPasswordResetEmail };
