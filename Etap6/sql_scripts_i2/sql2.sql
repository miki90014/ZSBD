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