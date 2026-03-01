/* =========================================================
   1. PERSON (MAIN TABLE)
   ========================================================= */
CREATE TABLE dbo.Person
(
    PersonId INT IDENTITY(1,1) PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    MiddleName VARCHAR(50) NULL,
    LastName VARCHAR(50) NOT NULL,
    Nationality VARCHAR(50) NOT NULL,
    UserPersonId INT NOT NULL,
    InsertDate SMALLDATETIME NOT NULL DEFAULT GETDATE()
);
GO

/* =========================================================
   2. PERSON SUB-TABLES (1:1)
   ========================================================= */
CREATE TABLE dbo.Customer
(
    PersonId INT PRIMARY KEY,
    UserPersonId INT NOT NULL,
    InsertDate SMALLDATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Customer_Person
        FOREIGN KEY (PersonId) REFERENCES dbo.Person(PersonId)
);
GO

CREATE TABLE dbo.Employee
(
    PersonId INT PRIMARY KEY,
    JobTitle VARCHAR(50) NOT NULL,
    HireDate DATE NOT NULL,
    UserPersonId INT NOT NULL,
    InsertDate SMALLDATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Employee_Person
        FOREIGN KEY (PersonId) REFERENCES dbo.Person(PersonId)
);
GO

/* =========================================================
   3. DROPDOWN MASTER TABLES
   ========================================================= */
CREATE TABLE dbo.ListItemCategory
(
    ListItemCategoryId INT IDENTITY(1,1) PRIMARY KEY,
    CategoryDescription VARCHAR(100) NOT NULL UNIQUE,
    UserPersonId INT NOT NULL,
    InsertDate SMALLDATETIME NOT NULL DEFAULT GETDATE()
);a
GO

CREATE TABLE dbo.ListItem
(
    ListItemId INT IDENTITY(1,1) PRIMARY KEY,
    ListItemDescription VARCHAR(100) NOT NULL,
    ListItemCategoryId INT NOT NULL,
    UserPersonId INT NOT NULL,
    InsertDate SMALLDATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_ListItem_Category
        FOREIGN KEY (ListItemCategoryId)
        REFERENCES dbo.ListItemCategory(ListItemCategoryId)
);
GO

/* =========================================================
   4. ADDRESS & CONTACT
   ========================================================= */
CREATE TABLE dbo.Address
(
    AddressId INT IDENTITY(1,1) PRIMARY KEY,
    AddressLine VARCHAR(250) NOT NULL,
    City VARCHAR(50) NOT NULL,
    Country VARCHAR(50) NOT NULL,
    ZipCode VARCHAR(25) NOT NULL,
    UserPersonId INT NOT NULL,
    InsertDate SMALLDATETIME NOT NULL DEFAULT GETDATE()
);
GO

CREATE TABLE dbo.Contact
(
    ContactId INT IDENTITY(1,1) PRIMARY KEY,
    ContactValue VARCHAR(100) NOT NULL UNIQUE,
    ContactTypeId INT NOT NULL,
    UserPersonId INT NOT NULL,
    InsertDate SMALLDATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Contact_Type
        FOREIGN KEY (ContactTypeId)
        REFERENCES dbo.ListItem(ListItemId)
);
GO

/* =========================================================
   5. BRIDGE TABLES
   ========================================================= */
CREATE TABLE dbo.PersonAddress
(
    PersonAddressId INT IDENTITY(1,1) PRIMARY KEY,
    PersonId INT NOT NULL,
    AddressId INT NOT NULL,
    AddressTypeId INT NOT NULL,
    UserPersonId INT NOT NULL,
    InsertDate SMALLDATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_PersonAddress_Person
        FOREIGN KEY (PersonId) REFERENCES dbo.Person(PersonId),

    CONSTRAINT FK_PersonAddress_Address
        FOREIGN KEY (AddressId) REFERENCES dbo.Address(AddressId),

    CONSTRAINT FK_PersonAddress_Type
        FOREIGN KEY (AddressTypeId) REFERENCES dbo.ListItem(ListItemId),

    CONSTRAINT UQ_PersonAddress UNIQUE (PersonId, AddressId)
);
GO

CREATE TABLE dbo.PersonContact
(
    PersonContactId INT IDENTITY(1,1) PRIMARY KEY,
    PersonId INT NOT NULL,
    ContactId INT NOT NULL,
    IsPrimary BIT NOT NULL DEFAULT 0,
    UserPersonId INT NOT NULL,
    InsertDate SMALLDATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_PersonContact_Person
        FOREIGN KEY (PersonId) REFERENCES dbo.Person(PersonId),

    CONSTRAINT FK_PersonContact_Contact
        FOREIGN KEY (ContactId) REFERENCES dbo.Contact(ContactId),

    CONSTRAINT UQ_PersonContact UNIQUE (PersonId, ContactId)
);
GO

/* =========================================================
   6. ROOM
   ========================================================= */
CREATE TABLE dbo.Room
(
    RoomId INT IDENTITY(1,1) PRIMARY KEY,
    RoomTypeId INT NOT NULL,
    RoomStatusId INT NOT NULL,
    RoomNumber VARCHAR(25) NOT NULL,
    UserPersonId INT NOT NULL,
    InsertDate SMALLDATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_Room_Type
        FOREIGN KEY (RoomTypeId) REFERENCES dbo.ListItem(ListItemId),

    CONSTRAINT FK_Room_Status
        FOREIGN KEY (RoomStatusId) REFERENCES dbo.ListItem(ListItemId)
);
GO

/* =========================================================
   7. RESERVATION
   ========================================================= */
