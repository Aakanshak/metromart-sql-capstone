/*
Business question: Which targeted indexes remove repeated scans while controlling write/storage cost?
*/
CREATE INDEX IF NOT EXISTS idx_order_items_order_id_cover ON order_items(order_id) INCLUDE(quantity,unit_price_at_sale);
CREATE INDEX IF NOT EXISTS idx_orders_business_dedup ON orders(order_id,loaded_at,order_row_id);
CREATE INDEX IF NOT EXISTS idx_orders_customer_date_completed ON orders(customer_id,order_date DESC) INCLUDE(order_id,region) WHERE status='completed';
CREATE INDEX IF NOT EXISTS idx_orders_date_status ON orders(order_date,status) INCLUDE(order_id,customer_id,region);
ANALYZE orders; ANALYZE order_items;
EXPLAIN (ANALYZE,BUFFERS,FORMAT TEXT)
SELECT o.order_id,o.customer_id,(SELECT sum(i.quantity*i.unit_price_at_sale) FROM order_items i WHERE i.order_id=o.order_id) order_value
FROM vw_orders_deduplicated o WHERE o.order_id<=1000;
/*
ACTUAL PLAN EXCERPT:
Bitmap Index Scan idx_orders_business_dedup: rows=1,004
Index Only Scan idx_order_items_order_id_cover: loops=1,000; Heap Fetches=0
Buffers: shared hit=3,804 read=15
Planning Time: 1.016 ms
Execution Time: 3.481 ms
So what: The covering index changed 1,000 full scans into tiny index-only probes: 13,560.194 ms to 3.481 ms (3,895x faster).
*/
