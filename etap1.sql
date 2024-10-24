-- Tworzenie tabeli Autorzy
CREATE TABLE Authors (
    AuthorID INT PRIMARY KEY AUTO_INCREMENT,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    DateOfBirth DATE,
    Country VARCHAR(50)
);

-- Tworzenie tabeli Książki
CREATE TABLE Books (
    BookID INT PRIMARY KEY AUTO_INCREMENT,
    Title VARCHAR(100) NOT NULL,
    PublicationDate DATE,
    Genre VARCHAR(50),
    AuthorID INT,
    FOREIGN KEY (AuthorID) REFERENCES Authors(AuthorID)
);

-- Tworzenie tabeli Czytelnicy
CREATE TABLE Readers (
    ReaderID INT PRIMARY KEY AUTO_INCREMENT,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    JoinDate DATE
);

-- Tworzenie tabeli Egzemplarze książek
CREATE TABLE BookCopies (
    CopyID INT PRIMARY KEY AUTO_INCREMENT,
    BookID INT,
    Location VARCHAR(50),
    IsAvailable CHAR(1) CHECK (IsAvailable IN ('Y', 'N')),
    AcquisitionDate DATE,
    FOREIGN KEY (BookID) REFERENCES Books(BookID)
);

-- Tworzenie tabeli Wypożyczenia
CREATE TABLE Loans (
    LoanID INT PRIMARY KEY AUTO_INCREMENT,
    CopyID INT,
    ReaderID INT,
    LoanDate DATE NOT NULL,
    ReturnDate DATE,
    FOREIGN KEY (CopyID) REFERENCES BookCopies(CopyID),
    FOREIGN KEY (ReaderID) REFERENCES Readers(ReaderID)
);

-- Tworzenie tabeli Kary
CREATE TABLE Penalties (
    PenaltyID INT PRIMARY KEY AUTO_INCREMENT,
    ReaderID INT,
    Amount DECIMAL(10, 2) NOT NULL,
    IssueDate DATE NOT NULL,
    DueDate DATE NOT NULL,
    IsPaid CHAR(1) CHECK (IsPaid IN ('Y', 'N')),
    FOREIGN KEY (ReaderID) REFERENCES Readers(ReaderID)
);

-- Tworzenie tabeli Recenzje
CREATE TABLE Reviews (
    ReviewID INT PRIMARY KEY AUTO_INCREMENT,
    ReaderID INT,
    BookID INT,
    Rating INT CHECK (Rating >= 1 AND Rating <= 5),
    ReviewText TEXT,
    ReviewDate DATE NOT NULL,
    FOREIGN KEY (ReaderID) REFERENCES Readers(ReaderID),
    FOREIGN KEY (BookID) REFERENCES Books(BookID)
);