# Airline Reservation System

A full-stack airline reservation system. Passengers can search flights, pick seats, pay, and get an e-ticket, while admins manage flights, bookings, and users. Built with a normalized MySQL database, a Node.js/Express REST API with JWT authentication, and a vanilla HTML/CSS/JavaScript frontend.

## Features

**Passengers**
- Sign up, log in, and reset a forgotten password by email
- Search flights by origin, destination, and date
- Interactive seat selection with live availability
- Payment step and e-ticket page
- Booking history, cancellation, and profile management with booking stats
- Booking confirmation email sent to the account holder via SMTP (optional)

**Admin**
- Role-protected admin panel
- Create, update, and delete flights
- View all bookings and users

**Security**
- JWT authentication with bcrypt password hashing
- Rate limiting on auth routes, `helmet` security headers, and input validation (`express-validator`)
- Database transactions with rollback for signup and booking

## Tech Stack

| Layer | Technology |
|-------|------------|
| Database | MySQL |
| Backend | Node.js, Express, mysql2, JWT, bcrypt, Nodemailer |
| Frontend | HTML, CSS, JavaScript |

## Database Design

14 tables with primary keys, foreign keys, unique constraints, and indexes on frequently queried columns (user email, flight date, booking passenger):

`User`, `Passenger`, `Airport`, `Route`, `Aircraft`, `Seat`, `Flight_Status`, `Flight`, `Ticket_Type`, `Payment_Method`, `Booking`, `Payment`, `Flight_Seat`, `Booking_Seat`

Constraints enforce data integrity, for example `UNIQUE (Flight_Number, Flight_Date)` for flights and `UNIQUE (FlightID, SeatID)` so a seat can only exist once per flight.

- ERD: [`erd-mapping/erd.pdf`](erd-mapping/erd.pdf)
- Relational mapping: [`erd-mapping/mapping.pdf`](erd-mapping/mapping.pdf)
- Schema and sample data: [`Database/Project.sql`](Database/Project.sql)

### SQL Queries
[`Database/Queries.sql`](Database/Queries.sql) contains 9 queries, from basic flight search to multi-table joins and aggregations, such as:
- Flight search by route and date
- Passenger booking history with total spent and average booking amount
- Revenue analysis by route

## API Overview

| Area | Endpoints |
|------|-----------|
| Auth | `POST /api/signup`, `POST /api/login`, `POST /api/auth/forgot-password`, `POST /api/auth/reset-password` |
| Profile | `GET /api/profile/:userId`, `PUT /api/profile/update`, `PUT /api/profile/change-password`, `GET /api/profile/stats/:userId` |
| Flights | `GET /api/flights/search`, `GET /api/flights/:flightId/seats`, `GET /api/airports` |
| Bookings | `POST /api/bookings/create`, `GET /api/bookings/passenger/:passengerId`, `PUT /api/bookings/:bookingId/cancel` |
| Admin | `/api/admin/flights`, `/api/admin/bookings`, `/api/admin/users` |

## Project Structure

```
.
├── Backend/          # Express API (server.js, mailer.js)
├── Database/         # Project.sql (schema + data), Queries.sql
├── erd-mapping/      # ERD and relational mapping
├── admin/            # Admin panel
├── Home/ Login/ Profile/ Passenger/ booking/ my-booking/ Payment/ ticket/ contact-us/   # Frontend pages
├── shared/config.js  # API base URL
└── Airline Reservation System Final.pdf   # Project report
```

## Getting Started

**Prerequisites:** Node.js 18+ and MySQL 8+

1. **Database:** import `Database/Project.sql` into MySQL (the queries file uses a database named `airlines_aid`).
2. **Backend configuration:**
   ```
   cd Backend
   cp .env.example .env
   ```
   Edit `.env` with your database credentials, a long random `JWT_SECRET`, `PORT=3000`, and `FRONTEND_URL` (the address you serve the frontend from).
   To enable booking confirmation emails, fill in the `SMTP_*` variables (for Gmail, use an App Password). If they are left empty, the app still runs and emails are skipped.
3. **Run the API:**
   ```
   npm install
   npm start
   ```
   The API runs on `http://localhost:3000`.
4. **Open the frontend:** serve the project folder with a static server (for example the VS Code Live Server extension) and open `Home/home.html`. To use a different API address, edit `shared/config.js`.

## Project Report
The full design and implementation report is in `Airline Reservation System Final.pdf`.

## Author
Nasser Hossam – [LinkedIn](https://www.linkedin.com/in/nasser-hossam)