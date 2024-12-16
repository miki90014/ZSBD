CREATE BITMAP INDEX idx_penalties_is_paid ON Penalties (IsPaid);
DROP INDEX idx_penalties_is_paid;
-- sql1,3,4,5,6

CREATE INDEX IDX_BOOKS_DATE_ID ON Books(PublicationDate, BookID);
DROP INDEX IDX_BOOKS_DATE_ID;
-- sql2 i sql4

-- Funkcyjny
CREATE INDEX IDX_LOAN_DATE_CONVERT ON Loans(TO_DATE(LoanDate, 'YYYY-MM-DD')); 
DROP INDEX IDX_LOAN_DATE_CONVERT;
-- sql3,5,6