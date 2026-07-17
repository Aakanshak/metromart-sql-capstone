/*
Business question: What share of signup cohorts return in each month after signup?
*/
WITH activity AS (
 SELECT DISTINCT c.customer_id,date_trunc('month',c.signup_date)::date cohort_month,
 date_trunc('month',o.order_date)::date activity_month
 FROM customers c JOIN vw_orders_deduplicated o USING(customer_id)
 WHERE o.status='completed' AND o.order_date>=c.signup_date
), retained AS (
 SELECT cohort_month,
 ((extract(year FROM age(activity_month,cohort_month))*12)+extract(month FROM age(activity_month,cohort_month)))::int month_number,
 count(DISTINCT customer_id) retained_customers FROM activity GROUP BY 1,2
), sizes AS (
 SELECT date_trunc('month',signup_date)::date cohort_month,count(*) cohort_size FROM customers GROUP BY 1
)
SELECT r.cohort_month,r.month_number,s.cohort_size,r.retained_customers,
 round(100.0*r.retained_customers/nullif(s.cohort_size,0),2) retention_pct
FROM retained r JOIN sizes s USING(cohort_month) ORDER BY 1,2;
/*
So what: Cohort-relative month bucketing separates lifecycle retention from calendar seasonality and avoids pandas entirely.
*/
