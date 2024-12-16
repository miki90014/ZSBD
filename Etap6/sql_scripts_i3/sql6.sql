UPDATE Loans l
SET l.ReturnDate = TO_DATE('2024-12-31', 'YYYY-MM-DD')
WHERE l.LoanID IN (
    SELECT /*+ INDEX(l2 IDX_LOAN_DATE_CONVERT) */ l2.LoanID
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
    ) high_rated_books ON b.BookID = high_rated_books.BookID  

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

    GROUP BY l2.LoanID, r.ReaderID, bc.Location, b.BookID, high_loan_readers.LoanCount, high_rated_books.AvgRating 

    HAVING COUNT(rv.ReviewID) > 2
      AND high_loan_readers.LoanCount > 3
      AND high_rated_books.AvgRating > 4.5 
);