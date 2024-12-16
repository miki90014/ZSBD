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