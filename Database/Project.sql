-- =====================================================
-- AIRLINE RESERVATION SYSTEM - MYSQL (FINAL FIXED)
-- =====================================================

DROP DATABASE IF EXISTS airlines_aid;
CREATE DATABASE airlines_aid;
USE airlines_aid;

-- User table
CREATE TABLE `User` (
    UserID INT AUTO_INCREMENT PRIMARY KEY,
    Fname VARCHAR(50) NOT NULL,
    Lname VARCHAR(50) NOT NULL,
    Email VARCHAR(100) NOT NULL UNIQUE,
    Password VARCHAR(255) NOT NULL,
    Phone VARCHAR(20) NULL,
    Role VARCHAR(50) NOT NULL DEFAULT 'User',
    Last_Login DATETIME NULL,
    CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    
);

-- Passenger table
CREATE TABLE Passenger (
    PassengerID INT AUTO_INCREMENT PRIMARY KEY,
    Fname VARCHAR(50) NOT NULL,
    Lname VARCHAR(50) NOT NULL,
    Email VARCHAR(100) NULL,
    Phone VARCHAR(20) NULL,
    Date_of_Birth DATE NOT NULL,
    Nationality VARCHAR(50) NOT NULL,
    Passport_Number VARCHAR(50) NOT NULL UNIQUE,
    Gender CHAR(1) NOT NULL,
    CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Airport table
CREATE TABLE Airport (
    AirportID INT AUTO_INCREMENT PRIMARY KEY,
    Airport_Name VARCHAR(100) NOT NULL,
    City VARCHAR(100) NOT NULL,
    Country VARCHAR(100) NOT NULL,
    IATA_Code CHAR(3) NOT NULL UNIQUE,
    ICAO_Code CHAR(4) NULL UNIQUE,
    Timezone VARCHAR(50) NULL
);

-- Route table
CREATE TABLE Route (
    RouteID INT AUTO_INCREMENT PRIMARY KEY,
    Origin_AirportID INT NOT NULL,
    Destination_AirportID INT NOT NULL,
    Distance DECIMAL(10, 2) NULL,
    Estimated_Time TIME NULL,
    
    FOREIGN KEY (Origin_AirportID) REFERENCES Airport(AirportID),
    FOREIGN KEY (Destination_AirportID) REFERENCES Airport(AirportID)
);

-- Aircraft table
CREATE TABLE Aircraft (
    AircraftID INT AUTO_INCREMENT PRIMARY KEY,
    Model VARCHAR(100) NOT NULL,
    Manufacturer VARCHAR(100) NOT NULL,
    Total_Seats INT NOT NULL,
    Year_Manufactured INT NULL,
    Aircraft_Type VARCHAR(50) NOT NULL,
    Registration_Number VARCHAR(20) NOT NULL UNIQUE,
    Status VARCHAR(20) DEFAULT 'Active'
);

-- Seat table
CREATE TABLE Seat (
    SeatID INT AUTO_INCREMENT PRIMARY KEY,
    AircraftID INT NOT NULL,
    Seat_Number VARCHAR(10) NOT NULL,
    Seat_Class VARCHAR(30) NOT NULL,
    
    FOREIGN KEY (AircraftID) REFERENCES Aircraft(AircraftID) ON DELETE CASCADE,
    UNIQUE KEY (AircraftID, Seat_Number)
);

-- Flight_Status table
CREATE TABLE Flight_Status (
    FlightStatusID INT AUTO_INCREMENT PRIMARY KEY,
    Status_Name VARCHAR(50) NOT NULL UNIQUE,
    Description VARCHAR(255) NULL
);

-- Flight table
CREATE TABLE Flight (
    FlightID INT AUTO_INCREMENT PRIMARY KEY,
    Flight_Number VARCHAR(20) NOT NULL,
    RouteID INT NOT NULL,
    AircraftID INT NOT NULL,
    Departure_Time DATETIME NOT NULL,
    Arrival_Time DATETIME NOT NULL,
    Flight_Date DATE NOT NULL,
    FlightStatusID INT NOT NULL,
    Gate_Number VARCHAR(10) NULL,
    
    FOREIGN KEY (RouteID) REFERENCES Route(RouteID),
    FOREIGN KEY (AircraftID) REFERENCES Aircraft(AircraftID),
    FOREIGN KEY (FlightStatusID) REFERENCES Flight_Status(FlightStatusID),
    UNIQUE KEY (Flight_Number, Flight_Date)
);

-- Ticket_Type table
CREATE TABLE Ticket_Type (
    TicketTypeID INT AUTO_INCREMENT PRIMARY KEY,
    Type_Name VARCHAR(50) NOT NULL UNIQUE,
    Base_Fare DECIMAL(10, 2) NOT NULL,
    Description VARCHAR(255) NULL
);

-- Payment_Method table
CREATE TABLE Payment_Method (
    PaymentMethodID INT AUTO_INCREMENT PRIMARY KEY,
    Method_Name VARCHAR(50) NOT NULL UNIQUE,
    Description VARCHAR(255) NULL
);

-- Booking table
CREATE TABLE Booking (
    BookingID INT AUTO_INCREMENT PRIMARY KEY,
    PassengerID INT NOT NULL,
    FlightID INT NOT NULL,
    Booking_Date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Booking_Status VARCHAR(20) NOT NULL DEFAULT 'Pending',
    Total_Amount DECIMAL(10, 2) NOT NULL,
    TicketTypeID INT NOT NULL,
    
    FOREIGN KEY (PassengerID) REFERENCES Passenger(PassengerID),
    FOREIGN KEY (FlightID) REFERENCES Flight(FlightID),
    FOREIGN KEY (TicketTypeID) REFERENCES Ticket_Type(TicketTypeID)
);

-- Payment table
CREATE TABLE Payment (
    PaymentID INT AUTO_INCREMENT PRIMARY KEY,
    BookingID INT NOT NULL,
    Payment_Date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Amount DECIMAL(10, 2) NOT NULL,
    PaymentMethodID INT NOT NULL,
    TransactionID VARCHAR(100) NULL UNIQUE,
    Payment_Status VARCHAR(20) NOT NULL DEFAULT 'Pending',
    
    FOREIGN KEY (BookingID) REFERENCES Booking(BookingID),
    FOREIGN KEY (PaymentMethodID) REFERENCES Payment_Method(PaymentMethodID)
);

-- Flight_Seat table
CREATE TABLE Flight_Seat (
    FlightSeatID INT AUTO_INCREMENT PRIMARY KEY,
    FlightID INT NOT NULL,
    SeatID INT NOT NULL,
    Is_Booked BOOLEAN NOT NULL DEFAULT 0,
    
    FOREIGN KEY (FlightID) REFERENCES Flight(FlightID) ON DELETE CASCADE,
    FOREIGN KEY (SeatID) REFERENCES Seat(SeatID),
    UNIQUE KEY (FlightID, SeatID)
);

-- Booking_Seat table
CREATE TABLE Booking_Seat (
    BookingSeatID INT AUTO_INCREMENT PRIMARY KEY,
    BookingID INT NOT NULL,
    SeatID INT NOT NULL,
    
    FOREIGN KEY (BookingID) REFERENCES Booking(BookingID) ON DELETE CASCADE,
    FOREIGN KEY (SeatID) REFERENCES Seat(SeatID),
    UNIQUE KEY (BookingID, SeatID)
);

-- =====================================================
-- INSERT SAMPLE DATA
-- =====================================================

-- Flight Statuses
INSERT INTO Flight_Status (Status_Name, Description) VALUES
('Scheduled', 'Flight is scheduled and on time'),
('Delayed', 'Flight is delayed'),
('Boarding', 'Passengers are boarding'),
('Departed', 'Flight has departed'),
('Cancelled', 'Flight has been cancelled');

-- Payment Methods
INSERT INTO Payment_Method (Method_Name, Description) VALUES
('Credit Card', 'Payment via credit card'),
('Debit Card', 'Payment via debit card'),
('PayPal', 'Payment via PayPal account'),
('Bank Transfer', 'Direct bank transfer'),
('Cash', 'Cash payment');

-- Ticket Types
INSERT INTO Ticket_Type (Type_Name, Base_Fare, Description) VALUES
('Economy', 350.00, 'Standard economy class ticket'),
('Premium Economy', 550.00, 'Enhanced economy with extra legroom'),
('Business', 1200.00, 'Business class with premium service'),
('First Class', 2500.00, 'First class with luxury amenities');

-- Airports
INSERT INTO Airport (Airport_Name, City, Country, IATA_Code, ICAO_Code, Timezone) VALUES
('Cairo International Airport', 'Cairo', 'Egypt', 'CAI', 'HECA', 'Africa/Cairo'),
('Alexandria Borg El Arab Airport', 'Alexandria', 'Egypt', 'HBE', 'HEBA', 'Africa/Cairo'),
('Jeddah King Abdulaziz Airport', 'Jeddah', 'Saudi Arabia', 'JED', 'OEJN', 'Asia/Riyadh'),
('Dubai International Airport', 'Dubai', 'UAE', 'DXB', 'OMDB', 'Asia/Dubai'),
('London Heathrow', 'London', 'UK', 'LHR', 'EGLL', 'Europe/London'),
('New York JFK', 'New York', 'USA', 'JFK', 'KJFK', 'America/New_York'),
('Paris Charles de Gaulle', 'Paris', 'France', 'CDG', 'LFPG', 'Europe/Paris');
  
-- Routes  
INSERT INTO Route (Origin_AirportID, Destination_AirportID, Distance, Estimated_Time) VALUES
(2, 3, 1200.00, '02:15:00'),  -- 1: Alexandria to Jeddah
(1, 4, 2500.00, '03:30:00'),  -- 2: Cairo to Dubai
(1, 5, 3500.00, '05:00:00'),  -- 3: Cairo to London
(1, 6, 9000.00, '11:00:00'),  -- 4: Cairo to New York
(4, 5, 5500.00, '07:00:00'),  -- 5: Dubai to London
(3, 2, 1200.00, '02:15:00'),  -- 6: Jeddah to Alexandria
(1, 2, 220.00, '00:45:00'),   -- 7: Cairo to Alexandria
(7, 1, 220.00, '00:45:00'),   -- 8: Paris to Cairo
(5, 6, 220.00, '00:45:00'),  -- 9: London to New York
(6, 5, 220.00, '00:45:00'),   -- 10: New York to London
(3, 4, 220.00, '00:45:00'),   -- 11:Jeddah to Dubai
(4, 3, 220.00, '00:45:00');   -- 12: Dubai to Jeddah




-- Aircraft
INSERT INTO Aircraft (Model, Manufacturer, Total_Seats, Year_Manufactured, Aircraft_Type, Registration_Number, Status) VALUES
('Boeing 737-800', 'Boeing', 189, 2018, 'Narrow-body', 'SU-AAA', 'Active'),
('Airbus A320', 'Airbus', 180, 2019, 'Narrow-body', 'SU-BBB', 'Active'),
('Boeing 777-300ER', 'Boeing', 396, 2020, 'Wide-body', 'SU-CCC', 'Active'),
('Airbus A380', 'Airbus', 525, 2021, 'Wide-body', 'SU-DDD', 'Active'),
('Boeing 787-9 Dreamliner', 'Boeing', 296, 2022, 'Wide-body', 'SU-EEE', 'Active'),
('Airbus A350-900', 'Airbus', 325, 2023, 'Wide-body', 'SU-FFF', 'Active'),
('Boeing 737 MAX 8', 'Boeing', 178, 2023, 'Narrow-body', 'SU-GGG', 'Active'),
('Embraer E195-E2', 'Embraer', 132, 2022, 'Narrow-body', 'SU-HHH', 'Active');

-- Seats for Aircraft 1 - Business Class
INSERT INTO Seat (AircraftID, Seat_Number, Seat_Class) VALUES
(1, '1A', 'Business'), (1, '1B', 'Business'), (1, '1C', 'Business'),
(1, '1D', 'Business'), (1, '1E', 'Business'), (1, '1F', 'Business'),
(1, '2A', 'Business'), (1, '2B', 'Business'), (1, '2C', 'Business'),
(1, '2D', 'Business'), (1, '2E', 'Business'), (1, '2F', 'Business'),
(1, '3A', 'Business'), (1, '3B', 'Business'), (1, '3C', 'Business'),
(1, '3D', 'Business'), (1, '3E', 'Business'), (1, '3F', 'Business'),
(1, '4A', 'Business'), (1, '4B', 'Business'), (1, '4C', 'Business'),
(1, '4D', 'Business'), (1, '4E', 'Business'), (1, '4F', 'Business'),
(1, '5A', 'Business'), (1, '5B', 'Business'), (1, '5C', 'Business'),
(1, '5D', 'Business'), (1, '5E', 'Business'), (1, '5F', 'Business'),
(1, '6A', 'Business'), (1, '6B', 'Business'), (1, '6C', 'Business'),
(1, '6D', 'Business'), (1, '6E', 'Business'), (1, '6F', 'Business'),
(1, '7A', 'Business'), (1, '7B', 'Business'), (1, '7C', 'Business'),
(1, '7D', 'Business'), (1, '7E', 'Business'), (1, '7F', 'Business'),
(1, '8A', 'Business'), (1, '8B', 'Business'), (1, '8C', 'Business'),
(1, '8D', 'Business'), (1, '8E', 'Business'), (1, '8F', 'Business'),
(1, '9A', 'Business'), (1, '9B', 'Business'), (1, '9C', 'Business'),
(1, '9D', 'Business'), (1, '9E', 'Business'), (1, '9F', 'Business');

-- Seats for Aircraft 1 - Economy Class
INSERT INTO Seat (AircraftID, Seat_Number, Seat_Class) VALUES
(1, '10A', 'Economy'), (1, '10B', 'Economy'), (1, '10C', 'Economy'),
(1, '10D', 'Economy'), (1, '10E', 'Economy'), (1, '10F', 'Economy'),
(1, '11A', 'Economy'), (1, '11B', 'Economy'), (1, '11C', 'Economy'),
(1, '11D', 'Economy'), (1, '11E', 'Economy'), (1, '11F', 'Economy'),
(1, '12A', 'Economy'), (1, '12B', 'Economy'), (1, '12C', 'Economy'),
(1, '12D', 'Economy'), (1, '12E', 'Economy'), (1, '12F', 'Economy'),
(1, '13A', 'Economy'), (1, '13B', 'Economy'), (1, '13C', 'Economy'),
(1, '13D', 'Economy'), (1, '13E', 'Economy'), (1, '13F', 'Economy'),
(1, '14A', 'Economy'), (1, '14B', 'Economy'), (1, '14C', 'Economy'),
(1, '14D', 'Economy'), (1, '14E', 'Economy'), (1, '14F', 'Economy'),
(1, '15A', 'Economy'), (1, '15B', 'Economy'), (1, '15C', 'Economy'),
(1, '15D', 'Economy'), (1, '15E', 'Economy'), (1, '15F', 'Economy'),
(1, '16A', 'Economy'), (1, '16B', 'Economy'), (1, '16C', 'Economy'),
(1, '16D', 'Economy'), (1, '16E', 'Economy'), (1, '16F', 'Economy'),
(1, '17A', 'Economy'), (1, '17B', 'Economy'), (1, '17C', 'Economy'),
(1, '17D', 'Economy'), (1, '17E', 'Economy'), (1, '17F', 'Economy'),
(1, '18A', 'Economy'), (1, '18B', 'Economy'), (1, '18C', 'Economy'),
(1, '18D', 'Economy'), (1, '18E', 'Economy'), (1, '18F', 'Economy'),
(1, '19A', 'Economy'), (1, '19B', 'Economy'), (1, '19C', 'Economy'),
(1, '19D', 'Economy'), (1, '19E', 'Economy'), (1, '19F', 'Economy'),
(1, '20A', 'Economy'), (1, '20B', 'Economy'), (1, '20C', 'Economy'),
(1, '20D', 'Economy'), (1, '20E', 'Economy'), (1, '20F', 'Economy'),
(1, '21A', 'Economy'), (1, '21B', 'Economy'), (1, '21C', 'Economy'),
(1, '21D', 'Economy'), (1, '21E', 'Economy'), (1, '21F', 'Economy'),
(1, '22A', 'Economy'), (1, '22B', 'Economy'), (1, '22C', 'Economy'),
(1, '22D', 'Economy'), (1, '22E', 'Economy'), (1, '22F', 'Economy'),
(1, '23A', 'Economy'), (1, '23B', 'Economy'), (1, '23C', 'Economy'),
(1, '23D', 'Economy'), (1, '23E', 'Economy'), (1, '23F', 'Economy'),
(1, '24A', 'Economy'), (1, '24B', 'Economy'), (1, '24C', 'Economy'),
(1, '24D', 'Economy'), (1, '24E', 'Economy'), (1, '24F', 'Economy'),
(1, '25A', 'Economy'), (1, '25B', 'Economy'), (1, '25C', 'Economy'),
(1, '25D', 'Economy'), (1, '25E', 'Economy'), (1, '25F', 'Economy'),
(1, '26A', 'Economy'), (1, '26B', 'Economy'), (1, '26C', 'Economy'),
(1, '26D', 'Economy'), (1, '26E', 'Economy'), (1, '26F', 'Economy'),
(1, '27A', 'Economy'), (1, '27B', 'Economy'), (1, '27C', 'Economy'),
(1, '27D', 'Economy'), (1, '27E', 'Economy'), (1, '27F', 'Economy'),
(1, '28A', 'Economy'), (1, '28B', 'Economy'), (1, '28C', 'Economy'),
(1, '28D', 'Economy'), (1, '28E', 'Economy'), (1, '28F', 'Economy'),
(1, '29A', 'Economy'), (1, '29B', 'Economy'), (1, '29C', 'Economy'),
(1, '29D', 'Economy'), (1, '29E', 'Economy'), (1, '29F', 'Economy'),
(1, '30A', 'Economy'), (1, '30B', 'Economy'), (1, '30C', 'Economy'),
(1, '30D', 'Economy'), (1, '30E', 'Economy'), (1, '30F', 'Economy'),
(1, '31A', 'Economy'), (1, '31B', 'Economy'), (1, '31C', 'Economy'),
(1, '31D', 'Economy'), (1, '31E', 'Economy'), (1, '31F', 'Economy'),
(1, '32A', 'Economy'), (1, '32B', 'Economy'), (1, '32C', 'Economy'),
(1, '32D', 'Economy'), (1, '32E', 'Economy'), (1, '32F', 'Economy'),
(1, '33A', 'Economy'), (1, '33B', 'Economy'), (1, '33C', 'Economy'),
(1, '33D', 'Economy'), (1, '33E', 'Economy'), (1, '33F', 'Economy'),
(1, '34A', 'Economy'), (1, '34B', 'Economy'), (1, '34C', 'Economy'),
(1, '34D', 'Economy'), (1, '34E', 'Economy'), (1, '34F', 'Economy'),
(1, '35A', 'Economy'), (1, '35B', 'Economy'), (1, '35C', 'Economy'),
(1, '35D', 'Economy'), (1, '35E', 'Economy'), (1, '35F', 'Economy');

-- Seats for Aircraft 2 - Business Class
INSERT IGNORE INTO Seat (AircraftID, Seat_Number, Seat_Class) VALUES
(2, '1A', 'Business'), (2, '1B', 'Business'), (2, '1C', 'Business'),
(2, '1D', 'Business'), (2, '1E', 'Business'), (2, '1F', 'Business'),
(2, '2A', 'Business'), (2, '2B', 'Business'), (2, '2C', 'Business'),
(2, '2D', 'Business'), (2, '2E', 'Business'), (2, '2F', 'Business'),
(2, '3A', 'Business'), (2, '3B', 'Business'), (2, '3C', 'Business'),
(2, '3D', 'Business'), (2, '3E', 'Business'), (2, '3F', 'Business'),
(2, '1A', 'Business'), (2, '1B', 'Business'), (2, '1C', 'Business'),
(2, '1D', 'Business'), (2, '1E', 'Business'), (2, '1F', 'Business'),
(2, '2A', 'Business'), (2, '2B', 'Business'), (2, '2C', 'Business'),
(2, '2D', 'Business'), (2, '2E', 'Business'), (2, '2F', 'Business'),
(2, '3A', 'Business'), (2, '3B', 'Business'), (2, '3C', 'Business'),
(2, '3D', 'Business'), (2, '3E', 'Business'), (2, '3F', 'Business'),
(2, '4A', 'Business'), (2, '4B', 'Business'), (2, '4C', 'Business'),
(2, '4D', 'Business'), (2, '4E', 'Business'), (2, '4F', 'Business'),
(2, '5A', 'Business'), (2, '5B', 'Business'), (2, '5C', 'Business'),
(2, '5D', 'Business'), (2, '5E', 'Business'), (2, '5F', 'Business'),
(2, '6A', 'Business'), (2, '6B', 'Business'), (2, '6C', 'Business'),
(2, '6D', 'Business'), (2, '6E', 'Business'), (2, '6F', 'Business'),
(2, '7A', 'Business'), (2, '7B', 'Business'), (2, '7C', 'Business'),
(2, '7D', 'Business'), (2, '7E', 'Business'), (2, '7F', 'Business'),
(2, '8A', 'Business'), (2, '8B', 'Business'), (2, '8C', 'Business'),
(2, '8D', 'Business'), (2, '8E', 'Business'), (2, '8F', 'Business'),
(2, '9A', 'Business'), (2, '9B', 'Business'), (2, '9C', 'Business'),
(2, '9D', 'Business'), (2, '9E', 'Business'), (2, '9F', 'Business');

-- Seats for Aircraft 2 - Economy Class
INSERT IGNORE INTO Seat (AircraftID, Seat_Number, Seat_Class) VALUES
(2, '10A', 'Economy'), (2, '10B', 'Economy'), (2, '10C', 'Economy'),
(2, '10D', 'Economy'), (2, '10E', 'Economy'), (2, '10F', 'Economy'),
(2, '11A', 'Economy'), (2, '11B', 'Economy'), (2, '11C', 'Economy'),
(2, '11D', 'Economy'), (2, '11E', 'Economy'), (2, '11F', 'Economy'),
(2, '12A', 'Economy'), (2, '12B', 'Economy'), (2, '12C', 'Economy'),
(2, '12D', 'Economy'), (2, '12E', 'Economy'), (2, '12F', 'Economy'),
(2, '13A', 'Economy'), (2, '13B', 'Economy'), (2, '13C', 'Economy'),
(2, '13D', 'Economy'), (2, '13E', 'Economy'), (2, '13F', 'Economy'),
(2, '14A', 'Economy'), (2, '14B', 'Economy'), (2, '14C', 'Economy'),
(2, '14D', 'Economy'), (2, '14E', 'Economy'), (2, '14F', 'Economy'),
(2, '15A', 'Economy'), (2, '15B', 'Economy'), (2, '15C', 'Economy'),
(2, '15D', 'Economy'), (2, '15E', 'Economy'), (2, '15F', 'Economy'),
(2, '16A', 'Economy'), (2, '16B', 'Economy'), (2, '16C', 'Economy'),
(2, '16D', 'Economy'), (2, '16E', 'Economy'), (2, '16F', 'Economy'),
(2, '17A', 'Economy'), (2, '17B', 'Economy'), (2, '17C', 'Economy'),
(2, '17D', 'Economy'), (2, '17E', 'Economy'), (2, '17F', 'Economy'),
(2, '18A', 'Economy'), (2, '18B', 'Economy'), (2, '18C', 'Economy'),
(2, '18D', 'Economy'), (2, '18E', 'Economy'), (2, '18F', 'Economy'),
(2, '19A', 'Economy'), (2, '19B', 'Economy'), (2, '19C', 'Economy'),
(2, '19D', 'Economy'), (2, '19E', 'Economy'), (2, '19F', 'Economy'),
(2, '20A', 'Economy'), (2, '20B', 'Economy'), (2, '20C', 'Economy'),
(2, '20D', 'Economy'), (2, '20E', 'Economy'), (2, '20F', 'Economy'),
(2, '21A', 'Economy'), (2, '21B', 'Economy'), (2, '21C', 'Economy'),
(2, '21D', 'Economy'), (2, '21E', 'Economy'), (2, '21F', 'Economy'),
(2, '22A', 'Economy'), (2, '22B', 'Economy'), (2, '22C', 'Economy'),
(2, '22D', 'Economy'), (2, '22E', 'Economy'), (2, '22F', 'Economy'),
(2, '23A', 'Economy'), (2, '23B', 'Economy'), (2, '23C', 'Economy'),
(2, '23D', 'Economy'), (2, '23E', 'Economy'), (2, '23F', 'Economy'),
(2, '24A', 'Economy'), (2, '24B', 'Economy'), (2, '24C', 'Economy'),
(2, '24D', 'Economy'), (2, '24E', 'Economy'), (2, '24F', 'Economy'),
(2, '25A', 'Economy'), (2, '25B', 'Economy'), (2, '25C', 'Economy'),
(2, '25D', 'Economy'), (2, '25E', 'Economy'), (2, '25F', 'Economy'),
(2, '26A', 'Economy'), (2, '26B', 'Economy'), (2, '26C', 'Economy'),
(2, '26D', 'Economy'), (2, '26E', 'Economy'), (2, '26F', 'Economy'),
(2, '27A', 'Economy'), (2, '27B', 'Economy'), (2, '27C', 'Economy'),
(2, '27D', 'Economy'), (2, '27E', 'Economy'), (2, '27F', 'Economy'),
(2, '28A', 'Economy'), (2, '28B', 'Economy'), (2, '28C', 'Economy'),
(2, '28D', 'Economy'), (2, '28E', 'Economy'), (2, '28F', 'Economy'),
(2, '29A', 'Economy'), (2, '29B', 'Economy'), (2, '29C', 'Economy'),
(2, '29D', 'Economy'), (2, '29E', 'Economy'), (2, '29F', 'Economy'),
(2, '30A', 'Economy'), (2, '30B', 'Economy'), (2, '30C', 'Economy'),
(2, '30D', 'Economy'), (2, '30E', 'Economy'), (2, '30F', 'Economy'),
(2, '31A', 'Economy'), (2, '31B', 'Economy'), (2, '31C', 'Economy'),
(2, '31D', 'Economy'), (2, '31E', 'Economy'), (2, '31F', 'Economy'),
(2, '32A', 'Economy'), (2, '32B', 'Economy'), (2, '32C', 'Economy'),
(2, '32D', 'Economy'), (2, '32E', 'Economy'), (2, '32F', 'Economy'),
(2, '33A', 'Economy'), (2, '33B', 'Economy'), (2, '33C', 'Economy'),
(2, '33D', 'Economy'), (2, '33E', 'Economy'), (2, '33F', 'Economy'),
(2, '34A', 'Economy'), (2, '34B', 'Economy'), (2, '34C', 'Economy'),
(2, '34D', 'Economy'), (2, '34E', 'Economy'), (2, '34F', 'Economy'),
(2, '35A', 'Economy'), (2, '35B', 'Economy'), (2, '35C', 'Economy'),
(2, '35D', 'Economy'), (2, '35E', 'Economy'), (2, '35F', 'Economy');

-- Seats for Aircraft 3 (Boeing 777-300ER - used by MS300 and MS400)
-- This is a wide-body aircraft with more seats

-- Seats for Aircraft 3 - First Class
INSERT IGNORE INTO Seat (AircraftID, Seat_Number, Seat_Class) VALUES
(3, '1A', 'First Class'), (3, '1B', 'First Class'), (3, '1C', 'First Class'), (3, '1D', 'First Class'),
(3, '2A', 'First Class'), (3, '2B', 'First Class'), (3, '2C', 'First Class'), (3, '2D', 'First Class'),
(3, '3A', 'First Class'), (3, '3B', 'First Class'), (3, '3C', 'First Class'), (3, '3D', 'First Class');

-- Seats for Aircraft 3 - Business Class
INSERT IGNORE INTO Seat (AircraftID, Seat_Number, Seat_Class) VALUES
(3, '4A', 'Business'), (3, '4B', 'Business'), (3, '4C', 'Business'), (3, '4D', 'Business'),
(3, '5A', 'Business'), (3, '5B', 'Business'), (3, '5C', 'Business'), (3, '5D', 'Business'),
(3, '6A', 'Business'), (3, '6B', 'Business'), (3, '6C', 'Business'), (3, '6D', 'Business'),
(3, '7A', 'Business'), (3, '7B', 'Business'), (3, '7C', 'Business'), (3, '7D', 'Business'),
(3, '8A', 'Business'), (3, '8B', 'Business'), (3, '8C', 'Business'), (3, '8D', 'Business'),
(3, '9A', 'Business'), (3, '9B', 'Business'), (3, '9C', 'Business'), (3, '9D', 'Business'),
(3, '10A', 'Business'), (3, '10B', 'Business'), (3, '10C', 'Business'), (3, '10D', 'Business'), (3, '10E', 'Business'), (3, '10F', 'Business'),
(3, '11A', 'Business'), (3, '11B', 'Business'), (3, '11C', 'Business'), (3, '11D', 'Business'), (3, '11E', 'Business'), (3, '11F', 'Business'),
(3, '12A', 'Business'), (3, '12B', 'Business'), (3, '12C', 'Business'), (3, '12D', 'Business'), (3, '12E', 'Business'), (3, '12F', 'Business');

-- Seats for Aircraft 3 - Premium Economy
INSERT IGNORE INTO Seat (AircraftID, Seat_Number, Seat_Class) VALUES
(3, '10A', 'Premium Economy'), (3, '10B', 'Premium Economy'), (3, '10C', 'Premium Economy'), 
(3, '10D', 'Premium Economy'), (3, '10E', 'Premium Economy'), (3, '10F', 'Premium Economy'),
(3, '11A', 'Premium Economy'), (3, '11B', 'Premium Economy'), (3, '11C', 'Premium Economy'),
(3, '11D', 'Premium Economy'), (3, '11E', 'Premium Economy'), (3, '11F', 'Premium Economy'),
(3, '12A', 'Premium Economy'), (3, '12B', 'Premium Economy'), (3, '12C', 'Premium Economy'),
(3, '12D', 'Premium Economy'), (3, '12E', 'Premium Economy'), (3, '12F', 'Premium Economy'),
(3, '13A', 'Premium Economy'), (3, '13B', 'Premium Economy'), (3, '13C', 'Premium Economy'), 
(3, '13D', 'Premium Economy'), (3, '13E', 'Premium Economy'), (3, '13F', 'Premium Economy'),
(3, '14A', 'Premium Economy'), (3, '14B', 'Premium Economy'), (3, '14C', 'Premium Economy'),
(3, '14D', 'Premium Economy'), (3, '14E', 'Premium Economy'), (3, '14F', 'Premium Economy'),
(3, '15A', 'Premium Economy'), (3, '15B', 'Premium Economy'), (3, '15C', 'Premium Economy'),
(3, '15D', 'Premium Economy'), (3, '15E', 'Premium Economy'), (3, '15F', 'Premium Economy'),
(3, '16A', 'Premium Economy'), (3, '16B', 'Premium Economy'), (3, '16C', 'Premium Economy'),
(3, '16D', 'Premium Economy'), (3, '16E', 'Premium Economy'), (3, '16F', 'Premium Economy'),
(3, '17A', 'Premium Economy'), (3, '17B', 'Premium Economy'), (3, '17C', 'Premium Economy'),
(3, '17D', 'Premium Economy'), (3, '17E', 'Premium Economy'), (3, '17F', 'Premium Economy'),
(3, '18A', 'Premium Economy'), (3, '18B', 'Premium Economy'), (3, '18C', 'Premium Economy'),
(3, '18D', 'Premium Economy'), (3, '18E', 'Premium Economy'), (3, '18F', 'Premium Economy'),
(3, '19A', 'Premium Economy'), (3, '19B', 'Premium Economy'), (3, '19C', 'Premium Economy'),
(3, '19D', 'Premium Economy'), (3, '19E', 'Premium Economy'), (3, '19F', 'Premium Economy');

-- Seats for Aircraft 3 - Economy Class
INSERT IGNORE INTO Seat (AircraftID, Seat_Number, Seat_Class) VALUES
(3, '20A', 'Economy'), (3, '20B', 'Economy'), (3, '20C', 'Economy'), 
(3, '20D', 'Economy'), (3, '20E', 'Economy'), (3, '20F', 'Economy'),
(3, '21A', 'Economy'), (3, '21B', 'Economy'), (3, '21C', 'Economy'),
(3, '21D', 'Economy'), (3, '21E', 'Economy'), (3, '21F', 'Economy'),
(3, '22A', 'Economy'), (3, '22B', 'Economy'), (3, '22C', 'Economy'),
(3, '22D', 'Economy'), (3, '22E', 'Economy'), (3, '22F', 'Economy'),
(3, '23A', 'Economy'), (3, '23B', 'Economy'), (3, '23C', 'Economy'),
(3, '23D', 'Economy'), (3, '23E', 'Economy'), (3, '23F', 'Economy'),
(3, '24A', 'Economy'), (3, '24B', 'Economy'), (3, '24C', 'Economy'),
(3, '24D', 'Economy'), (3, '24E', 'Economy'), (3, '24F', 'Economy'),
(3, '25A', 'Economy'), (3, '25B', 'Economy'), (3, '25C', 'Economy'),
(3, '25D', 'Economy'), (3, '25E', 'Economy'), (3, '25F', 'Economy'),
(3, '26A', 'Economy'), (3, '26B', 'Economy'), (3, '26C', 'Economy'),
(3, '26D', 'Economy'), (3, '26E', 'Economy'), (3, '26F', 'Economy'),
(3, '27A', 'Economy'), (3, '27B', 'Economy'), (3, '27C', 'Economy'),
(3, '27D', 'Economy'), (3, '27E', 'Economy'), (3, '27F', 'Economy'),
(3, '28A', 'Economy'), (3, '28B', 'Economy'), (3, '28C', 'Economy'),
(3, '28D', 'Economy'), (3, '28E', 'Economy'), (3, '28F', 'Economy'),
(3, '29A', 'Economy'), (3, '29B', 'Economy'), (3, '29C', 'Economy'),
(3, '29D', 'Economy'), (3, '29E', 'Economy'), (3, '29F', 'Economy'),
(3, '30A', 'Economy'), (3, '30B', 'Economy'), (3, '30C', 'Economy'),
(3, '30D', 'Economy'), (3, '30E', 'Economy'), (3, '30F', 'Economy'),
(3, '31A', 'Economy'), (3, '31B', 'Economy'), (3, '31C', 'Economy'),
(3, '31D', 'Economy'), (3, '31E', 'Economy'), (3, '31F', 'Economy'),
(3, '32A', 'Economy'), (3, '32B', 'Economy'), (3, '32C', 'Economy'),
(3, '32D', 'Economy'), (3, '32E', 'Economy'), (3, '32F', 'Economy'),
(3, '33A', 'Economy'), (3, '33B', 'Economy'), (3, '33C', 'Economy'),
(3, '33D', 'Economy'), (3, '33E', 'Economy'), (3, '33F', 'Economy'),
(3, '34A', 'Economy'), (3, '34B', 'Economy'), (3, '34C', 'Economy'),
(3, '34D', 'Economy'), (3, '34E', 'Economy'), (3, '34F', 'Economy'),
(3, '35A', 'Economy'), (3, '35B', 'Economy'), (3, '35C', 'Economy'),
(3, '35D', 'Economy'), (3, '35E', 'Economy'), (3, '35F', 'Economy');

INSERT INTO Seat (AircraftID, Seat_Number, Seat_Class) VALUES
-- UPPER DECK - First Class (Rows 1-2, 7 seats per row = 14 seats)
(4,'1A','First Class'),(4,'1B','First Class'),(4,'1C','First Class'),(4,'1D','First Class'),(4,'1E','First Class'),(4,'1F','First Class'),(4,'1G','First Class'),
(4,'2A','First Class'),(4,'2B','First Class'),(4,'2C','First Class'),(4,'2D','First Class'),(4,'2E','First Class'),(4,'2F','First Class'),(4,'2G','First Class'),

-- UPPER DECK - Business Class (Rows 3-12, 7-8 seats per row = 76 seats)
(4,'3A','Business'),(4,'3B','Business'),(4,'3C','Business'),(4,'3D','Business'),(4,'3E','Business'),(4,'3F','Business'),(4,'3G','Business'),
(4,'4A','Business'),(4,'4B','Business'),(4,'4C','Business'),(4,'4D','Business'),(4,'4E','Business'),(4,'4F','Business'),(4,'4G','Business'),
(4,'5A','Business'),(4,'5B','Business'),(4,'5C','Business'),(4,'5D','Business'),(4,'5E','Business'),(4,'5F','Business'),(4,'5G','Business'),(4,'5H','Business'),
(4,'6A','Business'),(4,'6B','Business'),(4,'6C','Business'),(4,'6D','Business'),(4,'6E','Business'),(4,'6F','Business'),(4,'6G','Business'),(4,'6H','Business'),
(4,'7A','Business'),(4,'7B','Business'),(4,'7C','Business'),(4,'7D','Business'),(4,'7E','Business'),(4,'7F','Business'),(4,'7G','Business'),(4,'7H','Business'),
(4,'8A','Business'),(4,'8B','Business'),(4,'8C','Business'),(4,'8D','Business'),(4,'8E','Business'),(4,'8F','Business'),(4,'8G','Business'),(4,'8H','Business'),
(4,'9A','Business'),(4,'9B','Business'),(4,'9C','Business'),(4,'9D','Business'),(4,'9E','Business'),(4,'9F','Business'),(4,'9G','Business'),(4,'9H','Business'),
(4,'10A','Business'),(4,'10B','Business'),(4,'10C','Business'),(4,'10D','Business'),(4,'10E','Business'),(4,'10F','Business'),(4,'10G','Business'),
(4,'11A','Business'),(4,'11B','Business'),(4,'11C','Business'),(4,'11D','Business'),(4,'11E','Business'),(4,'11F','Business'),(4,'11G','Business'),
(4,'12A','Business'),(4,'12B','Business'),(4,'12C','Business'),(4,'12D','Business'),(4,'12E','Business'),(4,'12F','Business'),(4,'12G','Business'),

-- MAIN DECK - Premium Economy (Rows 13-23, 8 seats per row + partial = 92 seats)
(4,'13A','Premium Economy'),(4,'13B','Premium Economy'),(4,'13C','Premium Economy'),(4,'13D','Premium Economy'),(4,'13E','Premium Economy'),(4,'13F','Premium Economy'),(4,'13G','Premium Economy'),(4,'13H','Premium Economy'),
(4,'14A','Premium Economy'),(4,'14B','Premium Economy'),(4,'14C','Premium Economy'),(4,'14D','Premium Economy'),(4,'14E','Premium Economy'),(4,'14F','Premium Economy'),(4,'14G','Premium Economy'),(4,'14H','Premium Economy'),
(4,'15A','Premium Economy'),(4,'15B','Premium Economy'),(4,'15C','Premium Economy'),(4,'15D','Premium Economy'),(4,'15E','Premium Economy'),(4,'15F','Premium Economy'),(4,'15G','Premium Economy'),(4,'15H','Premium Economy'),
(4,'16A','Premium Economy'),(4,'16B','Premium Economy'),(4,'16C','Premium Economy'),(4,'16D','Premium Economy'),(4,'16E','Premium Economy'),(4,'16F','Premium Economy'),(4,'16G','Premium Economy'),(4,'16H','Premium Economy'),
(4,'17A','Premium Economy'),(4,'17B','Premium Economy'),(4,'17C','Premium Economy'),(4,'17D','Premium Economy'),(4,'17E','Premium Economy'),(4,'17F','Premium Economy'),(4,'17G','Premium Economy'),(4,'17H','Premium Economy'),
(4,'18A','Premium Economy'),(4,'18B','Premium Economy'),(4,'18C','Premium Economy'),(4,'18D','Premium Economy'),(4,'18E','Premium Economy'),(4,'18F','Premium Economy'),(4,'18G','Premium Economy'),(4,'18H','Premium Economy'),
(4,'19A','Premium Economy'),(4,'19B','Premium Economy'),(4,'19C','Premium Economy'),(4,'19D','Premium Economy'),(4,'19E','Premium Economy'),(4,'19F','Premium Economy'),(4,'19G','Premium Economy'),(4,'19H','Premium Economy'),
(4,'20A','Premium Economy'),(4,'20B','Premium Economy'),(4,'20C','Premium Economy'),(4,'20D','Premium Economy'),(4,'20E','Premium Economy'),(4,'20F','Premium Economy'),(4,'20G','Premium Economy'),(4,'20H','Premium Economy'),
(4,'21A','Premium Economy'),(4,'21B','Premium Economy'),(4,'21C','Premium Economy'),(4,'21D','Premium Economy'),(4,'21E','Premium Economy'),(4,'21F','Premium Economy'),(4,'21G','Premium Economy'),(4,'21H','Premium Economy'),
(4,'22A','Premium Economy'),(4,'22B','Premium Economy'),(4,'22C','Premium Economy'),(4,'22D','Premium Economy'),(4,'22E','Premium Economy'),(4,'22F','Premium Economy'),(4,'22G','Premium Economy'),(4,'22H','Premium Economy'),
(4,'23A','Premium Economy'),(4,'23B','Premium Economy'),(4,'23C','Premium Economy'),(4,'23D','Premium Economy'),(4,'23E','Premium Economy'),(4,'23F','Premium Economy'),(4,'23G','Premium Economy'),(4,'23H','Premium Economy'),
(4,'24A','Premium Economy'),(4,'24B','Premium Economy'),(4,'24C','Premium Economy'),(4,'24D','Premium Economy'),

-- MAIN DECK - Economy Class (Rows 25-67, 8-9 seats per row = 343 seats)
(4,'25A','Economy'),(4,'25B','Economy'),(4,'25C','Economy'),(4,'25D','Economy'),(4,'25E','Economy'),(4,'25F','Economy'),(4,'25G','Economy'),(4,'25H','Economy'),
(4,'26A','Economy'),(4,'26B','Economy'),(4,'26C','Economy'),(4,'26D','Economy'),(4,'26E','Economy'),(4,'26F','Economy'),(4,'26G','Economy'),(4,'26H','Economy'),
(4,'27A','Economy'),(4,'27B','Economy'),(4,'27C','Economy'),(4,'27D','Economy'),(4,'27E','Economy'),(4,'27F','Economy'),(4,'27G','Economy'),(4,'27H','Economy'),
(4,'28A','Economy'),(4,'28B','Economy'),(4,'28C','Economy'),(4,'28D','Economy'),(4,'28E','Economy'),(4,'28F','Economy'),(4,'28G','Economy'),(4,'28H','Economy'),
(4,'29A','Economy'),(4,'29B','Economy'),(4,'29C','Economy'),(4,'29D','Economy'),(4,'29E','Economy'),(4,'29F','Economy'),(4,'29G','Economy'),(4,'29H','Economy'),
(4,'30A','Economy'),(4,'30B','Economy'),(4,'30C','Economy'),(4,'30D','Economy'),(4,'30E','Economy'),(4,'30F','Economy'),(4,'30G','Economy'),(4,'30H','Economy'),(4,'30J','Economy'),
(4,'31A','Economy'),(4,'31B','Economy'),(4,'31C','Economy'),(4,'31D','Economy'),(4,'31E','Economy'),(4,'31F','Economy'),(4,'31G','Economy'),(4,'31H','Economy'),(4,'31J','Economy'),
(4,'32A','Economy'),(4,'32B','Economy'),(4,'32C','Economy'),(4,'32D','Economy'),(4,'32E','Economy'),(4,'32F','Economy'),(4,'32G','Economy'),(4,'32H','Economy'),(4,'32J','Economy'),
(4,'33A','Economy'),(4,'33B','Economy'),(4,'33C','Economy'),(4,'33D','Economy'),(4,'33E','Economy'),(4,'33F','Economy'),(4,'33G','Economy'),(4,'33H','Economy'),(4,'33J','Economy'),
(4,'34A','Economy'),(4,'34B','Economy'),(4,'34C','Economy'),(4,'34D','Economy'),(4,'34E','Economy'),(4,'34F','Economy'),(4,'34G','Economy'),(4,'34H','Economy'),(4,'34J','Economy'),
(4,'35A','Economy'),(4,'35B','Economy'),(4,'35C','Economy'),(4,'35D','Economy'),(4,'35E','Economy'),(4,'35F','Economy'),(4,'35G','Economy'),(4,'35H','Economy'),(4,'35J','Economy'),
(4,'36A','Economy'),(4,'36B','Economy'),(4,'36C','Economy'),(4,'36D','Economy'),(4,'36E','Economy'),(4,'36F','Economy'),(4,'36G','Economy'),(4,'36H','Economy'),(4,'36J','Economy'),
(4,'37A','Economy'),(4,'37B','Economy'),(4,'37C','Economy'),(4,'37D','Economy'),(4,'37E','Economy'),(4,'37F','Economy'),(4,'37G','Economy'),(4,'37H','Economy'),(4,'37J','Economy'),
(4,'38A','Economy'),(4,'38B','Economy'),(4,'38C','Economy'),(4,'38D','Economy'),(4,'38E','Economy'),(4,'38F','Economy'),(4,'38G','Economy'),(4,'38H','Economy'),(4,'38J','Economy'),
(4,'39A','Economy'),(4,'39B','Economy'),(4,'39C','Economy'),(4,'39D','Economy'),(4,'39E','Economy'),(4,'39F','Economy'),(4,'39G','Economy'),(4,'39H','Economy'),(4,'39J','Economy'),
(4,'40A','Economy'),(4,'40B','Economy'),(4,'40C','Economy'),(4,'40D','Economy'),(4,'40E','Economy'),(4,'40F','Economy'),(4,'40G','Economy'),(4,'40H','Economy'),(4,'40J','Economy'),
(4,'41A','Economy'),(4,'41B','Economy'),(4,'41C','Economy'),(4,'41D','Economy'),(4,'41E','Economy'),(4,'41F','Economy'),(4,'41G','Economy'),(4,'41H','Economy'),(4,'41J','Economy'),
(4,'42A','Economy'),(4,'42B','Economy'),(4,'42C','Economy'),(4,'42D','Economy'),(4,'42E','Economy'),(4,'42F','Economy'),(4,'42G','Economy'),(4,'42H','Economy'),(4,'42J','Economy'),
(4,'43A','Economy'),(4,'43B','Economy'),(4,'43C','Economy'),(4,'43D','Economy'),(4,'43E','Economy'),(4,'43F','Economy'),(4,'43G','Economy'),(4,'43H','Economy'),(4,'43J','Economy'),
(4,'44A','Economy'),(4,'44B','Economy'),(4,'44C','Economy'),(4,'44D','Economy'),(4,'44E','Economy'),(4,'44F','Economy'),(4,'44G','Economy'),(4,'44H','Economy'),(4,'44J','Economy'),
(4,'45A','Economy'),(4,'45B','Economy'),(4,'45C','Economy'),(4,'45D','Economy'),(4,'45E','Economy'),(4,'45F','Economy'),(4,'45G','Economy'),(4,'45H','Economy'),(4,'45J','Economy'),
(4,'46A','Economy'),(4,'46B','Economy'),(4,'46C','Economy'),(4,'46D','Economy'),(4,'46E','Economy'),(4,'46F','Economy'),(4,'46G','Economy'),(4,'46H','Economy'),(4,'46J','Economy'),
(4,'47A','Economy'),(4,'47B','Economy'),(4,'47C','Economy'),(4,'47D','Economy'),(4,'47E','Economy'),(4,'47F','Economy'),(4,'47G','Economy'),(4,'47H','Economy'),(4,'47J','Economy'),
(4,'48A','Economy'),(4,'48B','Economy'),(4,'48C','Economy'),(4,'48D','Economy'),(4,'48E','Economy'),(4,'48F','Economy'),(4,'48G','Economy'),(4,'48H','Economy'),(4,'48J','Economy'),
(4,'49A','Economy'),(4,'49B','Economy'),(4,'49C','Economy'),(4,'49D','Economy'),(4,'49E','Economy'),(4,'49F','Economy'),(4,'49G','Economy'),(4,'49H','Economy'),(4,'49J','Economy'),
(4,'50A','Economy'),(4,'50B','Economy'),(4,'50C','Economy'),(4,'50D','Economy'),(4,'50E','Economy'),(4,'50F','Economy'),(4,'50G','Economy'),(4,'50H','Economy'),(4,'50J','Economy'),
(4,'51A','Economy'),(4,'51B','Economy'),(4,'51C','Economy'),(4,'51D','Economy'),(4,'51E','Economy'),(4,'51F','Economy'),(4,'51G','Economy'),(4,'51H','Economy'),(4,'51J','Economy'),
(4,'52A','Economy'),(4,'52B','Economy'),(4,'52C','Economy'),(4,'52D','Economy'),(4,'52E','Economy'),(4,'52F','Economy'),(4,'52G','Economy'),(4,'52H','Economy'),(4,'52J','Economy'),
(4,'53A','Economy'),(4,'53B','Economy'),(4,'53C','Economy'),(4,'53D','Economy'),(4,'53E','Economy'),(4,'53F','Economy'),(4,'53G','Economy'),(4,'53H','Economy'),(4,'53J','Economy'),
(4,'54A','Economy'),(4,'54B','Economy'),(4,'54C','Economy'),(4,'54D','Economy'),(4,'54E','Economy'),(4,'54F','Economy'),(4,'54G','Economy'),(4,'54H','Economy'),(4,'54J','Economy'),
(4,'55A','Economy'),(4,'55B','Economy'),(4,'55C','Economy'),(4,'55D','Economy'),(4,'55E','Economy'),(4,'55F','Economy'),(4,'55G','Economy'),(4,'55H','Economy'),(4,'55J','Economy'),
(4,'56A','Economy'),(4,'56B','Economy'),(4,'56C','Economy'),(4,'56D','Economy'),(4,'56E','Economy'),(4,'56F','Economy'),(4,'56G','Economy'),(4,'56H','Economy'),(4,'56J','Economy'),
(4,'57A','Economy'),(4,'57B','Economy'),(4,'57C','Economy'),(4,'57D','Economy'),(4,'57E','Economy'),(4,'57F','Economy'),(4,'57G','Economy'),(4,'57H','Economy'),(4,'57J','Economy'),
(4,'58A','Economy'),(4,'58B','Economy'),(4,'58C','Economy'),(4,'58D','Economy'),(4,'58E','Economy'),(4,'58F','Economy'),(4,'58G','Economy'),(4,'58H','Economy'),(4,'58J','Economy'),
(4,'59A','Economy'),(4,'59B','Economy'),(4,'59C','Economy'),(4,'59D','Economy'),(4,'59E','Economy'),(4,'59F','Economy'),(4,'59G','Economy'),(4,'59H','Economy'),(4,'59J','Economy'),
(4,'60A','Economy'),(4,'60B','Economy'),(4,'60C','Economy'),(4,'60D','Economy'),(4,'60E','Economy'),(4,'60F','Economy'),(4,'60G','Economy'),(4,'60H','Economy'),(4,'60J','Economy'),
(4,'61A','Economy'),(4,'61B','Economy'),(4,'61C','Economy'),(4,'61D','Economy'),(4,'61E','Economy'),(4,'61F','Economy'),(4,'61G','Economy'),(4,'61H','Economy'),(4,'61J','Economy'),
(4,'62A','Economy'),(4,'62B','Economy'),(4,'62C','Economy'),(4,'62D','Economy'),(4,'62E','Economy'),(4,'62F','Economy'),(4,'62G','Economy'),(4,'62H','Economy'),(4,'62J','Economy'),
(4,'63A','Economy'),(4,'63B','Economy'),(4,'63C','Economy'),(4,'63D','Economy'),(4,'63E','Economy'),(4,'63F','Economy'),(4,'63G','Economy'),(4,'63H','Economy'),(4,'63J','Economy'),
(4,'64A','Economy'),(4,'64B','Economy'),(4,'64C','Economy'),(4,'64D','Economy'),(4,'64E','Economy'),(4,'64F','Economy'),(4,'64G','Economy'),(4,'64H','Economy'),(4,'64J','Economy'),
(4,'65A','Economy'),(4,'65B','Economy'),(4,'65C','Economy'),(4,'65D','Economy'),(4,'65E','Economy'),(4,'65F','Economy'),(4,'65G','Economy'),(4,'65H','Economy'),(4,'65J','Economy'),
(4,'66A','Economy'),(4,'66B','Economy'),(4,'66C','Economy'),(4,'66D','Economy'),(4,'66E','Economy'),(4,'66F','Economy'),(4,'66G','Economy'),(4,'66H','Economy'),(4,'66J','Economy'),
(4,'67A','Economy'),(4,'67B','Economy'),(4,'67C','Economy'),(4,'67D','Economy'),(4,'67E','Economy'),(4,'67F','Economy'),(4,'67G','Economy'),(4,'67H','Economy');

-- =====================================================
-- SEATS - AIRCRAFT 5 (Boeing 787-9 Dreamliner - 296 seats)
-- Business: 30, Premium Economy: 48, Economy: 218
-- =====================================================

INSERT INTO Seat (AircraftID, Seat_Number, Seat_Class) VALUES
-- Business Class (Rows 1-5, 6 seats per row = 30 seats)
(5,'1A','Business'),(5,'1C','Business'),(5,'1D','Business'),(5,'1G','Business'),(5,'1H','Business'),(5,'1K','Business'),
(5,'2A','Business'),(5,'2C','Business'),(5,'2D','Business'),(5,'2G','Business'),(5,'2H','Business'),(5,'2K','Business'),
(5,'3A','Business'),(5,'3C','Business'),(5,'3D','Business'),(5,'3G','Business'),(5,'3H','Business'),(5,'3K','Business'),
(5,'4A','Business'),(5,'4C','Business'),(5,'4D','Business'),(5,'4G','Business'),(5,'4H','Business'),(5,'4K','Business'),
(5,'5A','Business'),(5,'5C','Business'),(5,'5D','Business'),(5,'5G','Business'),(5,'5H','Business'),(5,'5K','Business'),

-- Premium Economy (Rows 10-17, 6 seats per row = 48 seats)
(5,'10A','Premium Economy'),(5,'10B','Premium Economy'),(5,'10C','Premium Economy'),(5,'10D','Premium Economy'),(5,'10E','Premium Economy'),(5,'10F','Premium Economy'),
(5,'11A','Premium Economy'),(5,'11B','Premium Economy'),(5,'11C','Premium Economy'),(5,'11D','Premium Economy'),(5,'11E','Premium Economy'),(5,'11F','Premium Economy'),
(5,'12A','Premium Economy'),(5,'12B','Premium Economy'),(5,'12C','Premium Economy'),(5,'12D','Premium Economy'),(5,'12E','Premium Economy'),(5,'12F','Premium Economy'),
(5,'13A','Premium Economy'),(5,'13B','Premium Economy'),(5,'13C','Premium Economy'),(5,'13D','Premium Economy'),(5,'13E','Premium Economy'),(5,'13F','Premium Economy'),
(5,'14A','Premium Economy'),(5,'14B','Premium Economy'),(5,'14C','Premium Economy'),(5,'14D','Premium Economy'),(5,'14E','Premium Economy'),(5,'14F','Premium Economy'),
(5,'15A','Premium Economy'),(5,'15B','Premium Economy'),(5,'15C','Premium Economy'),(5,'15D','Premium Economy'),(5,'15E','Premium Economy'),(5,'15F','Premium Economy'),
(5,'16A','Premium Economy'),(5,'16B','Premium Economy'),(5,'16C','Premium Economy'),(5,'16D','Premium Economy'),(5,'16E','Premium Economy'),(5,'16F','Premium Economy'),
(5,'17A','Premium Economy'),(5,'17B','Premium Economy'),(5,'17C','Premium Economy'),(5,'17D','Premium Economy'),(5,'17E','Premium Economy'),(5,'17F','Premium Economy'),

-- Economy Class (Rows 20-55, 6 seats per row + partial = 218 seats)
(5,'20A','Economy'),(5,'20B','Economy'),(5,'20C','Economy'),(5,'20D','Economy'),(5,'20E','Economy'),(5,'20F','Economy'),
(5,'21A','Economy'),(5,'21B','Economy'),(5,'21C','Economy'),(5,'21D','Economy'),(5,'21E','Economy'),(5,'21F','Economy'),
(5,'22A','Economy'),(5,'22B','Economy'),(5,'22C','Economy'),(5,'22D','Economy'),(5,'22E','Economy'),(5,'22F','Economy'),
(5,'23A','Economy'),(5,'23B','Economy'),(5,'23C','Economy'),(5,'23D','Economy'),(5,'23E','Economy'),(5,'23F','Economy'),
(5,'24A','Economy'),(5,'24B','Economy'),(5,'24C','Economy'),(5,'24D','Economy'),(5,'24E','Economy'),(5,'24F','Economy'),
(5,'25A','Economy'),(5,'25B','Economy'),(5,'25C','Economy'),(5,'25D','Economy'),(5,'25E','Economy'),(5,'25F','Economy'),
(5,'26A','Economy'),(5,'26B','Economy'),(5,'26C','Economy'),(5,'26D','Economy'),(5,'26E','Economy'),(5,'26F','Economy'),
(5,'27A','Economy'),(5,'27B','Economy'),(5,'27C','Economy'),(5,'27D','Economy'),(5,'27E','Economy'),(5,'27F','Economy'),
(5,'28A','Economy'),(5,'28B','Economy'),(5,'28C','Economy'),(5,'28D','Economy'),(5,'28E','Economy'),(5,'28F','Economy'),
(5,'29A','Economy'),(5,'29B','Economy'),(5,'29C','Economy'),(5,'29D','Economy'),(5,'29E','Economy'),(5,'29F','Economy'),
(5,'30A','Economy'),(5,'30B','Economy'),(5,'30C','Economy'),(5,'30D','Economy'),(5,'30E','Economy'),(5,'30F','Economy'),
(5,'31A','Economy'),(5,'31B','Economy'),(5,'31C','Economy'),(5,'31D','Economy'),(5,'31E','Economy'),(5,'31F','Economy'),
(5,'32A','Economy'),(5,'32B','Economy'),(5,'32C','Economy'),(5,'32D','Economy'),(5,'32E','Economy'),(5,'32F','Economy'),
(5,'33A','Economy'),(5,'33B','Economy'),(5,'33C','Economy'),(5,'33D','Economy'),(5,'33E','Economy'),(5,'33F','Economy'),
(5,'34A','Economy'),(5,'34B','Economy'),(5,'34C','Economy'),(5,'34D','Economy'),(5,'34E','Economy'),(5,'34F','Economy'),
(5,'35A','Economy'),(5,'35B','Economy'),(5,'35C','Economy'),(5,'35D','Economy'),(5,'35E','Economy'),(5,'35F','Economy'),
(5,'36A','Economy'),(5,'36B','Economy'),(5,'36C','Economy'),(5,'36D','Economy'),(5,'36E','Economy'),(5,'36F','Economy'),
(5,'37A','Economy'),(5,'37B','Economy'),(5,'37C','Economy'),(5,'37D','Economy'),(5,'37E','Economy'),(5,'37F','Economy'),
(5,'38A','Economy'),(5,'38B','Economy'),(5,'38C','Economy'),(5,'38D','Economy'),(5,'38E','Economy'),(5,'38F','Economy'),
(5,'39A','Economy'),(5,'39B','Economy'),(5,'39C','Economy'),(5,'39D','Economy'),(5,'39E','Economy'),(5,'39F','Economy'),
(5,'40A','Economy'),(5,'40B','Economy'),(5,'40C','Economy'),(5,'40D','Economy'),(5,'40E','Economy'),(5,'40F','Economy'),
(5,'41A','Economy'),(5,'41B','Economy'),(5,'41C','Economy'),(5,'41D','Economy'),(5,'41E','Economy'),(5,'41F','Economy'),
(5,'42A','Economy'),(5,'42B','Economy'),(5,'42C','Economy'),(5,'42D','Economy'),(5,'42E','Economy'),(5,'42F','Economy'),
(5,'43A','Economy'),(5,'43B','Economy'),(5,'43C','Economy'),(5,'43D','Economy'),(5,'43E','Economy'),(5,'43F','Economy'),
(5,'44A','Economy'),(5,'44B','Economy'),(5,'44C','Economy'),(5,'44D','Economy'),(5,'44E','Economy'),(5,'44F','Economy'),
(5,'45A','Economy'),(5,'45B','Economy'),(5,'45C','Economy'),(5,'45D','Economy'),(5,'45E','Economy'),(5,'45F','Economy'),
(5,'46A','Economy'),(5,'46B','Economy'),(5,'46C','Economy'),(5,'46D','Economy'),(5,'46E','Economy'),(5,'46F','Economy'),
(5,'47A','Economy'),(5,'47B','Economy'),(5,'47C','Economy'),(5,'47D','Economy'),(5,'47E','Economy'),(5,'47F','Economy'),
(5,'48A','Economy'),(5,'48B','Economy'),(5,'48C','Economy'),(5,'48D','Economy'),(5,'48E','Economy'),(5,'48F','Economy'),
(5,'49A','Economy'),(5,'49B','Economy'),(5,'49C','Economy'),(5,'49D','Economy'),(5,'49E','Economy'),(5,'49F','Economy'),
(5,'50A','Economy'),(5,'50B','Economy'),(5,'50C','Economy'),(5,'50D','Economy'),(5,'50E','Economy'),(5,'50F','Economy'),
(5,'51A','Economy'),(5,'51B','Economy'),(5,'51C','Economy'),(5,'51D','Economy'),(5,'51E','Economy'),(5,'51F','Economy'),
(5,'52A','Economy'),(5,'52B','Economy'),(5,'52C','Economy'),(5,'52D','Economy'),(5,'52E','Economy'),(5,'52F','Economy'),
(5,'53A','Economy'),(5,'53B','Economy'),(5,'53C','Economy'),(5,'53D','Economy'),(5,'53E','Economy'),(5,'53F','Economy'),
(5,'54A','Economy'),(5,'54B','Economy'),(5,'54C','Economy'),(5,'54D','Economy'),(5,'54E','Economy'),(5,'54F','Economy'),
(5,'55A','Economy'),(5,'55B','Economy'),(5,'55C','Economy'),(5,'55D','Economy'),(5,'55E','Economy'),(5,'55F','Economy'),
(5,'56A','Economy'),(5,'56B','Economy'),(5,'56C','Economy'),(5,'56D','Economy'),
(5,'57A','Economy'),(5,'57B','Economy'),(5,'57C','Economy'),(5,'57D','Economy');

-- =====================================================
-- SEATS - AIRCRAFT 6 (Airbus A350-900 - 325 seats)
-- Business: 48, Premium Economy: 45, Economy: 232
-- =====================================================

INSERT INTO Seat (AircraftID, Seat_Number, Seat_Class) VALUES
-- Business Class (Rows 1-8, 6 seats per row = 48 seats)
(6,'1A','Business'),(6,'1C','Business'),(6,'1D','Business'),(6,'1G','Business'),(6,'1H','Business'),(6,'1K','Business'),
(6,'2A','Business'),(6,'2C','Business'),(6,'2D','Business'),(6,'2G','Business'),(6,'2H','Business'),(6,'2K','Business'),
(6,'3A','Business'),(6,'3C','Business'),(6,'3D','Business'),(6,'3G','Business'),(6,'3H','Business'),(6,'3K','Business'),
(6,'4A','Business'),(6,'4C','Business'),(6,'4D','Business'),(6,'4G','Business'),(6,'4H','Business'),(6,'4K','Business'),
(6,'5A','Business'),(6,'5C','Business'),(6,'5D','Business'),(6,'5G','Business'),(6,'5H','Business'),(6,'5K','Business'),
(6,'6A','Business'),(6,'6C','Business'),(6,'6D','Business'),(6,'6G','Business'),(6,'6H','Business'),(6,'6K','Business'),
(6,'7A','Business'),(6,'7C','Business'),(6,'7D','Business'),(6,'7G','Business'),(6,'7H','Business'),(6,'7K','Business'),
(6,'8A','Business'),(6,'8C','Business'),(6,'8D','Business'),(6,'8G','Business'),(6,'8H','Business'),(6,'8K','Business'),

-- Premium Economy (Rows 10-16, 6-7 seats per row = 45 seats)
(6,'10A','Premium Economy'),(6,'10B','Premium Economy'),(6,'10C','Premium Economy'),(6,'10D','Premium Economy'),(6,'10E','Premium Economy'),(6,'10F','Premium Economy'),(6,'10G','Premium Economy'),
(6,'11A','Premium Economy'),(6,'11B','Premium Economy'),(6,'11C','Premium Economy'),(6,'11D','Premium Economy'),(6,'11E','Premium Economy'),(6,'11F','Premium Economy'),(6,'11G','Premium Economy'),
(6,'12A','Premium Economy'),(6,'12B','Premium Economy'),(6,'12C','Premium Economy'),(6,'12D','Premium Economy'),(6,'12E','Premium Economy'),(6,'12F','Premium Economy'),
(6,'13A','Premium Economy'),(6,'13B','Premium Economy'),(6,'13C','Premium Economy'),(6,'13D','Premium Economy'),(6,'13E','Premium Economy'),(6,'13F','Premium Economy'),
(6,'14A','Premium Economy'),(6,'14B','Premium Economy'),(6,'14C','Premium Economy'),(6,'14D','Premium Economy'),(6,'14E','Premium Economy'),(6,'14F','Premium Economy'),
(6,'15A','Premium Economy'),(6,'15B','Premium Economy'),(6,'15C','Premium Economy'),(6,'15D','Premium Economy'),(6,'15E','Premium Economy'),(6,'15F','Premium Economy'),
(6,'16A','Premium Economy'),(6,'16B','Premium Economy'),(6,'16C','Premium Economy'),(6,'16D','Premium Economy'),(6,'16E','Premium Economy'),(6,'16F','Premium Economy'),(6,'16G','Premium Economy'),

-- Economy Class (Rows 18-56, 6 seats per row = 232 seats)
(6,'18A','Economy'),(6,'18B','Economy'),(6,'18C','Economy'),(6,'18D','Economy'),(6,'18E','Economy'),(6,'18F','Economy'),
(6,'19A','Economy'),(6,'19B','Economy'),(6,'19C','Economy'),(6,'19D','Economy'),(6,'19E','Economy'),(6,'19F','Economy'),
(6,'20A','Economy'),(6,'20B','Economy'),(6,'20C','Economy'),(6,'20D','Economy'),(6,'20E','Economy'),(6,'20F','Economy'),
(6,'21A','Economy'),(6,'21B','Economy'),(6,'21C','Economy'),(6,'21D','Economy'),(6,'21E','Economy'),(6,'21F','Economy'),
(6,'22A','Economy'),(6,'22B','Economy'),(6,'22C','Economy'),(6,'22D','Economy'),(6,'22E','Economy'),(6,'22F','Economy'),
(6,'23A','Economy'),(6,'23B','Economy'),(6,'23C','Economy'),(6,'23D','Economy'),(6,'23E','Economy'),(6,'23F','Economy'),
(6,'24A','Economy'),(6,'24B','Economy'),(6,'24C','Economy'),(6,'24D','Economy'),(6,'24E','Economy'),(6,'24F','Economy'),
(6,'25A','Economy'),(6,'25B','Economy'),(6,'25C','Economy'),(6,'25D','Economy'),(6,'25E','Economy'),(6,'25F','Economy'),
(6,'26A','Economy'),(6,'26B','Economy'),(6,'26C','Economy'),(6,'26D','Economy'),(6,'26E','Economy'),(6,'26F','Economy'),
(6,'27A','Economy'),(6,'27B','Economy'),(6,'27C','Economy'),(6,'27D','Economy'),(6,'27E','Economy'),(6,'27F','Economy'),
(6,'28A','Economy'),(6,'28B','Economy'),(6,'28C','Economy'),(6,'28D','Economy'),(6,'28E','Economy'),(6,'28F','Economy'),
(6,'29A','Economy'),(6,'29B','Economy'),(6,'29C','Economy'),(6,'29D','Economy'),(6,'29E','Economy'),(6,'29F','Economy'),
(6,'30A','Economy'),(6,'30B','Economy'),(6,'30C','Economy'),(6,'30D','Economy'),(6,'30E','Economy'),(6,'30F','Economy'),
(6,'31A','Economy'),(6,'31B','Economy'),(6,'31C','Economy'),(6,'31D','Economy'),(6,'31E','Economy'),(6,'31F','Economy'),
(6,'32A','Economy'),(6,'32B','Economy'),(6,'32C','Economy'),(6,'32D','Economy'),(6,'32E','Economy'),(6,'32F','Economy'),
(6,'33A','Economy'),(6,'33B','Economy'),(6,'33C','Economy'),(6,'33D','Economy'),(6,'33E','Economy'),(6,'33F','Economy'),
(6,'34A','Economy'),(6,'34B','Economy'),(6,'34C','Economy'),(6,'34D','Economy'),(6,'34E','Economy'),(6,'34F','Economy'),
(6,'35A','Economy'),(6,'35B','Economy'),(6,'35C','Economy'),(6,'35D','Economy'),(6,'35E','Economy'),(6,'35F','Economy'),
(6,'36A','Economy'),(6,'36B','Economy'),(6,'36C','Economy'),(6,'36D','Economy'),(6,'36E','Economy'),(6,'36F','Economy'),
(6,'37A','Economy'),(6,'37B','Economy'),(6,'37C','Economy'),(6,'37D','Economy'),(6,'37E','Economy'),(6,'37F','Economy'),
(6,'38A','Economy'),(6,'38B','Economy'),(6,'38C','Economy'),(6,'38D','Economy'),(6,'38E','Economy'),(6,'38F','Economy'),
(6,'39A','Economy'),(6,'39B','Economy'),(6,'39C','Economy'),(6,'39D','Economy'),(6,'39E','Economy'),(6,'39F','Economy'),
(6,'40A','Economy'),(6,'40B','Economy'),(6,'40C','Economy'),(6,'40D','Economy'),(6,'40E','Economy'),(6,'40F','Economy'),
(6,'41A','Economy'),(6,'41B','Economy'),(6,'41C','Economy'),(6,'41D','Economy'),(6,'41E','Economy'),(6,'41F','Economy'),
(6,'42A','Economy'),(6,'42B','Economy'),(6,'42C','Economy'),(6,'42D','Economy'),(6,'42E','Economy'),(6,'42F','Economy'),
(6,'43A','Economy'),(6,'43B','Economy'),(6,'43C','Economy'),(6,'43D','Economy'),(6,'43E','Economy'),(6,'43F','Economy'),
(6,'44A','Economy'),(6,'44B','Economy'),(6,'44C','Economy'),(6,'44D','Economy'),(6,'44E','Economy'),(6,'44F','Economy'),
(6,'45A','Economy'),(6,'45B','Economy'),(6,'45C','Economy'),(6,'45D','Economy'),(6,'45E','Economy'),(6,'45F','Economy'),
(6,'46A','Economy'),(6,'46B','Economy'),(6,'46C','Economy'),(6,'46D','Economy'),(6,'46E','Economy'),(6,'46F','Economy'),
(6,'47A','Economy'),(6,'47B','Economy'),(6,'47C','Economy'),(6,'47D','Economy'),(6,'47E','Economy'),(6,'47F','Economy'),
(6,'48A','Economy'),(6,'48B','Economy'),(6,'48C','Economy'),(6,'48D','Economy'),(6,'48E','Economy'),(6,'48F','Economy'),
(6,'49A','Economy'),(6,'49B','Economy'),(6,'49C','Economy'),(6,'49D','Economy'),(6,'49E','Economy'),(6,'49F','Economy'),
(6,'50A','Economy'),(6,'50B','Economy'),(6,'50C','Economy'),(6,'50D','Economy'),(6,'50E','Economy'),(6,'50F','Economy'),
(6,'51A','Economy'),(6,'51B','Economy'),(6,'51C','Economy'),(6,'51D','Economy'),(6,'51E','Economy'),(6,'51F','Economy'),
(6,'52A','Economy'),(6,'52B','Economy'),(6,'52C','Economy'),(6,'52D','Economy'),(6,'52E','Economy'),(6,'52F','Economy'),
(6,'53A','Economy'),(6,'53B','Economy'),(6,'53C','Economy'),(6,'53D','Economy'),(6,'53E','Economy'),(6,'53F','Economy'),
(6,'54A','Economy'),(6,'54B','Economy'),(6,'54C','Economy'),(6,'54D','Economy'),(6,'54E','Economy'),(6,'54F','Economy'),
(6,'55A','Economy'),(6,'55B','Economy'),(6,'55C','Economy'),(6,'55D','Economy'),(6,'55E','Economy'),(6,'55F','Economy'),
(6,'56A','Economy'),(6,'56B','Economy'),(6,'56C','Economy'),(6,'56D','Economy');

-- =====================================================
-- SEATS - AIRCRAFT 7 (Boeing 737 MAX 8 - 178 seats)
-- Business: 42 seats (Rows 1-7), Economy: 136 seats (Rows 8-30)
-- =====================================================

INSERT INTO Seat (AircraftID, Seat_Number, Seat_Class) VALUES
-- Business Class (Rows 1-7, 6 seats per row = 42 seats)
(7,'1A','Business'),(7,'1B','Business'),(7,'1C','Business'),(7,'1D','Business'),(7,'1E','Business'),(7,'1F','Business'),
(7,'2A','Business'),(7,'2B','Business'),(7,'2C','Business'),(7,'2D','Business'),(7,'2E','Business'),(7,'2F','Business'),
(7,'3A','Business'),(7,'3B','Business'),(7,'3C','Business'),(7,'3D','Business'),(7,'3E','Business'),(7,'3F','Business'),
(7,'4A','Business'),(7,'4B','Business'),(7,'4C','Business'),(7,'4D','Business'),(7,'4E','Business'),(7,'4F','Business'),
(7,'5A','Business'),(7,'5B','Business'),(7,'5C','Business'),(7,'5D','Business'),(7,'5E','Business'),(7,'5F','Business'),
(7,'6A','Business'),(7,'6B','Business'),(7,'6C','Business'),(7,'6D','Business'),(7,'6E','Business'),(7,'6F','Business'),
(7,'7A','Business'),(7,'7B','Business'),(7,'7C','Business'),(7,'7D','Business'),(7,'7E','Business'),(7,'7F','Business'),

-- Economy Class (Rows 8-30, mostly 6 seats per row = 136 seats)
(7,'8A','Economy'),(7,'8B','Economy'),(7,'8C','Economy'),(7,'8D','Economy'),(7,'8E','Economy'),(7,'8F','Economy'),
(7,'9A','Economy'),(7,'9B','Economy'),(7,'9C','Economy'),(7,'9D','Economy'),(7,'9E','Economy'),(7,'9F','Economy'),
(7,'10A','Economy'),(7,'10B','Economy'),(7,'10C','Economy'),(7,'10D','Economy'),(7,'10E','Economy'),(7,'10F','Economy'),
(7,'11A','Economy'),(7,'11B','Economy'),(7,'11C','Economy'),(7,'11D','Economy'),(7,'11E','Economy'),(7,'11F','Economy'),
(7,'12A','Economy'),(7,'12B','Economy'),(7,'12C','Economy'),(7,'12D','Economy'),(7,'12E','Economy'),(7,'12F','Economy'),
(7,'13A','Economy'),(7,'13B','Economy'),(7,'13C','Economy'),(7,'13D','Economy'),(7,'13E','Economy'),(7,'13F','Economy'),
(7,'14A','Economy'),(7,'14B','Economy'),(7,'14C','Economy'),(7,'14D','Economy'),(7,'14E','Economy'),(7,'14F','Economy'),
(7,'15A','Economy'),(7,'15B','Economy'),(7,'15C','Economy'),(7,'15D','Economy'),(7,'15E','Economy'),(7,'15F','Economy'),
(7,'16A','Economy'),(7,'16B','Economy'),(7,'16C','Economy'),(7,'16D','Economy'),(7,'16E','Economy'),(7,'16F','Economy'),
(7,'17A','Economy'),(7,'17B','Economy'),(7,'17C','Economy'),(7,'17D','Economy'),(7,'17E','Economy'),(7,'17F','Economy'),
(7,'18A','Economy'),(7,'18B','Economy'),(7,'18C','Economy'),(7,'18D','Economy'),(7,'18E','Economy'),(7,'18F','Economy'),
(7,'19A','Economy'),(7,'19B','Economy'),(7,'19C','Economy'),(7,'19D','Economy'),(7,'19E','Economy'),(7,'19F','Economy'),
(7,'20A','Economy'),(7,'20B','Economy'),(7,'20C','Economy'),(7,'20D','Economy'),(7,'20E','Economy'),(7,'20F','Economy'),
(7,'21A','Economy'),(7,'21B','Economy'),(7,'21C','Economy'),(7,'21D','Economy'),(7,'21E','Economy'),(7,'21F','Economy'),
(7,'22A','Economy'),(7,'22B','Economy'),(7,'22C','Economy'),(7,'22D','Economy'),(7,'22E','Economy'),(7,'22F','Economy'),
(7,'23A','Economy'),(7,'23B','Economy'),(7,'23C','Economy'),(7,'23D','Economy'),(7,'23E','Economy'),(7,'23F','Economy'),
(7,'24A','Economy'),(7,'24B','Economy'),(7,'24C','Economy'),(7,'24D','Economy'),(7,'24E','Economy'),(7,'24F','Economy'),
(7,'25A','Economy'),(7,'25B','Economy'),(7,'25C','Economy'),(7,'25D','Economy'),(7,'25E','Economy'),(7,'25F','Economy'),
(7,'26A','Economy'),(7,'26B','Economy'),(7,'26C','Economy'),(7,'26D','Economy'),(7,'26E','Economy'),(7,'26F','Economy'),
(7,'27A','Economy'),(7,'27B','Economy'),(7,'27C','Economy'),(7,'27D','Economy'),(7,'27E','Economy'),(7,'27F','Economy'),
(7,'28A','Economy'),(7,'28B','Economy'),(7,'28C','Economy'),(7,'28D','Economy'),(7,'28E','Economy'),(7,'28F','Economy'),
(7,'29A','Economy'),(7,'29B','Economy'),(7,'29C','Economy'),(7,'29D','Economy'),(7,'29E','Economy'),(7,'29F','Economy'),
(7,'30A','Economy'),(7,'30B','Economy');

-- =====================================================
-- SEATS - AIRCRAFT 8 (Embraer E195-E2 - 132 seats)
-- Business: 12 seats (Rows 1-2), Economy: 120 seats (Rows 5-34)
-- =====================================================

INSERT INTO Seat (AircraftID, Seat_Number, Seat_Class) VALUES
-- Business Class (Rows 1-2, 6 seats per row = 12 seats)
(8,'1A','Business'),(8,'1B','Business'),(8,'1C','Business'),(8,'1D','Business'),(8,'1E','Business'),(8,'1F','Business'),
(8,'2A','Business'),(8,'2B','Business'),(8,'2C','Business'),(8,'2D','Business'),(8,'2E','Business'),(8,'2F','Business'),

-- Economy Class (Rows 5-34, 4 seats per row = 120 seats)
(8,'5A','Economy'),(8,'5B','Economy'),(8,'5C','Economy'),(8,'5D','Economy'),
(8,'6A','Economy'),(8,'6B','Economy'),(8,'6C','Economy'),(8,'6D','Economy'),
(8,'7A','Economy'),(8,'7B','Economy'),(8,'7C','Economy'),(8,'7D','Economy'),
(8,'8A','Economy'),(8,'8B','Economy'),(8,'8C','Economy'),(8,'8D','Economy'),
(8,'9A','Economy'),(8,'9B','Economy'),(8,'9C','Economy'),(8,'9D','Economy'),
(8,'10A','Economy'),(8,'10B','Economy'),(8,'10C','Economy'),(8,'10D','Economy'),
(8,'11A','Economy'),(8,'11B','Economy'),(8,'11C','Economy'),(8,'11D','Economy'),
(8,'12A','Economy'),(8,'12B','Economy'),(8,'12C','Economy'),(8,'12D','Economy'),
(8,'13A','Economy'),(8,'13B','Economy'),(8,'13C','Economy'),(8,'13D','Economy'),
(8,'14A','Economy'),(8,'14B','Economy'),(8,'14C','Economy'),(8,'14D','Economy'),
(8,'15A','Economy'),(8,'15B','Economy'),(8,'15C','Economy'),(8,'15D','Economy'),
(8,'16A','Economy'),(8,'16B','Economy'),(8,'16C','Economy'),(8,'16D','Economy'),
(8,'17A','Economy'),(8,'17B','Economy'),(8,'17C','Economy'),(8,'17D','Economy'),
(8,'18A','Economy'),(8,'18B','Economy'),(8,'18C','Economy'),(8,'18D','Economy'),
(8,'19A','Economy'),(8,'19B','Economy'),(8,'19C','Economy'),(8,'19D','Economy'),
(8,'20A','Economy'),(8,'20B','Economy'),(8,'20C','Economy'),(8,'20D','Economy'),
(8,'21A','Economy'),(8,'21B','Economy'),(8,'21C','Economy'),(8,'21D','Economy'),
(8,'22A','Economy'),(8,'22B','Economy'),(8,'22C','Economy'),(8,'22D','Economy'),
(8,'23A','Economy'),(8,'23B','Economy'),(8,'23C','Economy'),(8,'23D','Economy'),
(8,'24A','Economy'),(8,'24B','Economy'),(8,'24C','Economy'),(8,'24D','Economy'),
(8,'25A','Economy'),(8,'25B','Economy'),(8,'25C','Economy'),(8,'25D','Economy'),
(8,'26A','Economy'),(8,'26B','Economy'),(8,'26C','Economy'),(8,'26D','Economy'),
(8,'27A','Economy'),(8,'27B','Economy'),(8,'27C','Economy'),(8,'27D','Economy'),
(8,'28A','Economy'),(8,'28B','Economy'),(8,'28C','Economy'),(8,'28D','Economy'),
(8,'29A','Economy'),(8,'29B','Economy'),(8,'29C','Economy'),(8,'29D','Economy'),
(8,'30A','Economy'),(8,'30B','Economy'),(8,'30C','Economy'),(8,'30D','Economy'),
(8,'31A','Economy'),(8,'31B','Economy'),(8,'31C','Economy'),(8,'31D','Economy'),
(8,'32A','Economy'),(8,'32B','Economy'),(8,'32C','Economy'),(8,'32D','Economy'),
(8,'33A','Economy'),(8,'33B','Economy'),(8,'33C','Economy'),(8,'33D','Economy'),
(8,'34A','Economy'),(8,'34B','Economy'),(8,'34C','Economy'),(8,'34D','Economy');

-- Verify the seats were created successfully
SELECT 
    f.FlightID,
    f.Flight_Number,
    DATE_FORMAT(f.Flight_Date, '%Y-%m-%d') AS Flight_Date,
    orig.City AS Origin,
    dest.City AS Destination,
    a.Model AS Aircraft,
    COUNT(fs.FlightSeatID) AS Total_Seats,
    SUM(CASE WHEN fs.Is_Booked = 0 THEN 1 ELSE 0 END) AS Available_Seats,
    SUM(CASE WHEN fs.Is_Booked = 1 THEN 1 ELSE 0 END) AS Booked_Seats
FROM Flight f
JOIN Route r ON f.RouteID = r.RouteID
JOIN Airport orig ON r.Origin_AirportID = orig.AirportID
JOIN Airport dest ON r.Destination_AirportID = dest.AirportID
JOIN Aircraft a ON f.AircraftID = a.AircraftID
LEFT JOIN Flight_Seat fs ON f.FlightID = fs.FlightID
GROUP BY f.FlightID, f.Flight_Number, f.Flight_Date, orig.City, dest.City, a.Model
ORDER BY f.FlightID;

-- Flights
INSERT INTO Flight (Flight_Number, RouteID, AircraftID, Departure_Time, Arrival_Time, Flight_Date, FlightStatusID, Gate_Number) VALUES
('MS100', 1, 1, '2025-12-26 08:00:00', '2025-12-26 10:15:00', '2025-12-26', 1, 'A12'),
('MS200', 2, 2, '2025-12-27 14:00:00', '2025-12-27 17:30:00', '2025-12-27', 1, 'B5'),
('MS300', 3, 3, '2025-12-28 10:00:00', '2025-12-28 15:00:00', '2025-12-28', 1, 'C8'),
('MS400', 4, 3, '2025-12-28 20:00:00', '2025-12-29 07:00:00', '2025-12-29', 1, 'D3'),
('MS150', 5, 5, '2025-12-30 07:00:00', '2025-12-30 07:45:00', '2025-12-30', 1, 'A5'),
('MS151', 6, 6, '2025-12-31 18:00:00', '2025-12-31 18:45:00', '2025-12-31', 1, 'A6'),
('MS503', 7, 7, '2026-01-01 08:00:00', '2026-01-01 10:15:00', '2026-01-01', 1, 'D4'),
('MS451', 8, 4, '2026-01-02 19:00:00', '2026-01-02 23:30:00', '2026-01-02', 1, 'B11'), -- Paris to Cairo 
('MS550', 9, 7, '2026-01-03 10:00:00', '2026-01-03 18:00:00', '2026-01-03', 1, 'D13'), -- London to New York 
('MS551', 10, 6, '2026-01-03 21:00:00', '2025-01-04 05:00:00', '2026-01-04', 1, 'E14'), -- New York to London 
('MS350', 11, 1, '2026-01-05 10:00:00', '2026-01-05 12:00:00', '2026-01-05', 1, 'D7'),  -- Jeddah to Dubai 
('MS351', 12, 1, '2026-01-06 16:00:00', '2026-01-06 18:00:00', '2026-01-06', 1, 'E9');  -- Dubai to Jeddah 



-- Create indexes
CREATE INDEX idx_user_email ON `User`(Email);
CREATE INDEX idx_passenger_email ON Passenger(Email);
CREATE INDEX idx_flight_date ON Flight(Flight_Date);
CREATE INDEX idx_booking_passenger ON Booking(PassengerID);

ALTER TABLE User ADD COLUMN Date_of_Birth DATE NULL;

-- Create seats for all flights that don't have them yet
-- MS100: Alexandria to Jeddah (FlightID 1, AircraftID 1)
INSERT IGNORE INTO Flight_Seat (FlightID, SeatID, Is_Booked)
SELECT 1, SeatID, 0 FROM Seat WHERE AircraftID = 1;

-- MS200: Cairo to Dubai (FlightID 2, AircraftID 2)  
INSERT IGNORE INTO Flight_Seat (FlightID, SeatID, Is_Booked)
SELECT 2, SeatID, 0 FROM Seat WHERE AircraftID = 2;

-- MS300: Cairo to London (FlightID 3, AircraftID 3)
INSERT IGNORE INTO Flight_Seat (FlightID, SeatID, Is_Booked)
SELECT 3, SeatID, 0 FROM Seat WHERE AircraftID = 3;

-- MS400: Cairo to New York (FlightID 4, AircraftID 3)
INSERT IGNORE INTO Flight_Seat (FlightID, SeatID, Is_Booked)
SELECT 4, SeatID, 0 FROM Seat WHERE AircraftID = 3;

INSERT IGNORE INTO Flight_Seat (FlightID, SeatID, Is_Booked)
SELECT 5, SeatID, 0 FROM Seat WHERE AircraftID = 5;

-- MS151: Alexandria to Cairo (FlightID 6, AircraftID 6)
INSERT IGNORE INTO Flight_Seat (FlightID, SeatID, Is_Booked)
SELECT 6, SeatID, 0 FROM Seat WHERE AircraftID = 6;

INSERT IGNORE INTO Flight_Seat (FlightID, SeatID, Is_Booked)
SELECT 7, SeatID, 0 FROM Seat WHERE AircraftID = 7;

INSERT IGNORE INTO Flight_Seat (FlightID, SeatID, Is_Booked)
SELECT 8, SeatID, 0 FROM Seat WHERE AircraftID = 4;

INSERT IGNORE INTO Flight_Seat (FlightID, SeatID, Is_Booked)
SELECT 9, SeatID, 0 FROM Seat WHERE AircraftID = 7;

INSERT IGNORE INTO Flight_Seat (FlightID, SeatID, Is_Booked)
SELECT 10, SeatID, 0 FROM Seat WHERE AircraftID = 6;

INSERT IGNORE INTO Flight_Seat (FlightID, SeatID, Is_Booked)
SELECT 11, SeatID, 0 FROM Seat WHERE AircraftID = 1;

INSERT IGNORE INTO Flight_Seat (FlightID, SeatID, Is_Booked)
SELECT 12, SeatID, 0 FROM Seat WHERE AircraftID = 1;

-- Verify it worked
SELECT 
    f.Flight_Number,
    orig.City || ' â†’ ' || dest.City AS Route,
    COUNT(fs.FlightSeatID) AS Seats_Created
FROM Flight f
JOIN Route r ON f.RouteID = r.RouteID
JOIN Airport orig ON r.Origin_AirportID = orig.AirportID
JOIN Airport dest ON r.Destination_AirportID = dest.AirportID
LEFT JOIN Flight_Seat fs ON f.FlightID = fs.FlightID
GROUP BY f.Flight_Number, orig.City, dest.City;

-- Show everything about flights
SELECT 
    f.FlightID,
    f.Flight_Number,
    f.Flight_Date,
    f.AircraftID,
    orig.IATA_Code AS Origin,
    dest.IATA_Code AS Destination,
    fs_count.total_seats,
    fs_count.available_seats
FROM Flight f
JOIN Route r ON f.RouteID = r.RouteID
JOIN Airport orig ON r.Origin_AirportID = orig.AirportID
JOIN Airport dest ON r.Destination_AirportID = dest.AirportID
LEFT JOIN (
    SELECT 
        FlightID,
        COUNT(*) AS total_seats,
        SUM(CASE WHEN Is_Booked = 0 THEN 1 ELSE 0 END) AS available_seats
    FROM Flight_Seat
    GROUP BY FlightID
) fs_count ON f.FlightID = fs_count.FlightID;

SELECT 
    f.Flight_Number,
    orig.City AS Origin,
    dest.City AS Destination,
    f.Flight_Date,
    fs.Status_Name
FROM Flight f
INNER JOIN Route r ON f.RouteID = r.RouteID
INNER JOIN Airport orig ON r.Origin_AirportID = orig.AirportID
INNER JOIN Airport dest ON r.Destination_AirportID = dest.AirportID
INNER JOIN Flight_Status fs ON f.FlightStatusID = fs.FlightStatusID;	