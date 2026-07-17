# Data quality

Raw orders preserve 800 duplicate headers for investigation; ROW_NUMBER chooses deterministic survivors. Address history uses half-open effective intervals and intentionally includes a small number of coverage gaps. COALESCE supplies reporting defaults while NULLIF protects ratios without disguising missingness.
