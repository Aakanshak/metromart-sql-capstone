/*
Business question: Can PostgreSQL crosstab produce the same monthly category matrix for a dynamic pivot workflow?
*/
SELECT * FROM crosstab(
 $$SELECT to_char(date_trunc('month',o.order_date),'YYYY-MM') AS month_key,p.category,
          sum(i.quantity*i.unit_price_at_sale)::numeric
   FROM metromart.vw_orders_deduplicated o JOIN metromart.order_items i USING(order_id)
   JOIN metromart.products p USING(product_id) WHERE o.status='completed'
   GROUP BY 1,2 ORDER BY 1,2$$,
 $$VALUES ('Clothing'),('Electronics'),('Home')$$
) AS ct(month_key text,clothing numeric,electronics numeric,home numeric);
/*
So what: crosstab is concise for many columns but requires a fixed output signature; manual FILTER is safer when schema transparency matters.
*/