CREATE TABLE dbo.Reservation
(
    ReservationId INT IDENTITY(1,1) PRIMARY KEY,
    RoomId INT NOT NULL,
    CustomerPersonId INT NOT NULL,
    UserPersonId INT NOT NULL,
    CheckInDate DATE NOT NULL,
    CheckOutDate DATE NOT NULL,
    InsertDate SMALLDATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_Reservation_Room
        FOREIGN KEY (RoomId) REFERENCES dbo.Room(RoomId),

    CONSTRAINT FK_Reservation_Customer
        FOREIGN KEY (CustomerPersonId) REFERENCES dbo.Customer(PersonId),

    CONSTRAINT FK_Reservation_Employee
        FOREIGN KEY (UserPersonId) REFERENCES dbo.Employee(PersonId),

    CONSTRAINT CK_Reservation_Dates
        CHECK (CheckOutDate > CheckInDate)
);
GO

/* =========================================================
   8. PAYMENT & REVIEW
   ========================================================= */
CREATE TABLE dbo.Payment
(
    PaymentId INT IDENTITY(1,1) PRIMARY KEY,
    ReservationId INT NOT NULL,
    Amount MONEY NOT NULL,
    PaymentMethodId INT NOT NULL,
    UserPersonId INT NOT NULL,
    InsertDate SMALLDATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_Payment_Reservation
        FOREIGN KEY (ReservationId) REFERENCES dbo.Reservation(ReservationId),

    CONSTRAINT FK_Payment_Method
        FOREIGN KEY (PaymentMethodId) REFERENCES dbo.ListItem(ListItemId)
);
GO

CREATE TABLE dbo.Review
(
    ReviewId INT IDENTITY(1,1) PRIMARY KEY,
    ReservationId INT NOT NULL,
    RatingId INT NOT NULL,
    Comment VARCHAR(500) NULL,
    UserPersonId INT NOT NULL,
    InsertDate SMALLDATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_Review_Reservation
        FOREIGN KEY (ReservationId) REFERENCES dbo.Reservation(ReservationId),

    CONSTRAINT FK_Review_Rating
        FOREIGN KEY (RatingId) REFERENCES dbo.ListItem(ListItemId)
);
GO

-------             
-------             
-------
-------
-------
-------
DECLARE @PersonName NVARCHAR(100) = 'Gita';
DECLARE @PersonLastName NVARCHAR(100) = 'Koirala';

SELECT
JSON_QUERY(
(
    SELECT
        CONCAT(p.FirstName, ' ', p.LastName) AS PersonName,
        'Guest' AS Title,

        -- Contacts
        (
            SELECT
                CASE c.ContactTypeId
                    WHEN 1 THEN 'Mobile'
                    WHEN 2 THEN 'Email'
                    ELSE 'Other'
                END AS ContactType,
                c.ContactValue
            FROM dbo.PersonContact pc
            JOIN dbo.Contact c ON pc.ContactId = c.ContactId
            WHERE pc.PersonId = p.PersonId
            FOR JSON PATH
        ) AS Contacts,

        -- Addresses
        (
            SELECT
                a.AddressLine AS Street,
                a.City,
                a.Country AS State,
                pa.AddressTypeId
            FROM dbo.PersonAddress pa
            JOIN dbo.Address a ON pa.AddressId = a.AddressId
            WHERE pa.PersonId = p.PersonId
            FOR JSON PATH
        ) AS Addresses

    FROM dbo.Person p
    WHERE p.FirstName = @PersonName AND p.LastName = @PersonLastName
    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
))
AS Person;
GO





SELECT
JSON_QUERY(
(
    SELECT
        JSON_QUERY(
            (SELECT CONCAT(p.FirstName, ' ', p.LastName) AS PersonName,
                    'Guest' AS Title
             FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
        ) AS Person,

        JSON_QUERY(
            (SELECT pay.PaymentMode,
                    pay.Amount,
                    pay.CardLast4
             FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
        ) AS Payment
    FROM dbo.Person p
    JOIN dbo.Payment pay ON p.PersonId = pay.PersonId
    FOR JSON PATH
))
AS FinalJson;





DECLARE @PersonId INT = 1;  -- example PersonId

SELECT
JSON_QUERY(
(
    SELECT
        -- Person object
        JSON_QUERY(
            (SELECT CONCAT(p.FirstName, ' ', p.LastName) AS PersonName,
                    'Guest' AS Title
             FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
        ) AS Person,

        -- Reservation object
        JSON_QUERY(
            (SELECT r.CheckIn, r.CheckOut,
                    (
                        SELECT rr.RoomTypeId, rr.Rate
                        FROM dbo.ReservationRoom rr
                        WHERE rr.ReservationId = r.ReservationId
                        FOR JSON PATH
                    ) AS Rooms
             FROM dbo.Reservation r
             WHERE r.PersonId = @PersonId
             FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
        ) AS Reservation

    FROM dbo.Person p
    WHERE p.PersonId = @PersonId
    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
))
AS FinalJson;








/* =========================================================
   COMPLETE DATABASE SETUP SCRIPT
   1. Seed Lookup Data
   2. Stored Procedures
   3. Test Execution
   ========================================================= */

-- =========================================================
-- PART 1: SEED LOOKUP DATA (MUST RUN FIRST!)
-- =========================================================

PRINT '========================================';
PRINT 'STEP 1: Seeding Lookup Data...';
PRINT '========================================';

-- Clear existing data if any
DELETE FROM dbo.ListItem;
DELETE FROM dbo.ListItemCategory;

-- Reset identity seeds
DBCC CHECKIDENT ('dbo.ListItem', RESEED, 0);
DBCC CHECKIDENT ('dbo.ListItemCategory', RESEED, 0);

-- Insert ListItemCategory records
SET IDENTITY_INSERT dbo.ListItemCategory ON;

INSERT INTO dbo.ListItemCategory (ListItemCategoryId, CategoryDescription, UserPersonId, InsertDate)
VALUES 
    (1, 'Contact Type', 1, GETDATE()),
    (2, 'Address Type', 1, GETDATE()),
    (3, 'Room Type', 1, GETDATE()),
    (4, 'Room Status', 1, GETDATE()),
    (5, 'Payment Method', 1, GETDATE()),
    (6, 'Rating', 1, GETDATE());

SET IDENTITY_INSERT dbo.ListItemCategory OFF;

-- Insert ListItem records
SET IDENTITY_INSERT dbo.ListItem ON;

-- Contact Types (CategoryId = 1)
INSERT INTO dbo.ListItem (ListItemId, ListItemDescription, ListItemCategoryId, UserPersonId, InsertDate)
VALUES 
    (1, 'Mobile', 1, 1, GETDATE()),
    (2, 'Email', 1, 1, GETDATE()),
    (3, 'Phone', 1, 1, GETDATE()),
    (4, 'Fax', 1, 1, GETDATE());

-- Address Types (CategoryId = 2)
INSERT INTO dbo.ListItem (ListItemId, ListItemDescription, ListItemCategoryId, UserPersonId, InsertDate)
VALUES 
    (5, 'Home', 2, 1, GETDATE()),
    (6, 'Office', 2, 1, GETDATE()),
    (7, 'Billing', 2, 1, GETDATE()),
    (8, 'Shipping', 2, 1, GETDATE());

-- Room Types (CategoryId = 3)
INSERT INTO dbo.ListItem (ListItemId, ListItemDescription, ListItemCategoryId, UserPersonId, InsertDate)
VALUES 
    (9, 'Single', 3, 1, GETDATE()),
    (10, 'Double', 3, 1, GETDATE()),
    (11, 'Suite', 3, 1, GETDATE()),
    (12, 'Deluxe', 3, 1, GETDATE());

-- Room Status (CategoryId = 4)
INSERT INTO dbo.ListItem (ListItemId, ListItemDescription, ListItemCategoryId, UserPersonId, InsertDate)
VALUES 
    (13, 'Available', 4, 1, GETDATE()),
    (14, 'Occupied', 4, 1, GETDATE()),
    (15, 'Maintenance', 4, 1, GETDATE()),
    (16, 'Reserved', 4, 1, GETDATE());

-- Payment Methods (CategoryId = 5)
INSERT INTO dbo.ListItem (ListItemId, ListItemDescription, ListItemCategoryId, UserPersonId, InsertDate)
VALUES 
    (17, 'Cash', 5, 1, GETDATE()),
    (18, 'Credit Card', 5, 1, GETDATE()),
    (19, 'Debit Card', 5, 1, GETDATE()),
    (20, 'Online Transfer', 5, 1, GETDATE());

-- Ratings (CategoryId = 6)
INSERT INTO dbo.ListItem (ListItemId, ListItemDescription, ListItemCategoryId, UserPersonId, InsertDate)
VALUES 
    (21, '1 Star', 6, 1, GETDATE()),
    (22, '2 Stars', 6, 1, GETDATE()),
    (23, '3 Stars', 6, 1, GETDATE()),
    (24, '4 Stars', 6, 1, GETDATE()),
    (25, '5 Stars', 6, 1, GETDATE());

SET IDENTITY_INSERT dbo.ListItem OFF;

PRINT '✓ Lookup data seeded successfully!';
GO












-- =========================================================
-- PART 2: STORED PROCEDURES
-- =========================================================



-- SP 1: Insert Person
CREATE OR ALTER PROCEDURE dbo.SpPersonIns
(
    @InputJson  NVARCHAR(MAX),
    @OutputJson NVARCHAR(MAX) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
 
    IF OBJECT_ID('tempdb..#TempPerson') IS NOT NULL DROP TABLE #TempPerson;
 
    CREATE TABLE #TempPerson
    (
        TempKey INT IDENTITY(1,1) PRIMARY KEY,
        PersonId INT NULL,
        FirstName VARCHAR(50),
        MiddleName VARCHAR(50),
        LastName VARCHAR(50),
        Nationality VARCHAR(50),
        UserPersonId INT,
        AddressLine VARCHAR(250),
        City VARCHAR(50),
        Country VARCHAR(50),
        ZipCode VARCHAR(25),
        ContactValue VARCHAR(100),
        ContactTypeId INT
    );
 
    INSERT INTO #TempPerson (FirstName, MiddleName, LastName, Nationality, UserPersonId, 
                              AddressLine, City, Country, ZipCode, ContactValue, ContactTypeId)
    SELECT
        FirstName, MiddleName, LastName, Nationality, UserPersonId,
        AddressLine, City, Country, ZipCode, ContactValue, ContactTypeId
    FROM OPENJSON(@InputJson)
    WITH
    (
        FirstName VARCHAR(50),
        MiddleName VARCHAR(50),
        LastName VARCHAR(50),
        Nationality VARCHAR(50),
        UserPersonId INT,
        AddressLine VARCHAR(250),
        City VARCHAR(50),
        Country VARCHAR(50),
        ZipCode VARCHAR(25),
        ContactValue VARCHAR(100),
        ContactTypeId INT
    );
 
    DECLARE @InsertedPersons TABLE (TempKey INT, PersonId INT);
    
    INSERT INTO dbo.Person (FirstName, MiddleName, LastName, Nationality, UserPersonId)
    OUTPUT inserted.PersonId
    INTO @InsertedPersons(PersonId)
    SELECT FirstName, MiddleName, LastName, Nationality, UserPersonId
    FROM #TempPerson
    ORDER BY TempKey;
    
    UPDATE t
    SET t.PersonId = i.PersonId
    FROM #TempPerson t
    JOIN (
        SELECT PersonId, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowNum
        FROM @InsertedPersons
    ) i ON t.TempKey = i.RowNum;
 
    SELECT @OutputJson = (
        SELECT
            TempKey, PersonId, FirstName, MiddleName, LastName, Nationality, UserPersonId,
            AddressLine, City, Country, ZipCode, ContactValue, ContactTypeId
        FROM #TempPerson
        FOR JSON PATH
    );
END;
GO



-- SP 2: Insert Address
CREATE OR ALTER PROCEDURE dbo.SpAddressIns
(
    @InputJson  NVARCHAR(MAX),
    @OutputJson NVARCHAR(MAX) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
 
    IF OBJECT_ID('tempdb..#TempAddress') IS NOT NULL DROP TABLE #TempAddress;
 
    CREATE TABLE #TempAddress
    (
        TempKey INT PRIMARY KEY,
        PersonId INT,
        AddressId INT NULL,
        AddressLine VARCHAR(250),
        City VARCHAR(50),
        Country VARCHAR(50),
        ZipCode VARCHAR(25),
        UserPersonId INT,
        FirstName VARCHAR(50),
        MiddleName VARCHAR(50),
        LastName VARCHAR(50),
        Nationality VARCHAR(50),
        ContactValue VARCHAR(100),
        ContactTypeId INT
    );
 
    INSERT INTO #TempAddress (TempKey, PersonId, AddressLine, City, Country, ZipCode, UserPersonId,
                               FirstName, MiddleName, LastName, Nationality, ContactValue, ContactTypeId)
    SELECT
        TempKey, PersonId, AddressLine, City, Country, ZipCode, UserPersonId,
        FirstName, MiddleName, LastName, Nationality, ContactValue, ContactTypeId
    FROM OPENJSON(@InputJson)
    WITH
    (
        TempKey INT, PersonId INT, AddressLine VARCHAR(250), City VARCHAR(50),
        Country VARCHAR(50), ZipCode VARCHAR(25), UserPersonId INT,
        FirstName VARCHAR(50), MiddleName VARCHAR(50), LastName VARCHAR(50),
        Nationality VARCHAR(50), ContactValue VARCHAR(100), ContactTypeId INT
    );
 
    DECLARE @InsertedAddresses TABLE (TempKey INT, AddressId INT);
    
    INSERT INTO dbo.Address (AddressLine, City, Country, ZipCode, UserPersonId)
    OUTPUT inserted.AddressId
    INTO @InsertedAddresses(AddressId)
    SELECT AddressLine, City, Country, ZipCode, UserPersonId
    FROM #TempAddress
    ORDER BY TempKey;
    
    UPDATE t
    SET t.AddressId = i.AddressId
    FROM #TempAddress t
    JOIN (
        SELECT AddressId, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowNum
        FROM @InsertedAddresses
    ) i ON t.TempKey = i.RowNum;
 
    SELECT @OutputJson = (
        SELECT
            TempKey, PersonId, AddressId, FirstName, MiddleName, LastName, Nationality, UserPersonId,
            AddressLine, City, Country, ZipCode, ContactValue, ContactTypeId
        FROM #TempAddress
        FOR JSON PATH
    );
END;
GO



-- SP 3: Insert Contact
CREATE OR ALTER PROCEDURE dbo.SpContactIns
(
    @InputJson  NVARCHAR(MAX),
    @OutputJson NVARCHAR(MAX) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
 
    IF OBJECT_ID('tempdb..#TempContact') IS NOT NULL DROP TABLE #TempContact;
 
    CREATE TABLE #TempContact
    (
        TempKey INT PRIMARY KEY,
        PersonId INT,
        AddressId INT,
        ContactId INT NULL,
        ContactValue VARCHAR(100),
        ContactTypeId INT,
        UserPersonId INT,
        FirstName VARCHAR(50),
        MiddleName VARCHAR(50),
        LastName VARCHAR(50),
        Nationality VARCHAR(50),
        AddressLine VARCHAR(250),
        City VARCHAR(50),
        Country VARCHAR(50),
        ZipCode VARCHAR(25)
    );
 
    INSERT INTO #TempContact (TempKey, PersonId, AddressId, ContactValue, ContactTypeId, UserPersonId,
                               FirstName, MiddleName, LastName, Nationality, 
                               AddressLine, City, Country, ZipCode)
    SELECT
        TempKey, PersonId, AddressId, ContactValue, ContactTypeId, UserPersonId,
        FirstName, MiddleName, LastName, Nationality,
        AddressLine, City, Country, ZipCode
    FROM OPENJSON(@InputJson)
    WITH
    (
        TempKey INT, PersonId INT, AddressId INT, ContactValue VARCHAR(100),
        ContactTypeId INT, UserPersonId INT, FirstName VARCHAR(50), MiddleName VARCHAR(50),
        LastName VARCHAR(50), Nationality VARCHAR(50), AddressLine VARCHAR(250),
        City VARCHAR(50), Country VARCHAR(50), ZipCode VARCHAR(25)
    );
 
    DECLARE @InsertedContacts TABLE (TempKey INT, ContactId INT, ContactValue VARCHAR(100));
    
    INSERT INTO dbo.Contact (ContactValue, ContactTypeId, UserPersonId)
    OUTPUT inserted.ContactId, inserted.ContactValue
    INTO @InsertedContacts(ContactId, ContactValue)
    SELECT tc.ContactValue, tc.ContactTypeId, tc.UserPersonId
    FROM #TempContact tc
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.Contact c WHERE c.ContactValue = tc.ContactValue
    );
    
    UPDATE tc
    SET tc.ContactId = c.ContactId
    FROM #TempContact tc
    JOIN dbo.Contact c ON c.ContactValue = tc.ContactValue
    WHERE tc.ContactId IS NULL;
 
    SELECT @OutputJson = (
        SELECT
            TempKey, PersonId, AddressId, ContactId, FirstName, MiddleName, LastName,
            Nationality, UserPersonId, AddressLine, City, Country, ZipCode,
            ContactValue, ContactTypeId
        FROM #TempContact
        FOR JSON PATH
    );
END;
GO



-- SP 4: Insert Bridge Tables
CREATE OR ALTER PROCEDURE dbo.SpPersonBridgeIns
(
    @InputJson  NVARCHAR(MAX),
    @OutputJson NVARCHAR(MAX) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    IF OBJECT_ID('tempdb..#TempBridge') IS NOT NULL DROP TABLE #TempBridge;

    CREATE TABLE #TempBridge
    (
        TempKey INT PRIMARY KEY,
        PersonId INT,
        AddressId INT,
        ContactId INT,
        UserPersonId INT,
        AddressTypeId INT DEFAULT 5, -- Default to 'Home' (ListItemId = 5)
        IsPrimary BIT DEFAULT 1
    );

    INSERT INTO #TempBridge (TempKey, PersonId, AddressId, ContactId, UserPersonId)
    SELECT TempKey, PersonId, AddressId, ContactId, UserPersonId
    FROM OPENJSON(@InputJson)
    WITH (TempKey INT, PersonId INT, AddressId INT, ContactId INT, UserPersonId INT);

    INSERT INTO dbo.PersonAddress (PersonId, AddressId, AddressTypeId, UserPersonId)
    SELECT PersonId, AddressId, AddressTypeId, UserPersonId
    FROM #TempBridge
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.PersonAddress pa 
        WHERE pa.PersonId = #TempBridge.PersonId 
          AND pa.AddressId = #TempBridge.AddressId
    );

    INSERT INTO dbo.PersonContact (PersonId, ContactId, IsPrimary, UserPersonId)
    SELECT PersonId, ContactId, IsPrimary, UserPersonId
    FROM #TempBridge
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.PersonContact pc 
        WHERE pc.PersonId = #TempBridge.PersonId 
          AND pc.ContactId = #TempBridge.ContactId
    );

    SET @OutputJson = @InputJson;
END;
GO



-- SP 5: Master Orchestration
CREATE OR ALTER PROCEDURE dbo.SpPersonNewTsk
(
    @InputJson NVARCHAR(MAX),
    @FinalJson NVARCHAR(MAX) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRAN;

        DECLARE @EnrichedJson NVARCHAR(MAX);

        EXEC dbo.SpPersonIns @InputJson, @EnrichedJson OUTPUT;
        EXEC dbo.SpAddressIns @EnrichedJson, @EnrichedJson OUTPUT;
        EXEC dbo.SpContactIns @EnrichedJson, @EnrichedJson OUTPUT;
        EXEC dbo.SpPersonBridgeIns @EnrichedJson, @EnrichedJson OUTPUT;

        SET @FinalJson = (
            SELECT
                p.PersonId,
                p.FirstName,
                p.MiddleName,
                p.LastName,
                p.Nationality,
                (
                    SELECT
                        a.AddressId,
                        a.AddressLine,
                        a.City,
                        a.Country,
                        a.ZipCode
                    FROM dbo.Address a
                    JOIN dbo.PersonAddress pa ON a.AddressId = pa.AddressId
                    WHERE pa.PersonId = p.PersonId
                    FOR JSON PATH
                ) AS Addresses,
                (
                    SELECT
                        c.ContactId,
                        c.ContactValue,
                        c.ContactTypeId
                    FROM dbo.Contact c
                    JOIN dbo.PersonContact pc ON c.ContactId = pc.ContactId
                    WHERE pc.PersonId = p.PersonId
                    FOR JSON PATH
                ) AS Contacts
            FROM dbo.Person p
            WHERE p.PersonId IN (
                SELECT PersonId FROM OPENJSON(@EnrichedJson) 
                WITH (PersonId INT)
            )
            FOR JSON PATH
        );

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO



-- =========================================================
-- PART 3: TEST EXECUTION
-- =========================================================


DECLARE @InputJson NVARCHAR(MAX) = N'
[
  {
    "FirstName": "Biraj",
    "MiddleName": "Kumar",
    "LastName": "Thapa",
    "Nationality": "Nepalese",
    "UserPersonId": 1,
    "AddressLine": "Biratnagar",
    "City": "Kathmandu",
    "Country": "Nepal",
    "ZipCode": "44600",
    "ContactValue": "1234567890",
    "ContactTypeId": 1
  }
]';
 
DECLARE @FinalJson NVARCHAR(MAX);
 
EXEC dbo.SpPersonNewTsk
     @InputJson = @InputJson,
     @FinalJson = @FinalJson OUTPUT;
 
SELECT @FinalJson AS FinalResultJson;

-- Verify inserts
PRINT '';
PRINT 'Record Counts:';
SELECT 'Persons' AS TableName, COUNT(*) AS RecordCount FROM dbo.Person
UNION ALL
SELECT 'Addresses', COUNT(*) FROM dbo.Address
UNION ALL
SELECT 'Contacts', COUNT(*) FROM dbo.Contact
UNION ALL
SELECT 'PersonAddress', COUNT(*) FROM dbo.PersonAddress
UNION ALL
SELECT 'PersonContact', COUNT(*) FROM dbo.PersonContact;



SELECT TOP 5 * FROM dbo.Person ORDER BY PersonId DESC;
SELECT TOP 5 * FROM dbo.Address ORDER BY AddressId DESC;
SELECT TOP 5 * FROM dbo.Contact ORDER BY ContactId DESC;
SELECT TOP 5 * FROM dbo.PersonContact ORDER BY ContactId DESC;
SELECT TOP 5 * FROM dbo.PersonAddress ORDER BY PersonAddressId DESC;
SELECT * from [dbo].[ListItemCategory]
SELECT * from [dbo].[ListItem];
GO




-- Test Execution
--------------------------------------------------
DECLARE @InputJson NVARCHAR(MAX) = N'
[
  {
    "FirstName": "Sita",
    "MiddleName": "Kumari",
    "LastName": "Shrestha",
    "Nationality": "Nepalese",
    "UserPersonId": 1,
    "AddressLine": "Baneshwor",
    "City": "Kathmandu",
    "Country": "Nepal",
    "ZipCode": "44600",
    "ContactValue": "9841234567",
    "ContactTypeId": 1
  },
  {
    "FirstName": "Ram",
    "MiddleName": null,
    "LastName": "Thapa",
    "Nationality": "Nepalese",
    "UserPersonId": 1,
    "AddressLine": "Patan",
    "City": "Lalitpur",
    "Country": "Nepal",
    "ZipCode": "44700",
    "ContactValue": "ram.thapa@gmail.com",
    "ContactTypeId": 2
  },
  {
    "FirstName": "Gita",
    "MiddleName": "Devi",
    "LastName": "Koirala",
    "Nationality": "Nepalese",
    "UserPersonId": 1,
    "AddressLine": "Biratnagar Road",
    "City": "Biratnagar",
    "Country": "Nepal",
    "ZipCode": "56613",
    "ContactValue": "9812345678",
    "ContactTypeId": 1
  },
  {
    "FirstName": "Hari",
    "MiddleName": null,
    "LastName": "Adhikari",
    "Nationality": "Nepalese",
    "UserPersonId": 1,
    "AddressLine": "Mahendrapool",
    "City": "Pokhara",
    "Country": "Nepal",
    "ZipCode": "33700",
    "ContactValue": "hari.adhikari@yahoo.com",
    "ContactTypeId": 2
  },
  {
    "FirstName": "Nirmala",
    "MiddleName": "Maya",
    "LastName": "Basnet",
    "Nationality": "Nepalese",
    "UserPersonId": 1,
    "AddressLine": "Tinkune",
    "City": "Kathmandu",
    "Country": "Nepal",
    "ZipCode": "44600",
    "ContactValue": "9801122334",
    "ContactTypeId": 1
  }
]';
 
DECLARE @FinalJson NVARCHAR(MAX);
 
EXEC dbo.SpPersonNewTsk
     @InputJson = @InputJson,
     @FinalJson = @FinalJson OUTPUT;
 
SELECT @FinalJson AS FinalResultJson;
GO

--
--
-- --a.
-- {
-- "Person": {
--   "PersonName": "Ramesh",
--   "Title": "Guest",
--   "Contacts": [
--      { "ContactType": "Mobile", "ContactValue": "9800000001" },
--      { "ContactType": "Email", "ContactValue": "ramesh@test.com" }
--   ],
--   "Addresses": [
--      { "Street": "Kalanki", "City": "Kathmandu", "State": "Bagmati", "AddressTypeId": 1 },
--      { "Street": "Lakeside", "City": "Pokhara", "State": "Gandaki", "AddressTypeId": 2 }
--   ]
-- },
-- "Reservation": {
--   "BranchId": 1,
--   "CheckIn": "2026-07-01",
--   "CheckOut": "2026-07-05"
-- }
-- }

DECLARE @PersonName NVARCHAR(100) = 'Gita';
DECLARE @PersonLastName NVARCHAR(100) = 'Koirala';

SELECT
    JSON_QUERY(
        (
            SELECT
                -- Person info
                JSON_QUERY(
                    (
                        SELECT
                            CONCAT(p.FirstName, ' ', p.LastName) AS PersonName,
                            'Guest' AS Title,

                            -- Contacts
                            JSON_QUERY(
                                (
                                    SELECT
                                        li.ListItemDescription AS ContactType,
                                        c.ContactValue
                                    FROM dbo.PersonContact pc
                                    JOIN dbo.Contact c ON pc.ContactId = c.ContactId
                                    JOIN dbo.ListItem li ON c.ContactTypeId = li.ListItemId
                                    WHERE pc.PersonId = p.PersonId
                                    FOR JSON PATH
                                )
                            ) AS Contacts,

                            -- Addresses
                            JSON_QUERY(
                                (
                                    SELECT
                                        a.AddressLine AS Street,
                                        a.City,
                                        a.Country AS State,
                                        pa.AddressTypeId
                                    FROM dbo.PersonAddress pa
                                    JOIN dbo.Address a ON pa.AddressId = a.AddressId
                                    WHERE pa.PersonId = p.PersonId
                                    FOR JSON PATH
                                )
                            ) AS Addresses

                        FROM dbo.Person p
                        WHERE p.FirstName = @PersonName AND p.LastName = @PersonLastName
                        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                    )
                ) AS Person,

                -- Reservation info (if exists)
                JSON_QUERY(
                    (
                        SELECT TOP 1
                            r.BranchId,
                            CONVERT(VARCHAR(10), r.CheckInDate, 23) AS CheckIn,
                            CONVERT(VARCHAR(10), r.CheckOutDate, 23) AS CheckOut
                        FROM dbo.Reservation r
                        JOIN dbo.Customer c ON r.CustomerPersonId = c.PersonId
                        JOIN dbo.Person p ON c.PersonId = p.PersonId
                        WHERE p.FirstName = @PersonName AND p.LastName = @PersonLastName
                        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                    )
                ) AS Reservation

            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        )
    ) AS Result;
GO



-- {
-- "Person": { "PersonName": "Hari", "Title": "Guest" },
-- "Reservation": {
--   "CheckIn": "2026-08-10",
--   "CheckOut": "2026-08-15",
--   "Rooms": [
--      { "RoomTypeId": 1, "Rate": 2000 },
--      { "RoomTypeId": 3, "Rate": 3500 }
--   ]
-- }
-- }

DECLARE @PersonId INT = 26;  -- Gita Koirala
SELECT
    JSON_QUERY(
        (
            SELECT
                -- Person nested object
                JSON_QUERY(
                    (
                        SELECT 
                            CONCAT(p.FirstName, ' ', p.LastName) AS PersonName,
                            'Guest' AS Title
                        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                    )
                ) AS Person,

                -- Reservation nested object
                JSON_QUERY(
                    (
                        SELECT TOP 1
                            CONVERT(VARCHAR(10), r.CheckInDate, 23) AS CheckIn,
                            CONVERT(VARCHAR(10), r.CheckOutDate, 23) AS CheckOut,
                            JSON_QUERY(
                                (
                                    SELECT 
                                        rr.RoomTypeId, 
                                        rr.Rate
                                    FROM dbo.ReservationRoom rr
                                    WHERE rr.ReservationId = r.ReservationId
                                    FOR JSON PATH
                                )
                            ) AS Rooms
                        FROM dbo.Reservation r
                        WHERE r.CustomerPersonId = @PersonId
                        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                    )
                ) AS Reservation

            FROM dbo.Person p
            WHERE p.PersonId = @PersonId
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        )
    ) AS Result;
GO



-- b. 
-- -- Example B: Person-Payment pairs (simplified for existing data)
-- -- This will work once you add Payment records

-- [
-- {
--   "Person": { "PersonName": "Sita", "Title": "Guest" },
--   "Payment": { "PaymentMode": "Card", "Amount": 5000, "CardLast4": "1234" }
-- },
-- {
--   "Person": { "PersonName": "Gita", "Title": "Guest" },
--   "Payment": { "PaymentMode": "Cash", "Amount": 3000 }
-- }
-- ]



SELECT
    JSON_QUERY(
        (
            SELECT 
                p.FirstName AS PersonName,
                'Guest' AS Title
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        )
    ) AS Person,
    JSON_QUERY(
        (
            SELECT 
                'Not Available' AS PaymentMode,
                0 AS Amount,
                NULL AS CardLast4
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        )
    ) AS Payment
FROM dbo.Person p
WHERE p.PersonId IN (24, 26)  -- Sita and Gita
FOR JSON PATH;
GO




-- 2. Create a stored procedure with input parameter Entity and Entity Id which gives information based on entity passed.
-- For example: When entity person is passed, Sp should return all information(name,usertype,address,contact) of person.
-- Note: Entities can be Person and hotel/organization.

-- Return the result in simple json format [No Nested Json]
-- {
--               “key”:value
-- }



CREATE OR ALTER PROCEDURE dbo.SpGetEntityInfo
(
    @Entity NVARCHAR(50),           -- 'Person' or 'Organization'
    @EntityId INT,                  -- PersonId or OrganizationId
    @OutputJson NVARCHAR(MAX) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate Entity parameter
    IF @Entity NOT IN ('Person', 'Organization')
    BEGIN
        RAISERROR('Invalid Entity. Must be ''Person'' or ''Organization''.', 16, 1);
        RETURN;
    END

    -- Handle PERSON entity
    IF @Entity = 'Person'
    BEGIN
        -- Check if person exists
        IF NOT EXISTS (SELECT 1 FROM dbo.Person WHERE PersonId = @EntityId)
        BEGIN
            SET @OutputJson = JSON_QUERY('{"Error": "Person not found"}');
            RETURN;
        END

        -- Build flat JSON for Person
        SELECT @OutputJson = (
            SELECT
                @EntityId AS PersonId,
                p.FirstName,
                p.MiddleName,
                p.LastName,
                CONCAT(p.FirstName, ' ', ISNULL(p.MiddleName + ' ', ''), p.LastName) AS FullName,
                p.Nationality,
                
                -- User Type (Customer or Employee)
                CASE 
                    WHEN EXISTS (SELECT 1 FROM dbo.Customer WHERE PersonId = @EntityId) THEN 'Customer'
                    WHEN EXISTS (SELECT 1 FROM dbo.Employee WHERE PersonId = @EntityId) THEN 'Employee'
                    ELSE 'Guest'
                END AS UserType,
                
                -- Employee specific info (if applicable)
                e.JobTitle,
                CONVERT(VARCHAR(10), e.HireDate, 23) AS HireDate,
                
                -- Primary Address
                a.AddressLine,
                a.City,
                a.Country,
                a.ZipCode,
                
                -- Address Type
                (SELECT li.ListItemDescription 
                 FROM dbo.ListItem li 
                 WHERE li.ListItemId = pa.AddressTypeId) AS AddressType,
                
                -- Primary Contact (Mobile)
                (SELECT TOP 1 c.ContactValue 
                 FROM dbo.PersonContact pc 
                 JOIN dbo.Contact c ON pc.ContactId = c.ContactId 
                 JOIN dbo.ListItem li ON c.ContactTypeId = li.ListItemId
                 WHERE pc.PersonId = @EntityId 
                   AND li.ListItemDescription = 'Mobile'
                 ORDER BY pc.IsPrimary DESC) AS MobileNumber,
                
                -- Primary Contact (Email)
                (SELECT TOP 1 c.ContactValue 
                 FROM dbo.PersonContact pc 
                 JOIN dbo.Contact c ON pc.ContactId = c.ContactId 
                 JOIN dbo.ListItem li ON c.ContactTypeId = li.ListItemId
                 WHERE pc.PersonId = @EntityId 
                   AND li.ListItemDescription = 'Email'
                 ORDER BY pc.IsPrimary DESC) AS Email,
                
                -- All Contacts (comma-separated)
                STUFF((
                    SELECT ', ' + c.ContactValue
                    FROM dbo.PersonContact pc
                    JOIN dbo.Contact c ON pc.ContactId = c.ContactId
                    WHERE pc.PersonId = @EntityId
                    FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS AllContacts,
                
                p.InsertDate AS CreatedDate
                
            FROM dbo.Person p
            LEFT JOIN dbo.Employee e ON p.PersonId = e.PersonId
            LEFT JOIN dbo.PersonAddress pa ON p.PersonId = pa.PersonId AND pa.AddressTypeId = 5
            LEFT JOIN dbo.Address a ON pa.AddressId = a.AddressId
            WHERE p.PersonId = @EntityId
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );
    END

    -- Handle ORGANIZATION entity
    ELSE IF @Entity = 'Organization'
    BEGIN
        -- Check if organization exists
        IF NOT EXISTS (SELECT 1 FROM [Org].[Organization] WHERE OrganizationId = @EntityId)
        BEGIN
            SET @OutputJson = JSON_QUERY('{"Error": "Organization not found"}');
            RETURN;
        END

        -- Build flat JSON for Organization
        SELECT @OutputJson = (
            SELECT
                @EntityId AS OrganizationId,
                o.OrganizationName,
                o.DepartmentName,
                
                -- Organization Type
                CASE 
                    WHEN o.ParentOrganizationId IS NULL THEN 'Root Organization'
                    ELSE 'Department'
                END AS OrganizationType,
                
                o.ParentOrganizationId,
                o.RootOrganizationId,
                
                -- Parent Organization Name (if department)
                (SELECT OrganizationName 
                 FROM [Org].[Organization] 
                 WHERE OrganizationId = o.ParentOrganizationId) AS ParentOrganizationName,
                
                -- Primary Address
                a.AddressLine,
                a.City,
                a.AddressType,
                
                -- Primary Contact
                c.ContactValue AS PrimaryContact,
                c.ContactType AS PrimaryContactType,
                
                -- All Contacts (comma-separated)
                STUFF((
                    SELECT ', ' + ct.ContactValue
                    FROM [Org].[OrganizationContact] oc
                    JOIN [Org].[Contact] ct ON oc.ContactId = ct.ContactId
                    WHERE oc.OrganizationId = @EntityId
                    FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS AllContacts,
                
                -- Count of Departments (if root organization)
                (SELECT COUNT(*) 
                 FROM [Org].[Organization] 
                 WHERE ParentOrganizationId = @EntityId) AS DepartmentCount,
                
                o.InsertDate AS CreatedDate
                
            FROM [Org].[Organization] o
            LEFT JOIN [Org].[OrganizationAddress] oa ON o.OrganizationId = oa.OrganizationId AND oa.IsPrimary = 1
            LEFT JOIN [Org].[Address] a ON oa.AddressId = a.AddressId
            LEFT JOIN [Org].[OrganizationContact] oc ON o.OrganizationId = oc.OrganizationId AND oc.IsPrimary = 1
            LEFT JOIN [Org].[Contact] c ON oc.ContactId = c.ContactId
            WHERE o.OrganizationId = @EntityId
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );
    END
END;
GO


-- Test 1: Get Person Information (Gita Koirala - PersonId 26)
DECLARE @Output1 NVARCHAR(MAX);

EXEC dbo.SpGetEntityInfo
    @Entity = 'Person',
    @EntityId = 26,
    @OutputJson = @Output1 OUTPUT;

SELECT 'Person Info (Gita)' AS TestCase, @Output1 AS JsonOutput;
GO

-- Test 2: Get Person Information (Nirmala - PersonId 28)
DECLARE @Output2 NVARCHAR(MAX);

EXEC dbo.SpGetEntityInfo
    @Entity = 'Person',
    @EntityId = 28,
    @OutputJson = @Output2 OUTPUT;

SELECT 'Person Info (Nirmala)' AS TestCase, @Output2 AS JsonOutput;
GO

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------        Jan 26                           -----------------------------------------------------------------------------------------
-----------------------------------------------        Dynamic SQL                           -----------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


SELECT * FROM dbo.Person;
SELECT * FROM dbo.Customer;
SELECT * FROM dbo.Employee;
SELECT * FROM dbo.ListItemCategory;
SELECT * FROM dbo.ListItem;
SELECT * FROM dbo.Address;
SELECT * FROM dbo.Contact;
SELECT * FROM dbo.PersonAddress;
SELECT * FROM dbo.PersonContact;
SELECT * FROM dbo.Room;
SELECT * FROM dbo.Reservation;
SELECT * FROM dbo.Payment;
SELECT * FROM dbo.Review;




INSERT INTO dbo.Room (RoomTypeId, RoomStatusId, RoomNumber, UserPersonId)
VALUES
(11, 13, '101', 1), -- Suite
(12, 13, '102', 1), -- Deluxe
(12, 13, '103', 1); -- Deluxe
INSERT INTO dbo.Room (RoomTypeId, RoomStatusId, RoomNumber, UserPersonId)
VALUES
(11, 13, '104', 1), -- Suite
(12, 13, '105', 1), -- Deluxe
(11, 13, '106', 1); -- Suite


INSERT INTO dbo.Reservation
(
    RoomId,
    CustomerPersonId,
    UserPersonId,
    CheckInDate,
    CheckOutDate
)
VALUES
(
    1,          -- Room 101
    26,         -- Customer
    27,         -- Employee
    '2026-02-10',
    '2026-02-15'
);




