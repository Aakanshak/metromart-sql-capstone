/*
Business question: What is the value of the first 1,000 logical orders, and why is the naive correlated lookup slow?
Captured on PostgreSQL 18.4, Windows, 200,800 raw orders / 340,366 items, cold indexing baseline.
*/
EXPLAIN (ANALYZE,BUFFERS,FORMAT TEXT)
SELECT o.order_id,o.customer_id,
 (SELECT sum(i.quantity*i.unit_price_at_sale) FROM order_items i WHERE i.order_id=o.order_id) order_value
FROM vw_orders_deduplicated o WHERE o.order_id<=1000;
/*
ACTUAL PLAN EXCERPT:
Seq Scan on orders: rows=1,004; Rows Removed by Filter=199,796
SubPlan Aggregate loops=1,000
  Seq Scan on order_items loops=1,000; Rows Removed by Filter=340,364
Buffers: shared hit=2,890,142
Planning Time: 2.391 ms
Execution Time: 13,560.194 ms
So what: The correlated subquery rescanned all 340K items 1,000 times; repeated work, not row count alone, caused the 13.56-second latency.
*/
