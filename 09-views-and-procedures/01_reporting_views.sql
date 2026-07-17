/*
Business question: Which reusable semantic layers should reporting tools query consistently?
*/
CREATE OR REPLACE VIEW vw_monthly_revenue_by_category AS
SELECT date_trunc('month',o.order_date)::date AS month_start,o.region,p.category,
 sum(i.quantity*i.unit_price_at_sale)::numeric(16,2) revenue,count(DISTINCT o.order_id) orders
FROM vw_orders_deduplicated o JOIN order_items i USING(order_id) JOIN products p USING(product_id)
WHERE o.status='completed' GROUP BY 1,2,3;
CREATE OR REPLACE VIEW vw_customer_summary AS
SELECT c.customer_id,c.name,c.region,c.signup_date,count(DISTINCT o.order_id) FILTER(WHERE o.status='completed') completed_orders,
 coalesce(sum(i.quantity*i.unit_price_at_sale) FILTER(WHERE o.status='completed'),0)::numeric(16,2) lifetime_revenue
FROM customers c LEFT JOIN vw_orders_deduplicated o USING(customer_id) LEFT JOIN order_items i USING(order_id) GROUP BY 1,2,3,4;
/*
So what: Views centralize deduplication and metric definitions, preventing dashboard teams from creating inconsistent revenue logic.
*/
