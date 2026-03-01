# Hotel Reservation Database (SQL Server)

This repository contains a SQL Server database script for a **hotel reservation system**. The script creates the database tables, seeds lookup (dropdown) data, provides stored procedures for **JSON-driven inserts**, includes procedures for retrieving entity info as **flat JSON**, and contains test/demo queries and sample inserts.

> **Database platform:** Microsoft SQL Server (uses `OPENJSON` and `FOR JSON PATH`, so SQL Server 2016+ is recommended)

---

## Repository structure

```
hotel-reservation-database/
├── README.md
├── .gitignore
├── sql/
│   └── Hotel_reservation_final_code.sql
└── diagrams/
    └── Hotel_Resevation_dbDiagram.pdf
```

---

## What the SQL script contains

The file `sql/Hotel_reservation_final_code.sql` includes the following major parts:

1. **Schema / Tables**
2. **Lookup (dropdown) seed data**
3. **Stored procedures**
   - JSON input → normalized inserts across tables
   - Entity info output as flat JSON
4. **Test execution blocks**
5. **Sample data inserts (rooms + reservation)**
6. **Example JSON output queries**

---

## 1. Database schema (tables)

### 1.1 Person and subtypes

#### `dbo.Person`
Main table holding generic person details.

- `PersonId` (identity primary key)
- `FirstName`, `MiddleName`, `LastName`
- `Nationality`
- `UserPersonId` (the person/employee who inserted the row; audit-like column)
- `InsertDate` (default `GETDATE()`)

#### `dbo.Customer` (1:1 with Person)
Marks a person as a **customer**.

- `PersonId` (PK, FK → `dbo.Person.PersonId`)
- `UserPersonId`, `InsertDate`

#### `dbo.Employee` (1:1 with Person)
Marks a person as an **employee**.

- `PersonId` (PK, FK → `dbo.Person.PersonId`)
- `JobTitle`, `HireDate`
- `UserPersonId`, `InsertDate`

**Concept:** A row in `dbo.Person` can become a Customer and/or Employee by having a corresponding row in these subtype tables.

---

### 1.2 Lookup (“dropdown”) system

#### `dbo.ListItemCategory`
Defines categories of dropdown values. Examples used in this script:
- Contact Type
- Address Type
- Room Type
- Room Status
- Payment Method
- Rating

#### `dbo.ListItem`
Stores the actual dropdown values and ties them to a category.

Examples:
- Contact Types: Mobile, Email, Phone, Fax
- Address Types: Home, Office, Billing, Shipping
- Room Types: Single, Double, Suite, Deluxe
- Room Status: Available, Occupied, Maintenance, Reserved
- Payment Methods: Cash, Credit Card, Debit Card, Online Transfer
- Rating: 1–5 Stars

---

### 1.3 Address & Contact

#### `dbo.Address`
Stores address records.

- `AddressId` (identity PK)
- `AddressLine`, `City`, `Country`, `ZipCode`
- `UserPersonId`, `InsertDate`

#### `dbo.Contact`
Stores a single contact value (e.g., a phone number or email).

- `ContactId` (identity PK)
- `ContactValue` (UNIQUE)
- `ContactTypeId` (FK → `dbo.ListItem.ListItemId`)
- `UserPersonId`, `InsertDate`

**Important:** Because `ContactValue` is UNIQUE, the same email/phone cannot be inserted twice into `dbo.Contact`. Instead, multiple persons can link to the same contact via the bridge table.

---

### 1.4 Bridge tables (many-to-many relationships)

#### `dbo.PersonAddress`
Links person ↔ address, with an address type.

- `PersonAddressId` (identity PK)
- `PersonId` (FK → `dbo.Person`)
- `AddressId` (FK → `dbo.Address`)
- `AddressTypeId` (FK → `dbo.ListItem`) e.g., Home/Office
- Unique constraint: `(PersonId, AddressId)`

#### `dbo.PersonContact`
Links person ↔ contact, with a “primary” flag.

- `PersonContactId` (identity PK)
- `PersonId` (FK → `dbo.Person`)
- `ContactId` (FK → `dbo.Contact`)
- `IsPrimary` (default 0)
- Unique constraint: `(PersonId, ContactId)`

---

### 1.5 Room, Reservation, Payment, Review

#### `dbo.Room`
- `RoomId` (identity PK)
- `RoomTypeId` (FK → `dbo.ListItem`)
- `RoomStatusId` (FK → `dbo.ListItem`)
- `RoomNumber`
- `UserPersonId`, `InsertDate`

#### `dbo.Reservation`
Represents a reservation for **one room** (as modeled in this script).

- `ReservationId` (identity PK)
- `RoomId` (FK → `dbo.Room`)
- `CustomerPersonId` (FK → `dbo.Customer.PersonId`)
- `UserPersonId` (FK → `dbo.Employee.PersonId`)  
  *(used as “created by / handled by employee” in this design)*
- `CheckInDate`, `CheckOutDate`
- Check constraint: `CheckOutDate > CheckInDate`

#### `dbo.Payment`
- `PaymentId` (identity PK)
- `ReservationId` (FK → `dbo.Reservation`)
- `Amount`
- `PaymentMethodId` (FK → `dbo.ListItem`)
- `UserPersonId`, `InsertDate`

