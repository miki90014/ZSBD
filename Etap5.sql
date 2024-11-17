

--Drugie zapytanie
EXPLAIN PLAN FOR
SELECT 
    r.ReaderID,
    r.FirstName,
    r.LastName,
    COUNT(DISTINCT l.LoanID) AS TotalLoans,  -- całkowita liczba wypożyczeń
    SUM(CASE WHEN p.IsPaid = 'N' THEN p.Amount ELSE 0 END) AS UnpaidPenalties,  -- suma niezapłaconych kar
    COUNT(DISTINCT rv.BookID) AS TotalReviewedBooks,  -- liczba książek, które ocenił
    AVG(rv.Rating) AS AvgBookRating,  -- średnia ocena książek, które ocenił
    (SELECT COUNT(*) 
     FROM Loans l2 
     WHERE l2.ReaderID = r.ReaderID 
       AND l2.LoanDate >= TO_DATE('2024-01-01', 'YYYY-MM-DD') - 365) AS LoansLastYear,  -- liczba wypożyczeń w ciągu ostatniego roku
    (SELECT COUNT(*) 
     FROM Penalties p2 
     WHERE p2.ReaderID = r.ReaderID 
       AND p2.IsPaid = 'N' 
       AND p2.DueDate < TO_DATE('2024-01-01', 'YYYY-MM-DD')) AS OverdueCount  -- liczba zaległych kar
FROM 
    Readers r
LEFT JOIN 
    Loans l ON r.ReaderID = l.ReaderID
LEFT JOIN 
    Penalties p ON r.ReaderID = p.ReaderID
LEFT JOIN 
    Reviews rv ON r.ReaderID = rv.ReaderID
WHERE 
    EXISTS (SELECT 1 
            FROM Loans l3 
            WHERE l3.ReaderID = r.ReaderID 
              AND l3.LoanDate >= TO_DATE('2020-01-01', 'YYYY-MM-DD') - 30)  -- sprawdzanie czy czytelnik wypożyczył coś w ostatnich 30 dniach
GROUP BY 
    r.ReaderID, r.FirstName, r.LastName
HAVING 
    COUNT(DISTINCT l.LoanID) > 5  -- tylko czytelnicy, którzy wypożyczyli więcej niż 5 książek
    OR SUM(CASE WHEN p.IsPaid = 'N' THEN p.Amount ELSE 0 END) > 0;  -- lub mają zaległe kary
--2:01:56





-- nowe zapytanie
EXPLAIN PLAN FOR
SELECT 
    a.AuthorID,
    a.FirstName,
    a.LastName,
    COUNT(DISTINCT b.BookID) AS TotalBooksPublished,  -- liczba unikalnych książek opublikowanych
    AVG(EXTRACT(YEAR FROM b.PublicationDate)) AS AvgPublicationYear,  -- średni rok publikacji
    COUNT(DISTINCT rv.ReviewID) AS TotalReviews,  -- liczba recenzji dla książek autora
    AVG(rv.Rating) AS AvgRating,  -- średnia ocena książek autora
    (SELECT COUNT(*)
     FROM Books b2
     WHERE b2.AuthorID = a.AuthorID
       AND b2.PublicationDate >= TO_DATE('2020-01-01', 'YYYY-MM-DD')) AS RecentBooksPublished,  -- liczba książek wydanych od 2020 roku
    (SELECT COUNT(*)
     FROM BookCopies bc2
     WHERE bc2.BookID IN (SELECT b3.BookID FROM Books b3 WHERE b3.AuthorID = a.AuthorID)
       AND bc2.IsAvailable = 'Y') AS TotalAvailableCopies  -- liczba dostępnych egzemplarzy książek autora
FROM 
    Authors a
LEFT JOIN 
    Books b ON a.AuthorID = b.AuthorID
LEFT JOIN 
    Reviews rv ON b.BookID = rv.BookID
GROUP BY 
    a.AuthorID, a.FirstName, a.LastName
HAVING 
    COUNT(DISTINCT b.BookID) > 5  -- autor opublikował więcej niż 5 książek
    OR AVG(rv.Rating) >= 4;  -- lub średnia ocena jego książek wynosi co najmniej 4
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY());
--10:18:10
DELETE FROM PLAN_TABLE;
COMMIT;

--nowe zapytanie
EXPLAIN PLAN FOR
DELETE FROM Penalties p
WHERE p.PenaltyID IN (
    SELECT p2.PenaltyID
    FROM Penalties p2
    JOIN Loans l ON p2.ReaderID = l.ReaderID
    JOIN Readers r ON p2.ReaderID = r.ReaderID
    LEFT JOIN BookCopies bc ON l.CopyID = bc.CopyID
    LEFT JOIN Books b ON bc.BookID = b.BookID
    LEFT JOIN Reviews rv ON b.BookID = rv.BookID
    LEFT JOIN Penalties p3 ON p2.ReaderID = p3.ReaderID AND p3.IsPaid = 'N'
    WHERE l.DueDate < TO_DATE('2022-01-01', 'YYYY-MM-DD')
      AND l.ReturnDate IS NULL
      AND p2.IsPaid = 'N'
      AND (
          SELECT COUNT(*) 
          FROM Loans l2
          WHERE l2.ReaderID = l.ReaderID 
            AND l2.LoanDate >= TO_DATE('2022-01-01', 'YYYY-MM-DD') - INTERVAL '1' YEAR
      ) > 2  -- Czytelnik ma więcej niż 2 aktywne wypożyczenia w ciągu ostatniego roku
      AND EXISTS (  -- Książki, które są wypożyczane w określonych lokalizacjach
          SELECT 1
          FROM BookCopies bc2
          WHERE bc2.CopyID = l.CopyID
            AND bc2.Location like 'Główna aleja%'
      )
      AND NOT EXISTS (  -- Książki, które mają niską średnią ocenę
          SELECT 1
          FROM Reviews rv2
          WHERE rv2.BookID = b.BookID
            AND rv2.Rating < 3
      )
      AND EXISTS (  -- Czytelnik ma niezapłacone kary w sumie powyżej 100 zł
          SELECT 1
          FROM Penalties p4
          WHERE p4.ReaderID = l.ReaderID
            AND p4.IsPaid = 'N'
          HAVING SUM(p4.Amount) > 100
      )
      AND (
          SELECT SUM(p.Amount)
          FROM Penalties p2
          WHERE p2.IsPaid = 'N'
            AND p2.DueDate < TO_DATE('2020-01-01', 'YYYY-MM-DD')  -- Sprawdzanie niezapłaconych kar
      ) > 0
    GROUP BY p2.PenaltyID, l.ReaderID, bc.Location
    HAVING COUNT(l.LoanID) > 3  -- Czytelnik wypożyczył więcej niż 3 książki
);
ROLLBACK;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY());
--212:09:23

EXPLAIN PLAN FOR
SELECT 
    b.BookID, 
    b.Title, 
    b.PublicationDate, 
    AVG(rv.Rating) AS AvgRating,  -- Średnia ocena książki
    COUNT(DISTINCT l.LoanID) AS TotalLoans,  -- Liczba wypożyczeń książki
    SUM(CASE 
            WHEN l.DueDate < SYSDATE AND l.ReturnDate IS NULL THEN 1
            ELSE 0
        END) AS TotalDelayedLoans,  -- Liczba wypożyczeń spóźnionych (nie oddanych na czas)
    COUNT(DISTINCT bc.CopyID) AS TotalCopies,  -- Liczba dostępnych egzemplarzy książki
    COUNT(DISTINCT CASE 
                     WHEN bc.Location LIKE 'Boczna aleja%' THEN bc.CopyID
                     ELSE NULL
                   END) AS AlejaLocationCopies,  -- Liczba dostępnych egzemplarzy w lokalizacjach "Aleja"
    COUNT(DISTINCT rv.ReviewID) AS TotalReviews,  -- Liczba recenzji książki
    (SELECT COUNT(*)
     FROM BookCopies bc2
     WHERE bc2.BookID = b.BookID
       AND bc2.IsAvailable = 'Y') AS TotalAvailableCopies  -- Łączna liczba dostępnych egzemplarzy książki
FROM 
    Books b
JOIN 
    BookCopies bc ON b.BookID = bc.BookID  -- Połączenie z tabelą kopii książek
LEFT JOIN 
    Reviews rv ON b.BookID = rv.BookID  -- Połączenie z recenzjami książek
LEFT JOIN 
    Loans l ON bc.CopyID = l.CopyID  -- Połączenie z wypożyczeniami książek
LEFT JOIN 
    Penalties p ON l.ReaderID = p.ReaderID AND p.IsPaid = 'N'  -- Połączenie z karami, które nie zostały opłacone
WHERE 
    b.PublicationDate < SYSDATE - INTERVAL '2' YEAR  -- Książki starsze niż 2 lata
    AND EXISTS (  -- Książki dostępne w lokalizacjach 'Aleja'
        SELECT 1
        FROM BookCopies bc2
        WHERE bc2.BookID = b.BookID
          AND bc2.Location LIKE 'Boczna aleja%'
          AND bc2.IsAvailable = 'Y'
    )
GROUP BY 
    b.BookID, b.Title, b.PublicationDate
HAVING 
    AVG(rv.Rating) >= 2  -- Książki, które mają średnią ocenę >= 4
    AND COUNT(DISTINCT l.LoanID) > 1  -- Książki, które były wypożyczane więcej niż 5 razy
    AND COUNT(DISTINCT rv.ReviewID) > 1  -- Książki, które mają więcej niż 1 recenzję
ORDER BY 
    AvgRating DESC, TotalLoans DESC;


SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY());
--2:38



DELETE FROM PLAN_TABLE;
COMMIT;

