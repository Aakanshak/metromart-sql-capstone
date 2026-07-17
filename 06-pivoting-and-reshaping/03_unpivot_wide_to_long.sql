/*
Business question: How can a wide monthly target table be normalized for BI filtering and time-series analysis?
*/
WITH wide(region,jan_target,feb_target,mar_target) AS (
 VALUES ('North',100000::numeric,110000::numeric,125000::numeric),
        ('South',90000,95000,105000),('East',105000,108000,120000),('West',98000,102000,115000)
)
SELECT w.region,v.month_number,v.target FROM wide w
CROSS JOIN LATERAL (VALUES (1,w.jan_target),(2,w.feb_target),(3,w.mar_target)) v(month_number,target)
ORDER BY region,month_number;
/*
So what: LATERAL VALUES unpivots once without repeated table scans and produces a BI-friendly region-month grain.
*/
