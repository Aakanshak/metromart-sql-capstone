/*
Business question: Which customers spend more than the average customer in their home region?
*/
WITH customer_spend AS (
 SELECT c.customer_id,c.name,c.region,coalesce(sum(i.quantity*i.unit_price_at_sale) FILTER(WHERE o.status='completed'),0) spend
 FROM customers c LEFT JOIN vw_orders_deduplicated o USING(customer_id) LEFT JOIN order_items i USING(order_id) GROUP BY 1,2,3
)
SELECT cs.* FROM customer_spend cs WHERE cs.spend>(
 SELECT avg(peer.spend) FROM customer_spend peer WHERE peer.region=cs.region
) ORDER BY region,spend DESC;
/*
So what: The correlated condition benchmarks customers against comparable regional peers instead of a potentially misleading national average.
*/
