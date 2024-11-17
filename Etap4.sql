SELECT 
    r.ReaderID,
    r.FirstName,
    r.LastName
FROM 
    Readers r
WHERE 
    (SELECT COUNT(*) 
     FROM Penalties p2 
     WHERE p2.ReaderID = r.ReaderID 
       AND p2.IsPaid = 'N' 
       AND p2.DueDate < SYSDATE) >= 3  -- czytelnicy z co najmniej trzema zaległymi karami
GROUP BY 
    r.ReaderID, r.FirstName, r.LastName;
--2.086s
-- 1m 11.293s

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
       AND l2.LoanDate >= SYSDATE - 365) AS LoansLastYear,  -- liczba wypożyczeń w ciągu ostatniego roku
    (SELECT COUNT(*) 
     FROM Penalties p2 
     WHERE p2.ReaderID = r.ReaderID 
       AND p2.IsPaid = 'N' 
       AND p2.DueDate < SYSDATE) AS OverdueCount  -- liczba zaległych kar
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
              AND l3.LoanDate >= SYSDATE - 30)  -- sprawdzanie czy czytelnik wypożyczył coś w ostatnich 30 dniach
GROUP BY 
    r.ReaderID, r.FirstName, r.LastName
HAVING 
    COUNT(DISTINCT l.LoanID) > 5  -- tylko czytelnicy, którzy wypożyczyli więcej niż 5 książek
    OR SUM(CASE WHEN p.IsPaid = 'N' THEN p.Amount ELSE 0 END) > 0;  -- lub mają zaległe kary
--1.932s
--42.632s





SELECT 
    b.Title,
    a.FirstName AS AuthorFirstName,
    a.LastName AS AuthorLastName,
    AVG(r.Rating) AS AverageRating,
    COUNT(l.LoanID) AS TotalLoans
FROM 
    Books b
JOIN 
    Authors a ON b.AuthorID = a.AuthorID
LEFT JOIN 
    Reviews r ON b.BookID = r.BookID
LEFT JOIN 
    BookCopies bc ON b.BookID = bc.BookID
LEFT JOIN 
    Loans l ON bc.CopyID = l.CopyID
WHERE 
    r.Rating IS NOT NULL  -- tylko książki z przynajmniej jedną oceną
GROUP BY 
    b.Title, a.FirstName, a.LastName
HAVING 
    AVG(r.Rating) > 4  -- tylko książki z wysoką średnią oceną
ORDER BY 
    AverageRating DESC;

--1.419s
--2.760s



UPDATE Loans l
SET DueDate = CASE
                WHEN LoanDate < SYSDATE - 60 THEN SYSDATE + 10   -- Długi czas przetrzymania, dodaj 10 dni
                WHEN LoanDate BETWEEN SYSDATE - 30 AND SYSDATE - 60 THEN DueDate + 7  -- Przetrzymanie od 30 do 60 dni, dodaj 7 dni
                ELSE DueDate + 3  -- Krótsze przetrzymanie, dodaj 3 dni
              END
WHERE l.CopyID IN (
    SELECT bc.CopyID
    FROM BookCopies bc
    JOIN Books b ON bc.BookID = b.BookID
    LEFT JOIN Reviews r ON b.BookID = r.BookID
    LEFT JOIN Loans l2 ON bc.CopyID = l2.CopyID
    GROUP BY bc.CopyID, b.BookID
    HAVING COUNT(l2.LoanID) > 10  -- Egzemplarze często wypożyczane
       OR AVG(r.Rating) > 4       -- Książki wysoko oceniane
)
AND l.DueDate < SYSDATE;  -- tylko dla przeterminowanych wypożyczeń
--01.309s



UPDATE Penalties
SET Amount = Amount * 1.1
WHERE ReaderID IN (
    SELECT ReaderID
    FROM Loans
    WHERE DueDate < SYSDATE
      AND ReturnDate IS NULL
)
AND IsPaid = 'N';
-- 1.02s
-- 0.243s


UPDATE BookCopies bc
SET Location = 'Archived'
WHERE bc.CopyID IN (
    SELECT bc2.CopyID
    FROM BookCopies bc2
    JOIN Books b ON bc2.BookID = b.BookID
    LEFT JOIN Loans l ON bc2.CopyID = l.CopyID
    WHERE bc2.IsAvailable = 'N'  -- Niedostępne egzemplarze
      AND (l.LoanDate IS NULL OR l.LoanDate < SYSDATE - INTERVAL '1' YEAR)  -- Nie wypożyczane przez ponad rok
      AND b.PublicationDate < SYSDATE - INTERVAL '5' YEAR  -- Książki starsze niż 5 lat
      AND EXISTS (
          SELECT 1
          FROM Reviews r
          WHERE r.BookID = b.BookID
            AND r.Rating < 3  -- Książki o niskiej ocenie
      )
    GROUP BY bc2.CopyID
    HAVING COUNT(l.LoanID) < 5  -- Wypożyczane mniej niż 5 razy
);
--1.402s
--1.017s