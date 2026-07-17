/*
Business question: What was each customer's address on 2025-01-15, and what is their current address?
*/
WITH as_of_address AS (
 SELECT DISTINCT ON(customer_id) customer_id,address,region FROM customer_addresses
 WHERE effective_date<=date '2025-01-15' AND (end_date>date '2025-01-15' OR end_date IS NULL)
 ORDER BY customer_id,effective_date DESC
), current_address AS (
 SELECT DISTINCT ON(customer_id) customer_id,address,region FROM customer_addresses
 WHERE end_date IS NULL ORDER BY customer_id,effective_date DESC
)
SELECT c.customer_id,a.address address_as_of_2025_01_15,a.region region_as_of_2025_01_15,
 cur.address current_address,cur.region current_region
FROM customers c LEFT JOIN as_of_address a USING(customer_id) LEFT JOIN current_address cur USING(customer_id);
/*
So what: Half-open [effective,end) logic prevents double matches at move boundaries; missing as-of rows intentionally reveal source-history gaps.
*/
