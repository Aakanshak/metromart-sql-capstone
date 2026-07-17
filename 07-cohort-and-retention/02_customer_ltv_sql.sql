/*
Business question: What realized net lifetime value and purchase cadence does each customer have?
*/
SELECT c.customer_id,c.name,min(o.order_date) first_order,max(o.order_date) latest_order,
 count(DISTINCT o.order_id) FILTER(WHERE o.status='completed') completed_orders,
 (coalesce(sum(i.quantity*i.unit_price_at_sale) FILTER(WHERE o.status='completed'),0)
 -coalesce(sum(i.quantity*i.unit_price_at_sale) FILTER(WHERE o.status='returned'),0))::numeric(14,2) realized_net_ltv,
 round(coalesce(sum(i.quantity*i.unit_price_at_sale) FILTER(WHERE o.status='completed'),0)
 /nullif(count(DISTINCT o.order_id) FILTER(WHERE o.status='completed'),0),2) avg_completed_order_value
FROM customers c LEFT JOIN vw_orders_deduplicated o USING(customer_id) LEFT JOIN order_items i USING(order_id)
GROUP BY 1,2 ORDER BY realized_net_ltv DESC;
/*
So what: Separating completed value from returns gives acquisition teams a realized, auditable LTV rather than gross sales.
*/
