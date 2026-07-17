/*
Business question: What are each customer's three highest-value completed orders?
*/
SELECT c.customer_id,c.name,t.order_id,t.order_date,t.order_value
FROM customers c CROSS JOIN LATERAL (
 SELECT o.order_id,o.order_date,sum(i.quantity*i.unit_price_at_sale)::numeric(14,2) order_value
 FROM vw_orders_deduplicated o JOIN order_items i USING(order_id)
 WHERE o.customer_id=c.customer_id AND o.status='completed' GROUP BY 1,2
 ORDER BY order_value DESC,o.order_id LIMIT 3
) t ORDER BY c.customer_id,t.order_value DESC;
/*
So what: LATERAL expresses per-customer top-N cleanly and can exploit a customer/order index without ranking the entire fact table.
*/
