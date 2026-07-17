/*
Business question: Which customers bought Electronics in the last 90 days, and how do EXISTS, IN, and JOIN compare?
Run each EXPLAIN (ANALYZE, BUFFERS) after loading; captured output is written by scripts/capture_explain.py.
*/
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT c.customer_id,c.name FROM customers c WHERE EXISTS (
 SELECT 1 FROM vw_orders_deduplicated o JOIN order_items i USING(order_id) JOIN products p USING(product_id)
 WHERE o.customer_id=c.customer_id AND o.order_date>=date '2026-04-01' AND o.status='completed' AND p.category='Electronics'
);
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT customer_id,name FROM customers WHERE customer_id IN (
 SELECT o.customer_id FROM vw_orders_deduplicated o JOIN order_items i USING(order_id) JOIN products p USING(product_id)
 WHERE o.order_date>=date '2026-04-01' AND o.status='completed' AND p.category='Electronics'
);
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT DISTINCT c.customer_id,c.name FROM customers c JOIN vw_orders_deduplicated o USING(customer_id)
JOIN order_items i USING(order_id) JOIN products p USING(product_id)
WHERE o.order_date>=date '2026-04-01' AND o.status='completed' AND p.category='Electronics';
/*
So what: PostgreSQL often decorrelates EXISTS and IN to semi-joins; JOIN needs DISTINCT and may process many duplicate matches. Actual plans decide.
*/
