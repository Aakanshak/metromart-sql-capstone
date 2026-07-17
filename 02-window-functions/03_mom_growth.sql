/*
Business question: How quickly is completed revenue growing month over month, and what is next month's value?
*/
WITH monthly AS (
 SELECT date_trunc('month',o.order_date)::date AS month_start,sum(i.quantity*i.unit_price_at_sale) revenue
 FROM vw_orders_deduplicated o JOIN order_items i USING(order_id) WHERE status='completed' GROUP BY 1
), x AS (
 SELECT *,lag(revenue) OVER(ORDER BY month_start) prior_revenue,lead(revenue) OVER(ORDER BY month_start) next_revenue FROM monthly
)
SELECT month_start,revenue::numeric(14,2),prior_revenue::numeric(14,2),next_revenue::numeric(14,2),
 round(100*(revenue-prior_revenue)/nullif(prior_revenue,0),2) mom_growth_pct FROM x ORDER BY month_start;
/*
So what: LAG makes trend inflections explicit; LEAD is included for forward-looking QA without a self-join.
*/
