DROP TABLE IF EXISTS 
    Departments, Employees, Juniors, Bookers, Seniors, Managers, 
    MeetingRooms, HealthDeclarations, Sessions, Joins, Updates
CASCADE;

CREATE TABLE Departments (
    did INTEGER PRIMARY KEY, 
    dname CHARACTER VARYING(255) NOT NULL
);

CREATE TABLE Employees (
    eid INTEGER PRIMARY KEY, 
    ename CHARACTER VARYING(255) NOT NULL, 
    email CHARACTER VARYING(255) UNIQUE NOT NULL, 
    home_phone INTEGER, 
    mobile_phone INTEGER, 
    office_phone INTEGER, 
    resigned_date DATE, 
    did INTEGER NOT NULL, 
    FOREIGN KEY (did) REFERENCES Departments (did)
);

CREATE TABLE Juniors (
    eid INTEGER PRIMARY KEY,
    FOREIGN KEY (eid) REFERENCES Employees (eid) ON DELETE CASCADE
);

CREATE TABLE Bookers (
    eid INTEGER PRIMARY KEY,
    FOREIGN KEY (eid) REFERENCES Employees (eid) ON DELETE CASCADE
);

CREATE TABLE Seniors (
    eid INTEGER PRIMARY KEY,
    FOREIGN KEY (eid) REFERENCES Bookers (eid) ON DELETE CASCADE
);

CREATE TABLE Managers (
    eid INTEGER PRIMARY KEY,
    FOREIGN KEY (eid) REFERENCES Bookers (eid) ON DELETE CASCADE
);

CREATE TABLE MeetingRooms (
    room INTEGER, 
    storey INTEGER, 
    rname CHARACTER VARYING(255), 
    did INTEGER NOT NULL, 
    PRIMARY KEY (room, storey),
    FOREIGN KEY (did) REFERENCES Departments (did) ON UPDATE CASCADE
);

CREATE TABLE HealthDeclarations (
    declare_date DATE,
    temperature FLOAT NOT NULL,
    fever BOOLEAN, 
    eid INTEGER, 
    PRIMARY KEY (declare_date, eid), 
    FOREIGN KEY (eid) REFERENCES Employees (eid),
    CONSTRAINT temp_range CHECK (temperature BETWEEN 34 AND 43)
);

CREATE TABLE Sessions (
    book_date DATE, 
    start_hour INTEGER,
    eid INTEGER NOT NULL, 
    room INTEGER, 
    storey INTEGER, 
    approve_id INTEGER , 
    PRIMARY KEY (book_date, start_hour, room, storey), 
    FOREIGN KEY (eid) REFERENCES Bookers (eid), 
    FOREIGN KEY (approve_id) REFERENCES Managers (eid),
    FOREIGN KEY (room, storey) REFERENCES MeetingRooms (room, storey)
);

CREATE TABLE Joins (
    eid INTEGER, 
    book_date DATE, 
    start_hour INTEGER,
    room INTEGER, 
    storey INTEGER, 
    PRIMARY KEY (eid, book_date, start_hour, room, storey),
    FOREIGN KEY (eid) REFERENCES Employees (eid), 
    FOREIGN KEY (book_date, start_hour, room, storey) REFERENCES Sessions (book_date, start_hour, room, storey) ON DELETE CASCADE
);

CREATE TABLE Updates (
    update_date DATE,
    new_cap INTEGER, 
    eid INTEGER,
    room INTEGER,
    storey INTEGER,
    PRIMARY KEY(update_date, eid, room, storey),
    FOREIGN KEY (eid) REFERENCES Managers(eid),
    FOREIGN KEY (room, storey) REFERENCES MeetingRooms (room, storey)
);

