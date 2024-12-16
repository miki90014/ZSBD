--Drugie zapytanie
EXPLAIN PLAN FOR
SELECT /*+ INDEX(p idx_penalties_is_paid)*/
    r.ReaderID,
    r.FirstName,
    r.LastName,
    COUNT(DISTINCT l.LoanID) AS TotalLoans, 
    SUM(CASE WHEN p.IsPaid = 'N' THEN p.Amount ELSE 0 END) AS UnpaidPenalties,  
    COUNT(DISTINCT rv.BookID) AS TotalReviewedBooks,  
    AVG(rv.Rating) AS AvgBookRating, 
    (SELECT COUNT(*) 
     FROM Loans l2 
     WHERE l2.ReaderID = r.ReaderID 
       AND l2.LoanDate >= TO_DATE('2024-01-01', 'YYYY-MM-DD') - 365) AS LoansLastYear, 
    (SELECT /*+ INDEX(p2 idx_penalties_is_paid)*/ COUNT(*) 
     FROM Penalties p2 
     WHERE p2.ReaderID = r.ReaderID 
       AND p2.IsPaid = 'N' 
       AND p2.DueDate < TO_DATE('2024-01-01', 'YYYY-MM-DD')) AS OverdueCount  
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
              AND l3.LoanDate >= TO_DATE('2020-01-01', 'YYYY-MM-DD') - 30)  
GROUP BY 
    r.ReaderID, r.FirstName, r.LastName
HAVING 
    COUNT(DISTINCT l.LoanID) > 5  
    OR SUM(CASE WHEN p.IsPaid = 'N' THEN p.Amount ELSE 0 END) > 0; 
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY());

-- nowe zapytanie
EXPLAIN PLAN FOR
SELECT 
    a.AuthorID,
    a.FirstName,
    a.LastName,
    COUNT(DISTINCT b.BookID) AS TotalBooksPublished,  
    AVG(EXTRACT(YEAR FROM b.PublicationDate)) AS AvgPublicationYear,  
    COUNT(DISTINCT rv.ReviewID) AS TotalReviews,  
    AVG(rv.Rating) AS AvgRating,  
    (SELECT COUNT(*)
     FROM Books b2
     WHERE b2.AuthorID = a.AuthorID
       AND b2.PublicationDate >= TO_DATE('2020-01-01', 'YYYY-MM-DD')) AS RecentBooksPublished,  
    (SELECT COUNT(*)
     FROM BookCopies bc2
     WHERE bc2.BookID IN (SELECT b3.BookID FROM Books b3 WHERE b3.AuthorID = a.AuthorID)
       AND bc2.IsAvailable = 'Y') AS TotalAvailableCopies  
FROM 
    Authors a
LEFT JOIN 
    Books b ON a.AuthorID = b.AuthorID
LEFT JOIN 
    Reviews rv ON b.BookID = rv.BookID
GROUP BY 
    a.AuthorID, a.FirstName, a.LastName
HAVING 
    COUNT(DISTINCT b.BookID) > 5  
    OR AVG(rv.Rating) >= 4;  

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
    LEFT JOIN Books b /*+ INDEX(b IDX_BOOKS_DATE_ID) */ ON bc.BookID = b.BookID
    LEFT JOIN Reviews rv ON b.BookID = rv.BookID
    LEFT JOIN Penalties p3 /*+ INDEX(p3 idx_penalties_is_paid) */ ON p2.ReaderID = p3.ReaderID AND p3.IsPaid = 'N'
    WHERE l.DueDate < TO_DATE('2022-01-01', 'YYYY-MM-DD')
      AND l.ReturnDate IS NULL
      AND p2.IsPaid = 'N'
      AND (
          SELECT COUNT(*) 
          FROM Loans l2 /*+ INDEX(l2 IDX_LOAN_DATE_CONVERT) */
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
          FROM Penalties p4 /*+ INDEX(p4 idx_penalties_is_paid) */
          WHERE p4.ReaderID = l.ReaderID
            AND p4.IsPaid = 'N'
          HAVING SUM(p4.Amount) > 100
      )
    GROUP BY p2.PenaltyID, l.ReaderID, bc.Location
    HAVING COUNT(l.LoanID) > 3 
);
ROLLBACK;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY());
--00:25:28

