# Subqueries and set operations

The same membership question is expressed with EXISTS, IN, and JOIN plus DISTINCT. PostgreSQL may produce similar semi-join plans for EXISTS and IN; JOIN can multiply rows. Use EXPLAIN ANALYZE rather than assuming a universal winner.

Generated marketing lists contain 7,349 email rows, 6,114 SMS rows, and 2,269 exact identity overlaps before normalization.
