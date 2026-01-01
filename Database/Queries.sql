-- =====================================================
-- 9 COMPREHENSIVE QUERIES FOR AIRLINES_AID DATABASE
-- =====================================================
-- MySQL Compatible Version - Only queries for existing tables
-- =====================================================

USE airlines_aid;

-- =====================================================
-- QUERY 1: Basic Flight Search
-- Description: Find all flights from a specific origin to destination on a given date
-- Complexity: Simple - Basic JOIN
-- =====================================================
SELECT 
    f.Flight_Number,
    orig.Airport_Name AS Origin_Airport,
    orig.IATA_Code AS Origin_Code,
    dest.Airport_Name AS Destination_Airport,
    dest.IATA_Code AS Destination_Code,
    f.Departure_Time,
    f.Arrival_Time,
    fs.Status_Name AS Flight_Status,
    a.Model AS Aircraft_Model,
    a.Total_Seats
FROM Flight f
INNER JOIN `Route` r ON f.RouteID = r.RouteID
INNER JOIN Airport orig ON r.Origin_AirportID = orig.AirportID
INNER JOIN Airport dest ON r.Destination_AirportID = dest.AirportID
INNER JOIN Flight_Status fs ON f.FlightStatusID = fs.FlightStatusID
INNER JOIN Aircraft a ON f.AircraftID = a.AircraftID
WHERE orig.IATA_Code = 'JFK'
  AND dest.IATA_Code = 'LAX'
  AND f.Flight_Date = '2025-12-10'
ORDER BY f.Departure_Time;

-- =====================================================
-- QUERY 2: Passenger Booking History with Total Spent
-- Description: Get complete booking history for all passengers
-- Complexity: Medium - Multiple JOINs with aggregation
-- =====================================================
SELECT 
    p.PassengerID,
    CONCAT(p.Fname, ' ', p.Lname) AS Passenger_Name,
    p.Email,
    COUNT(DISTINCT b.BookingID) AS Total_Bookings,
    COUNT(DISTINCT CASE WHEN b.Booking_Status = 'Confirmed' THEN b.BookingID END) AS Confirmed_Bookings,
    COUNT(DISTINCT CASE WHEN b.Booking_Status = 'Cancelled' THEN b.BookingID END) AS Cancelled_Bookings,
    SUM(CASE WHEN b.Booking_Status = 'Confirmed' THEN b.Total_Amount ELSE 0 END) AS Total_Spent,
    AVG(CASE WHEN b.Booking_Status = 'Confirmed' THEN b.Total_Amount ELSE NULL END) AS Avg_Booking_Amount,
    MAX(b.Booking_Date) AS Last_Booking_Date
FROM Passenger p
LEFT JOIN Booking b ON p.PassengerID = b.PassengerID
GROUP BY p.PassengerID, p.Fname, p.Lname, p.Email
ORDER BY p.PassengerID;


-- =====================================================
-- QUERY 3: Revenue Analysis by Route
-- Description: Analyze revenue, bookings, and average fare by route
-- Complexity: Medium - Multiple JOINs with GROUP BY and aggregation
-- =====================================================
SELECT 
    orig.City AS Origin_City,
    orig.IATA_Code AS Origin_Code,
    dest.City AS Destination_City,
    dest.IATA_Code AS Destination_Code,
    COUNT(DISTINCT b.BookingID) AS Total_Bookings,
    SUM(b.Total_Amount) AS Total_Revenue,
    AVG(b.Total_Amount) AS Average_Fare,
    MIN(b.Total_Amount) AS Min_Fare,
    MAX(b.Total_Amount) AS Max_Fare,
    COUNT(DISTINCT f.FlightID) AS Flights_On_Route
FROM Booking b
INNER JOIN Booking_Seat bs ON b.BookingID = bs.BookingID
INNER JOIN Flight_Seat fls ON bs.SeatID = fls.SeatID
INNER JOIN Flight f ON fls.FlightID = f.FlightID
INNER JOIN `Route` r ON f.RouteID = r.RouteID
INNER JOIN Airport orig ON r.Origin_AirportID = orig.AirportID
INNER JOIN Airport dest ON r.Destination_AirportID = dest.AirportID
WHERE b.Booking_Status = 'Confirmed'
GROUP BY orig.City, orig.IATA_Code, dest.City, dest.IATA_Code
ORDER BY Total_Revenue DESC;

-- =====================================================
-- QUERY 4: Available Seats by Class for Specific Flight
-- Description: Show seat availability breakdown by class for a flight
-- Complexity: Simple - GROUP BY with aggregation
-- =====================================================
SELECT 
    s.Seat_Class,
    COUNT(*) AS Total_Seats,
    SUM(CASE WHEN fs.Is_Booked = 0 THEN 1 ELSE 0 END) AS Available_Seats,
    SUM(CASE WHEN fs.Is_Booked = 1 THEN 1 ELSE 0 END) AS Booked_Seats,
    CAST(SUM(CASE WHEN fs.Is_Booked = 1 THEN 1 ELSE 0 END) AS DECIMAL(10,2)) / COUNT(*) * 100 AS Occupancy_Percentage
FROM Flight_Seat fs
INNER JOIN Seat s ON fs.SeatID = s.SeatID
WHERE fs.FlightID = 1
GROUP BY s.Seat_Class
ORDER BY 
    CASE s.Seat_Class
        WHEN 'First Class' THEN 1
        WHEN 'Business' THEN 2
        WHEN 'Premium Economy' THEN 3
        WHEN 'Economy' THEN 4
    END;

-- =====================================================
-- QUERY 5: Top 10 Passengers by Total Spending
-- Description: Identify VIP passengers based on total confirmed bookings
-- Complexity: Medium - Aggregation with ranking
-- =====================================================
SELECT 
    p.PassengerID,
    CONCAT(p.Fname, ' ', p.Lname) AS Passenger_Name,
    p.Email,
    p.Nationality,
    COUNT(b.BookingID) AS Total_Bookings,
    SUM(b.Total_Amount) AS Total_Spent,
    AVG(b.Total_Amount) AS Avg_Booking_Value,
    MAX(b.Booking_Date) AS Last_Booking_Date
FROM Passenger p
INNER JOIN Booking b ON p.PassengerID = b.PassengerID
WHERE b.Booking_Status = 'Confirmed'
GROUP BY p.PassengerID, p.Fname, p.Lname, p.Email, p.Nationality
ORDER BY Total_Spent DESC
LIMIT 10;

-- =====================================================
-- QUERY 6: Daily Flight Schedule
-- Description: Complete flight schedule for a specific date with gate info
-- Complexity: Simple - Multiple JOINs with ordering
-- =====================================================
SELECT 
    f.Flight_Number,
    orig.Airport_Name AS Origin,
    orig.IATA_Code AS Origin_Code,
    dest.Airport_Name AS Destination,
    dest.IATA_Code AS Dest_Code,
    f.Departure_Time,
    f.Arrival_Time,
    TIMESTAMPDIFF(MINUTE, f.Departure_Time, f.Arrival_Time) AS Flight_Duration_Minutes,
    f.Gate_Number,
    fs.Status_Name,
    a.Model AS Aircraft,
    a.Registration_Number
FROM Flight f
INNER JOIN `Route` r ON f.RouteID = r.RouteID
INNER JOIN Airport orig ON r.Origin_AirportID = orig.AirportID
INNER JOIN Airport dest ON r.Destination_AirportID = dest.AirportID
INNER JOIN Flight_Status fs ON f.FlightStatusID = fs.FlightStatusID
INNER JOIN Aircraft a ON f.AircraftID = a.AircraftID
WHERE f.Flight_Date = '2025-12-10'
ORDER BY f.Departure_Time;

-- =====================================================
-- QUERY 7: Payment Method Analysis
-- Description: Analyze payment methods used and their totals
-- Complexity: Simple - GROUP BY with payment details
-- =====================================================
SELECT 
    pm.Method_Name,
    COUNT(DISTINCT p.PaymentID) AS Total_Transactions,
    COUNT(DISTINCT p.BookingID) AS Unique_Bookings,
    SUM(p.Amount) AS Total_Amount,
    AVG(p.Amount) AS Average_Transaction,
    MIN(p.Payment_Date) AS First_Transaction,
    MAX(p.Payment_Date) AS Latest_Transaction