EXPLAIN PLAN FOR
SELECT 
    /*+ INDEX(b IDX_BOOKS_DATE_ID) */
    b.BookID, 
    b.Title, 
    b.PublicationDate, 
    AVG(rv.Rating) AS AvgRating,  
    COUNT(DISTINCT l.LoanID) AS TotalLoans,  
    SUM(CASE 
            WHEN l.DueDate < SYSDATE AND l.ReturnDate IS NULL THEN 1
            ELSE 0
        END) AS TotalDelayedLoans, 
    COUNT(DISTINCT bc.CopyID) AS TotalCopies,  
    COUNT(DISTINCT CASE 
                     WHEN bc.Location LIKE 'Boczna aleja%' THEN bc.CopyID
                     ELSE NULL
                   END) AS AlejaLocationCopies,  
    COUNT(DISTINCT rv.ReviewID) AS TotalReviews,  
    (SELECT /*+ INDEX(bc2 IDX_BOOKS_DATE_ID) */ COUNT(*)
     FROM BookCopies bc2
     WHERE bc2.BookID = b.BookID
       AND bc2.IsAvailable = 'Y') AS TotalAvailableCopies  
FROM 
    Books b
JOIN 
    BookCopies bc /*+ INDEX(bc IDX_BOOKS_DATE_ID) */ ON b.BookID = bc.BookID 
LEFT JOIN 
    Reviews rv ON b.BookID = rv.BookID  
LEFT JOIN 
    Loans l ON bc.CopyID = l.CopyID 
LEFT JOIN 
    Penalties p /*+ INDEX(p idx_penalties_is_paid) */ ON l.ReaderID = p.ReaderID AND p.IsPaid = 'N'  
WHERE 
    b.PublicationDate < SYSDATE - INTERVAL '2' YEAR 
    AND EXISTS (  
        SELECT 1
        FROM BookCopies bc2
        WHERE bc2.BookID = b.BookID
          AND bc2.Location LIKE 'Boczna aleja%'
          AND bc2.IsAvailable = 'Y'
    )
GROUP BY 
    b.BookID, b.Title, b.PublicationDate
HAVING 
    AVG(rv.Rating) >= 2  
    AND COUNT(DISTINCT l.LoanID) > 1  
    AND COUNT(DISTINCT rv.ReviewID) > 1  
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
    LEFT JOIN Penalties p3 /*+ INDEX(p3 idx_penalties_is_paid) */ ON p2.ReaderID = p3.ReaderID AND p3.IsPaid = 'N'
    WHERE l.DueDate < TO_DATE('2022-01-01', 'YYYY-MM-DD')
      AND l.ReturnDate IS NULL
      AND p2.IsPaid = 'N'
      AND (
          SELECT COUNT(*) 
          FROM Loans l2 /*+ INDEX(l2 IDX_LOAN_DATE_CONVERT) */
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
          FROM Penalties p4 /*+ INDEX(p4 idx_penalties_is_paid) */
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
    /*+ INDEX(p idx_penalties_is_paid) */
    LEFT JOIN (
        SELECT /*+ INDEX(l3 IDX_LOAN_DATE_CONVERT) */ l3.ReaderID, COUNT(l3.LoanID) AS LoanCount
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
    ) high_rated_books ON b.BookID = high_rated_books.BookID  

    WHERE /*+ INDEX(l2 IDX_LOAN_DATE_CONVERT) */ l2.ReturnDate IS NULL
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
          SELECT /*+ INDEX(p2 idx_penalties_is_paid) */ 1
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

    GROUP BY l2.LoanID, r.ReaderID, bc.Location, b.BookID, high_loan_readers.LoanCount, high_rated_books.AvgRating 

    HAVING COUNT(rv.ReviewID) > 2
      AND high_loan_readers.LoanCount > 3
      AND high_rated_books.AvgRating > 4.5 
);
ROLLBACK;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY());
--00:23:07