-- modyfikacja danych
EXPLAIN PLAN FOR
UPDATE Penalties p
SET p.IsPaid = 'Y'
WHERE p.PenaltyID IN (
    SELECT p2.PenaltyID
    FROM Penalties p2
    JOIN Loans l ON p2.ReaderID = l.ReaderID
    JOIN Readers r ON p2.ReaderID = r.ReaderID
    LEFT JOIN BookCopies bc ON l.CopyID = bc.CopyID
    LEFT JOIN Books b ON bc.BookID = b.BookID
    LEFT JOIN Reviews rv ON b.BookID = rv.BookID
    LEFT JOIN Penalties p3 ON p2.ReaderID = p3.ReaderID AND p3.IsPaid = 'N'
    WHERE l.DueDate < TO_DATE('2022-01-01', 'YYYY-MM-DD')
      AND l.ReturnDate IS NULL
      AND p2.IsPaid = 'N'
      AND (
          SELECT COUNT(*) 
          FROM Loans l2
          WHERE l2.ReaderID = l.ReaderID 
            AND l2.LoanDate >= TO_DATE('2022-01-01', 'YYYY-MM-DD') - INTERVAL '1' YEAR
      ) > 2
      AND EXISTS (
          SELECT 1
          FROM BookCopies bc2
          WHERE bc2.CopyID = l.CopyID
            AND bc2.Location like 'Główna aleja%'
      )
      AND NOT EXISTS (
          SELECT 1
          FROM Reviews rv2
          WHERE rv2.BookID = b.BookID
            AND rv2.Rating < 3
      )
      AND EXISTS (
          SELECT 1
          FROM Penalties p4
          WHERE p4.ReaderID = l.ReaderID
            AND p4.IsPaid = 'N'
          HAVING SUM(p4.Amount) > 100
      )
    GROUP BY p2.PenaltyID, l.ReaderID, bc.Location
    HAVING COUNT(l.LoanID) > 3
);
ROLLBACK;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY());
--0:25:28

-- Modyfikacja danych w tabeli Loans
EXPLAIN PLAN FOR
UPDATE Loans l
SET l.ReturnDate = TO_DATE('2024-12-31', 'YYYY-MM-DD')
WHERE l.LoanID IN (
    SELECT l2.LoanID
    FROM Loans l2
    JOIN BookCopies bc ON l2.CopyID = bc.CopyID
    JOIN Books b ON bc.BookID = b.BookID
    JOIN Authors a ON b.AuthorID = a.AuthorID
    LEFT JOIN Reviews rv ON b.BookID = rv.BookID
    LEFT JOIN Readers r ON l2.ReaderID = r.ReaderID
    LEFT JOIN Penalties p ON r.ReaderID = p.ReaderID AND p.IsPaid = 'N'
    LEFT JOIN (
        SELECT l3.ReaderID, COUNT(l3.LoanID) AS LoanCount
        FROM Loans l3
        WHERE l3.DueDate < TO_DATE('2023-01-01', 'YYYY-MM-DD')
        GROUP BY l3.ReaderID
        HAVING COUNT(l3.LoanID) > 5
    ) high_loan_readers ON r.ReaderID = high_loan_readers.ReaderID
    LEFT JOIN (
        SELECT b2.BookID, AVG(rv2.Rating) AS AvgRating
        FROM Reviews rv2
        JOIN Books b2 ON rv2.BookID = b2.BookID
        WHERE rv2.Rating >= 4
        GROUP BY b2.BookID
    ) high_rated_books ON b.BookID = high_rated_books.BookID  -- Poprawka: b.BookID w JOIN

    WHERE l2.ReturnDate IS NULL
      AND l2.DueDate < TO_DATE('2023-01-01', 'YYYY-MM-DD')
      AND bc.IsAvailable = 'N'
      AND a.DateOfBirth < TO_DATE('1980-01-01', 'YYYY-MM-DD')
      AND (
          SELECT COUNT(*)
          FROM Loans l4
          WHERE l4.ReaderID = l2.ReaderID
            AND l4.LoanDate >= TO_DATE('2022-01-01', 'YYYY-MM-DD') - INTERVAL '1' YEAR
      ) > 3
      AND EXISTS (
          SELECT 1
          FROM Reviews rv3
          WHERE rv3.BookID = b.BookID
            AND rv3.Rating > 3
      )
      AND NOT EXISTS (
          SELECT 1
          FROM Penalties p2
          WHERE p2.ReaderID = r.ReaderID
            AND p2.IsPaid = 'N'
            AND p2.Amount > 50
            AND p2.DueDate < TO_DATE('2024-01-01', 'YYYY-MM-DD')
      )
      AND EXISTS (
          SELECT 1
          FROM BookCopies bc2
          WHERE bc2.CopyID = l2.CopyID
            AND bc2.Location LIKE 'Główna aleja%'
      )

    GROUP BY l2.LoanID, r.ReaderID, bc.Location, b.BookID, high_loan_readers.LoanCount, high_rated_books.AvgRating -- Dodano aliasy do GROUP BY

    HAVING COUNT(rv.ReviewID) > 2
      AND high_loan_readers.LoanCount > 3
      AND high_rated_books.AvgRating > 4.5 -- Sprawdzanie warunków w HAVING dla agregowanych aliasów
)
ROLLBACK;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY());
--00:23:07