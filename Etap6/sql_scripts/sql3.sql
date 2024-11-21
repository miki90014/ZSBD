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