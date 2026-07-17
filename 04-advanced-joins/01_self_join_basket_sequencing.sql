/*
Business question: Which product pairs show customers buying A and then B within 30 days?
*/
WITH purchases AS (
 SELECT DISTINCT o.customer_id,o.order_id,o.order_date,i.product_id FROM vw_orders_deduplicated o
 JOIN order_items i USING(order_id) WHERE o.status='completed'
)
SELECT a.product_id product_a,b.product_id product_b,count(DISTINCT a.customer_id) customers
FROM purchases a JOIN purchases b ON b.customer_id=a.customer_id AND b.order_date>a.order_date
 AND b.order_date<=a.order_date+30 AND b.product_id<>a.product_id
GROUP BY 1,2 HAVING count(DISTINCT a.customer_id)>=10 ORDER BY customers DESC LIMIT 100;
/*
So what: Direction and time bounds turn simple co-occurrence into a cross-sell sequence that can inform triggered recommendations.
*/
