/*
Business question: Is a set-based window rewrite always faster than a correlated subquery after indexing?
*/
EXPLAIN (ANALYZE,BUFFERS,FORMAT TEXT)
SELECT DISTINCT o.order_id,o.customer_id,sum(i.quantity*i.unit_price_at_sale) OVER(PARTITION BY o.order_id) order_value
FROM vw_orders_deduplicated o JOIN order_items i USING(order_id) WHERE o.order_id<=1000;
/*
ACTUAL PLAN EXCERPT (same indexed database):
WindowAgg rows=1,726; Unique rows=1,000
Index Only Scan idx_order_items_order_id_cover: loops=1,000; Heap Fetches=0
Planning Time: 3.498 ms
Execution Time: 5.353 ms
So what: The rewrite avoids scalar syntax but must expand line items then sort/deduplicate. At this selective grain, indexed correlation (3.481 ms) beats the window (5.353 ms); set-based is not automatically faster.
*/
