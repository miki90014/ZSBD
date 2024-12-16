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