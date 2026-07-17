/*
Business question: Which customers belong to spend quartiles, and where do they sit on the full spend distribution?
*/
WITH spend AS (
 SELECT c.customer_id,c.name,coalesce(sum(i.quantity*i.unit_price_at_sale) FILTER(WHERE o.status='completed'),0) lifetime_spend
 FROM customers c LEFT JOIN vw_orders_deduplicated o USING(customer_id) LEFT JOIN order_items i USING(order_id) GROUP BY 1,2
)
SELECT *,ntile(4) OVER(ORDER BY lifetime_spend DESC,customer_id) spend_quartile,
 round(percent_rank() OVER(ORDER BY lifetime_spend)::numeric,4) spend_percent_rank
FROM spend ORDER BY lifetime_spend DESC,customer_id;
/*
So what: NTILE creates actionable campaign-sized segments while PERCENT_RANK preserves a customer's exact relative position.
*/
