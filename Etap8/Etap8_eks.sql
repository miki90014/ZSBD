CREATE INDEX idx_genre_btree ON Books(Genre);
DROP INDEX idx_genre_btree;

CREATE BITMAP INDEX idx_genre_bitmap ON Books(Genre);
DROP INDEX idx_genre_bitmap;

EXPLAIN PLAN FOR
SELECT * FROM Books WHERE Genre = 'Fantasy';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY());