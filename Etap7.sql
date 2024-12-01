CREATE BITMAP INDEX idx_penalties_is_paid ON Penalties (IsPaid);

CREATE INDEX IDX_BOOKS_DATE_ID ON Books(PublicationDate, BookID);

-- Funkcyjny
CREATE INDEX IDX_REVIEWS_AVG_RATING ON Reviews(Rating);