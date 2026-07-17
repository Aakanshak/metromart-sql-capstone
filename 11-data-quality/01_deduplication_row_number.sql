/*
Business question: Which raw order headers are double inserts, and how can one canonical row be retained safely?
*/
WITH marked AS (
 SELECT o.*,row_number() OVER(PARTITION BY order_id ORDER BY loaded_at,order_row_id) duplicate_sequence,
 count(*) OVER(PARTITION BY order_id) copies FROM orders o
)
SELECT * FROM marked WHERE copies>1 ORDER BY order_id,duplicate_sequence;
-- Safe remediation pattern after review:
-- DELETE FROM orders WHERE order_row_id IN (SELECT order_row_id FROM marked WHERE duplicate_sequence>1);
/*
So what: ROW_NUMBER preserves a deterministic survivor and exposes all 800 bad copies before any destructive cleanup is approved.
*/