#### `dbo.Review`
- `ReviewId` (identity PK)
- `ReservationId` (FK → `dbo.Reservation`)
- `RatingId` (FK → `dbo.ListItem`)
- `Comment`
- `UserPersonId`, `InsertDate`

---

## 2. Lookup seed data

The script includes a seeding section that:
- Deletes existing lookup rows in `dbo.ListItem` and `dbo.ListItemCategory`
- Resets identity seeds
- Inserts categories and items with **fixed IDs** using `SET IDENTITY_INSERT ON`

These fixed IDs are later assumed by other parts of the script (for example: AddressTypeId defaulting to Home).

---

## 3. JSON-driven insert stored procedure pipeline

A key part of the script is a set of stored procedures designed to accept **JSON input** and insert related data across normalized tables.

### 3.1 Input JSON format

Example input (array of objects):

```json
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
]
```

### 3.2 Stored procedures

#### SP1: `dbo.SpPersonIns`
**Goal:** Insert into `dbo.Person`.

**What it does:**
- Parses the JSON array into a temp table `#TempPerson`
- Inserts rows into `dbo.Person`
- Builds an “enriched” JSON output including a generated `PersonId`

**Output:** JSON array with `PersonId` included.

> Note: The script attempts to map inserted `PersonId`s back to the temp rows using row-number ordering. This may be fragile for multi-row inserts and is something you may want to improve later.

---

#### SP2: `dbo.SpAddressIns`
**Goal:** Insert addresses into `dbo.Address`.

**What it does:**
- Parses enriched JSON into `#TempAddress`
- Inserts into `dbo.Address`
- Adds generated `AddressId` back into the output JSON

---

#### SP3: `dbo.SpContactIns`
**Goal:** Insert contacts into `dbo.Contact`.

**What it does:**
- Parses JSON into `#TempContact`
- Inserts into `dbo.Contact` only if the contact value is not already present
- Resolves `ContactId` by joining on the unique `ContactValue`
- Outputs JSON containing `ContactId`

---

#### SP4: `dbo.SpPersonBridgeIns`
**Goal:** Link person ↔ address and person ↔ contact.

**What it does:**
- Parses JSON into `#TempBridge`
- Inserts rows into:
  - `dbo.PersonAddress` (defaults `AddressTypeId` to `5` → Home)
  - `dbo.PersonContact` (defaults `IsPrimary` to `1`)
- Prevents duplicates using `NOT EXISTS`

---

#### SP5 (Orchestrator): `dbo.SpPersonNewTsk`
**Goal:** One call to insert person + address + contact + bridge relationships.

**What it does:**
- Begins a transaction
- Runs SP1 → SP2 → SP3 → SP4 in order
- Builds a final JSON output for inserted persons including:
  - Person data
  - `Addresses` array (queried via `PersonAddress` + `Address`)
  - `Contacts` array (queried via `PersonContact` + `Contact`)
- Commits transaction on success, rolls back on failure

**Output:** `@FinalJson` containing a JSON array of inserted persons and their associated addresses/contacts.

---

## 4. Entity info procedure (flat JSON)

### `dbo.SpGetEntityInfo`
This procedure is designed to return entity details based on:
- `@Entity` (expected values: `'Person'` or `'Organization'`)
- `@EntityId`

### 4.1 Person output
For `@Entity = 'Person'`, it returns a **flat JSON object** (no nested JSON) including:
- Person fields (names, nationality)
- `UserType` derived from whether the person exists in `dbo.Customer` or `dbo.Employee`
- Employee info (JobTitle, HireDate) if applicable
- Address fields (joins to AddressTypeId=5 “Home”)
- MobileNumber and Email (best-effort, using ListItem descriptions)
- AllContacts as a comma-separated list

### 4.2 Organization output
For `@Entity = 'Organization'`, it queries `[Org].[Organization]` and related tables.

> Note: The script shown in this repository does **not** create the `[Org]` schema/tables. The Organization branch will only work if those tables exist in your database environment.

---

## 5. Test blocks & sample data

The script includes:
- Test execution calls to `dbo.SpPersonNewTsk` with 1 record and with multiple records
- Verification queries (record counts and TOP rows)
- Demo JSON queries using `FOR JSON PATH` / `JSON_QUERY`
- Sample `INSERT`s for:
  - `dbo.Room` (adds room numbers and sets status/type using lookup IDs)
  - `dbo.Reservation` (creates one reservation referencing RoomId and Customer/Employee person IDs)

---

## 6. Notes / Known mismatches in demo queries

Some demo JSON SELECT queries in the script reference columns/tables not created in the schema portion of the same script (examples):
- `dbo.ReservationRoom` (not created)
- `Reservation.BranchId` (not present in table)
- `Payment.PaymentMode`, `Payment.CardLast4`, and `Payment.PersonId` (not present in table)

These blocks appear to be **examples/drafts** and may require schema changes to run successfully.

---

## How to run

1. Open **SQL Server Management Studio (SSMS)**.
2. Open `sql/Hotel_reservation_final_code.sql`.
3. Execute in order:
   - Table creation
   - Lookup seeding
   - Stored procedures
