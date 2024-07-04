
CREATE TABLE Merchants (
    MerchantID INT PRIMARY KEY IDENTITY(1,1),
    [Name] NVARCHAR(100) NOT NULL,
    ContactNumber NVARCHAR(255),
    EmailAddress NVARCHAR(255),
    CreateDate DATETIME DEFAULT GETDATE()
);
CREATE TABLE Address (
    AddressID INT PRIMARY KEY IDENTITY,
    Address1 NVARCHAR(100),
    Address2 NVARCHAR(100),
    City NVARCHAR(50),
    [State] NVARCHAR(50)
)

CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY IDENTITY,
    FirstName NVARCHAR(100) NOT NULL,
    LastName NVARCHAR(100) NOT NULL,
    ContactNumber NVARCHAR(255),
    EmailAddress NVARCHAR(255),
    AddressID INT FOREIGN KEY REFERENCES Address(AddressID),
    CreatedDate DATETIME DEFAULT GETDATE()
)

CREATE TABLE Transactions (
    TransactionID INT PRIMARY KEY IDENTITY(1,1),
    MerchantID INT NOT NULL,
    CustomerID INT NOT NULL,
    Amount DECIMAL(18, 2) NOT NULL,
    [Date] DATETIME DEFAULT GETDATE(),
    [Note] NVARCHAR(255),
    DateFrom DATETIME2 GENERATED ALWAYS AS ROW START HIDDEN NOT NULL DEFAULT SYSUTCDATETIME(),
    DateTo DATETIME2 GENERATED ALWAYS AS ROW END HIDDEN NOT NULL DEFAULT CONVERT(DATETIME2, '9999-12-31 23:59:59.9999999'),
    PERIOD FOR SYSTEM_TIME (DateFrom, DateTo)
) 
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.TransactionsHistory));

-- I utilized temporal tables to be able to retrieve transaction records given a date range.
-- This will allow us to track valid transactions at different points in time 
CREATE PROCEDURE GetTransactionByDateRange
    @StartDate DATETIME,
    @EndDate DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        tr.TransactionID,
        tr.Amount,
        tr.Date AS TransactionDate,
        tr.Note,
        me.Name AS MerchantName,
        cu.FirstName + ' ' + cu.LastName AS CustomerName,
        cu.EmailAddress AS CustomerEmail,
        ad.Address1 AS CustomerAddress1,
        ad.Address2 AS CustomerAddress2,
        ad.City AS CustomerCity,
        ad.State AS CustomerState
    FROM
        Transactions FOR SYSTEM_TIME BETWEEN @StartDate AND @EndDate AS tr
        INNER JOIN Merchants me ON tr.MerchantID = me.MerchantID
        INNER JOIN Customers cu ON tr.CustomerID = cu.CustomerID
        INNER JOIN Address ad ON cu.AddressID = ad.AddressID
    WHERE
        tr.Date BETWEEN @StartDate AND @EndDate;
END


-- Insert scripts
INSERT INTO Merchants ([Name], ContactNumber, EmailAddress)
VALUES 
('Merchant A', '123-456-7890', 'merchantA@example.com'),
('Merchant B', '234-567-8901', 'merchantB@example.com'),
('Merchant C', '345-678-9012', 'merchantC@example.com');

INSERT INTO Address (Address1, Address2, City, [State])
VALUES 
('123 Main St', 'Apt 1', 'Anytown', 'CA'),
('456 Elm St', NULL, 'Othertown', 'TX'),
('789 Maple St', 'Suite 5', 'Sometown', 'NY');

INSERT INTO Customers (FirstName, LastName, ContactNumber, EmailAddress, AddressID)
VALUES 
('John', 'Doe', '555-1234', 'john.doe@example.com', 1),
('Jane', 'Smith', '555-5678', 'jane.smith@example.com', 2),
('Jim', 'Brown', '555-8765', 'jim.brown@example.com', 3);


--Run these transaction inserts on different time, to test GetTransactionByDateRange Stored Procedure
INSERT INTO Transactions (MerchantID, CustomerID, Amount, [Note]) VALUES (1, 1, 100.00, 'Payment for services')

INSERT INTO Transactions (MerchantID, CustomerID, Amount, [Note]) VALUES (2, 2, 200.50, 'Invoice payment')

INSERT INTO Transactions (MerchantID, CustomerID, Amount, [Note]) VALUES (3, 3, 150.75, 'Purchase of goods')


--Test the stored procedure
DECLARE 
--Put the daterange of the transaction records you want to retrieve
@dateFrom DATETIME = '2024-07-04 07:11:53.393', 
@dateTo DATETIME = GETDATE(); 

--This will retrieve transaction records from 2024-07-04 07:11:53.393 to present
EXEC GetTransactionByDateRange @dateFrom, @dateTo