FROM Payment p
INNER JOIN Payment_Method pm ON p.PaymentMethodID = pm.PaymentMethodID
WHERE p.Payment_Status = 'Completed'
GROUP BY pm.PaymentMethodID, pm.Method_Name
ORDER BY Total_Amount DESC;

-- =====================================================
-- QUERY 8: Route Distance and Flight Time Analysis
-- Description: Compare actual flight times with estimated times
-- Complexity: Medium - Calculated fields with time analysis
-- =====================================================
SELECT 
    orig.City AS Origin,
    dest.City AS Destination,
    r.Distance AS Distance_KM,
    r.Estimated_Time,
    COUNT(f.FlightID) AS Number_Of_Flights,
    AVG(TIMESTAMPDIFF(MINUTE, f.Departure_Time, f.Arrival_Time)) AS Avg_Actual_Duration_Minutes,
    MIN(TIMESTAMPDIFF(MINUTE, f.Departure_Time, f.Arrival_Time)) AS Min_Duration_Minutes,
    MAX(TIMESTAMPDIFF(MINUTE, f.Departure_Time, f.Arrival_Time)) AS Max_Duration_Minutes,
    CASE 
        WHEN AVG(TIMESTAMPDIFF(MINUTE, f.Departure_Time, f.Arrival_Time)) > TIMESTAMPDIFF(MINUTE, '00:00:00', r.Estimated_Time)
        THEN 'Behind Schedule'
        ELSE 'On Time'
    END AS Performance_Status
FROM `Route` r
INNER JOIN Airport orig ON r.Origin_AirportID = orig.AirportID
INNER JOIN Airport dest ON r.Destination_AirportID = dest.AirportID
INNER JOIN Flight f ON r.RouteID = f.RouteID
GROUP BY r.RouteID, orig.City, dest.City, r.Distance, r.Estimated_Time
ORDER BY r.Distance DESC;

-- =====================================================
-- QUERY 9: Flight Occupancy Report
-- Description: Calculate seat occupancy percentage for each flight
-- Complexity: Medium - Aggregation with calculated percentages
-- =====================================================
SELECT 
    f.FlightID,
    f.Flight_Number,
    f.Flight_Date,
    CONCAT(orig.City, ' → ', dest.City) AS Route,
    a.Model AS Aircraft,
    a.Total_Seats,
    COUNT(CASE WHEN fs.Is_Booked = 1 THEN 1 END) AS Booked_Seats,
    a.Total_Seats - COUNT(CASE WHEN fs.Is_Booked = 1 THEN 1 END) AS Available_Seats,
    CAST(COUNT(CASE WHEN fs.Is_Booked = 1 THEN 1 END) AS DECIMAL(10,2)) / a.Total_Seats * 100 AS Occupancy_Percentage
FROM Flight f
INNER JOIN Aircraft a ON f.AircraftID = a.AircraftID
INNER JOIN Flight_Seat fs ON f.FlightID = fs.FlightID
INNER JOIN `Route` r ON f.RouteID = r.RouteID
INNER JOIN Airport orig ON r.Origin_AirportID = orig.AirportID
INNER JOIN Airport dest ON r.Destination_AirportID = dest.AirportID
GROUP BY 
    f.FlightID, f.Flight_Number, f.Flight_Date, 
    orig.City, dest.City, a.Model, a.Total_Seats
ORDER BY Occupancy_Percentage DESC;

-- =====================================================
-- END OF QUERIES
-- =====================================================


-- Check all passengers
SELECT * FROM Passenger;

-- Check bookings with passenger info
SELECT 
    b.BookingID,
    b.PassengerID,
    p.Email,
    p.Fname,
    b.Total_Amount
FROM Booking b
INNER JOIN Passenger p ON b.PassengerID = p.PassengerID;