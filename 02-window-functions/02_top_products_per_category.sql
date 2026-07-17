/*
Business question: Which products lead each category, and how do ranking rules behave when revenue ties?
*/
WITH product_sales AS (
 SELECT p.category,p.product_id,p.product_name,round(sum(i.quantity*i.unit_price_at_sale),-2) revenue
 FROM vw_orders_deduplicated o JOIN order_items i USING(order_id) JOIN products p USING(product_id)
 WHERE o.status='completed' GROUP BY 1,2,3
)
SELECT *, rank() OVER(PARTITION BY category ORDER BY revenue DESC) AS rank_with_gaps,
 dense_rank() OVER(PARTITION BY category ORDER BY revenue DESC) AS dense_rank_no_gaps,
 row_number() OVER(PARTITION BY category ORDER BY revenue DESC,product_id) AS deterministic_row_number
FROM product_sales ORDER BY category,revenue DESC,product_id;
/*
So what: RANK preserves ties for awards, DENSE_RANK creates compact tiers, and ROW_NUMBER guarantees exactly N products.
*/
