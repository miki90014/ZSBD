-- Usuwanie recenzji podejrzanych o spam:
/* Zapytanie, które usuwa recenzje podejrzane o spam 
w top 10 najczęściej wypożyczanych książkach. 
Recenzje podejrzane o spam mają stworzoną recenzję i czytelnika tego samego dnia oraz 
czytelnik nie wypożyczył nigdy tej książki. W recenzji również znajduje się link */

WITH TopBooks AS (
    SELECT BookID
    FROM Loans L
    JOIN BookCopies BC ON L.CopyID = BC.CopyID
    GROUP BY BC.BookID
    ORDER BY COUNT(L.LoanID) DESC
    LIMIT 10
),

SpamReviews AS (
    SELECT R.ReviewID
    FROM Reviews R
    JOIN Readers RD ON R.ReaderID = RD.ReaderID
    LEFT JOIN Loans L ON R.BookID = L.BookID AND R.ReaderID = L.ReaderID
    WHERE R.BookID IN (SELECT BookID FROM TopBooks)
      AND R.ReviewDate = RD.JoinDate
      AND L.LoanID IS NULL
      AND R.ReviewText LIKE '%http%'
)

DELETE FROM Reviews
WHERE ReviewID IN (SELECT ReviewID FROM SpamReviews);


/*To zapytanie wyszukuje wszystkich czytelników, którzy mają aktualnie wypożyczoną książkę oraz naliczone kary, a ich suma przekracza 50 zł. 
Dodatkowo zwracamy informację, ile czasu minęło od najstarszej niezapłaconej kary.*/
SELECT 
    r.FirstName, 
    r.LastName, 
    SUM(p.Amount) AS TotalPenalties, 
    DATEDIFF(CURDATE(), MIN(p.IssueDate)) AS DaysSinceOldestUnpaidPenalty
FROM 
    Readers r
JOIN 
    Loans l ON r.ReaderID = l.ReaderID
JOIN 
    Penalties p ON r.ReaderID = p.ReaderID
WHERE 
    l.ReturnDate IS NULL
    AND p.IsPaid = 'N'
GROUP BY 
    r.FirstName, r.LastName
HAVING 
    SUM(p.Amount) > 50
ORDER BY 
    TotalPenalties DESC;



SELECT 
    a.AuthorID,
    CONCAT(a.FirstName, ' ', a.LastName) AS AuthorFullName,
    COUNT(b.BookID) AS TotalBooks,
    AVG(r.CurrentPenalties) AS AveragePenalties,
    SUM(p.Amount) AS TotalPenalties,
    COUNT(DISTINCT r.ReaderID) AS TotalReaders,
    COUNT(DISTINCT l.LoanID) AS TotalLoans,
    MAX(b.PublicationDate) AS LatestPublication,
    MIN(l.LoanDate) AS EarliestLoanDate,
    DATEDIFF(CURDATE(), MIN(l.LoanDate)) AS DaysSinceFirstLoan,
    AVG(TIMESTAMPDIFF(DAY, l.LoanDate, COALESCE(l.ReturnDate, CURDATE()))) AS AverageLoanDuration,
    b.Genre,
    COUNT(DISTINCT bc.CopyID) AS TotalCopies,
    SUM(CASE WHEN bc.IsAvailable = 'N' THEN 1 ELSE 0 END) AS TotalUnavailableCopies
FROM 
    Authors a
JOIN 
    Books b ON a.AuthorID = b.AuthorID
JOIN 
    Reviews rev ON b.BookID = rev.BookID
JOIN 
    Readers r ON rev.ReaderID = r.ReaderID
JOIN 
    Loans l ON r.ReaderID = l.ReaderID
JOIN 
    BookCopies bc ON l.CopyID = bc.CopyID
LEFT JOIN 
    Penalties p ON r.ReaderID = p.ReaderID
GROUP BY 
    a.AuthorID, b.Genre
HAVING 
    COUNT(b.BookID) > 0
ORDER BY 
    TotalBooks DESC, AveragePenalties DESC;


UPDATE BookCopies bc
JOIN Loans l ON bc.CopyID = l.CopyID
JOIN Readers r ON l.ReaderID = r.ReaderID
JOIN Books b ON bc.BookID = b.BookID
SET 
    bc.IsAvailable = 'N',
    r.CurrentPenalties = CASE 
                            WHEN DATEDIFF(CURDATE(), l.LoanDate) > 30 THEN r.CurrentPenalties + 10.00
                            ELSE r.CurrentPenalties 
                          END,
    r.JoinDate = DATE_ADD(r.JoinDate, INTERVAL 1 DAY)
WHERE 
    l.ReturnDate IS NULL
    AND bc.IsAvailable = 'Y'
    AND EXISTS (
        SELECT 1
        FROM Penalties p
        WHERE p.ReaderID = r.ReaderID AND p.IsPaid = 'N'
    )
    AND r.ReaderID IN (
        SELECT ReaderID
        FROM Readers
        WHERE CurrentPenalties > 0
        ORDER BY RAND()
        LIMIT 100
    )
    AND (SELECT COUNT(*)
         FROM Loans l2
         WHERE l2.ReaderID = r.ReaderID) > 5;