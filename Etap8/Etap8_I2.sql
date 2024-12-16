-- nowe zapytanie
EXPLAIN PLAN FOR
SELECT /*+ INDEX(b IDX_BOOKS_DATE_ID) */
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


EXPLAIN PLAN FOR
SELECT /*+ INDEX(b IDX_BOOKS_DATE_ID) */
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
    (SELECT COUNT(*)
     FROM BookCopies bc2
     WHERE bc2.BookID = b.BookID
       AND bc2.IsAvailable = 'Y') AS TotalAvailableCopies  
FROM 
    Books b
JOIN 
    BookCopies bc ON b.BookID = bc.BookID 
LEFT JOIN 
    Reviews rv ON b.BookID = rv.BookID  
LEFT JOIN 
    Loans l ON bc.CopyID = l.CopyID 
LEFT JOIN 
    Penalties p ON l.ReaderID = p.ReaderID AND p.IsPaid = 'N'  
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