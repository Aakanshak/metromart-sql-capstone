/*
Business question: Can consumers request a consistent revenue report for any valid date range?
*/
CREATE OR REPLACE FUNCTION fn_revenue_report(p_start_date date,p_end_date date)
RETURNS TABLE(month_start date,region text,category text,completed_orders bigint,revenue numeric,return_value numeric)
LANGUAGE plpgsql STABLE AS $$
BEGIN
 IF p_start_date IS NULL OR p_end_date IS NULL OR p_start_date>p_end_date THEN RAISE EXCEPTION 'Invalid date range'; END IF;
 RETURN QUERY SELECT date_trunc('month',o.order_date)::date,o.region,p.category,
 count(DISTINCT o.order_id) FILTER(WHERE o.status='completed'),
 coalesce(sum(i.quantity*i.unit_price_at_sale) FILTER(WHERE o.status='completed'),0),
 coalesce(sum(i.quantity*i.unit_price_at_sale) FILTER(WHERE o.status='returned'),0)
 FROM vw_orders_deduplicated o JOIN order_items i USING(order_id) JOIN products p USING(product_id)
 WHERE o.order_date BETWEEN p_start_date AND p_end_date GROUP BY 1,2,3 ORDER BY 1,2,3;
END $$;
/*
So what: A parameterized function creates one validated reporting contract while keeping date predicates visible to PostgreSQL.
*/
