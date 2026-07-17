"""Live PostgreSQL dashboard; analytical results are never pre-cached."""
import os
from datetime import date
import pandas as pd
import plotly.express as px
import psycopg2
import streamlit as st

st.set_page_config(page_title="MetroMart SQL Engine", page_icon="🛒", layout="wide")
st.title("MetroMart Retail Analytics Engine")
st.caption("Every visual executes parameterized SQL against PostgreSQL.")

@st.cache_resource
def connection():
    return psycopg2.connect(host=os.getenv("POSTGRES_HOST", "127.0.0.1"),
        port=os.getenv("POSTGRES_PORT", "5432"), dbname=os.getenv("POSTGRES_DB", "metromart_db"),
        user=os.getenv("POSTGRES_USER", "metromart_user"), password=os.getenv("POSTGRES_PASSWORD", "metromart_pass"))

def query(statement, params=None):
    conn = connection()
    try:
        return pd.read_sql_query(statement, conn, params=params)
    except Exception:
        conn.rollback()
        raise

with st.sidebar:
    st.header("Filters")
    start = st.date_input("Start", date(2023, 7, 1))
    end = st.date_input("End", date(2026, 6, 30))
    region = st.selectbox("Region", ["All", "North", "South", "East", "West"])
    category = st.selectbox("Category", ["All", "Electronics", "Home", "Clothing"])
params = {"start": start, "end": end, "region": region, "category": category}
predicate = """o.order_date BETWEEN %(start)s AND %(end)s
 AND (%(region)s='All' OR o.region=%(region)s)
 AND (%(category)s='All' OR p.category=%(category)s)"""
monthly = query("""SELECT date_trunc('month',o.order_date)::date month_start,
 sum(i.quantity*i.unit_price_at_sale)::numeric revenue,count(DISTINCT o.order_id) orders
 FROM metromart.vw_orders_deduplicated o JOIN metromart.order_items i USING(order_id)
 JOIN metromart.products p USING(product_id) WHERE o.status='completed' AND """ + predicate + " GROUP BY 1 ORDER BY 1", params)
c1, c2 = st.columns(2)
c1.metric("Revenue", f"${monthly.revenue.sum():,.0f}" if len(monthly) else "$0")
c2.metric("Completed orders", f"{monthly.orders.sum():,.0f}" if len(monthly) else "0")
st.plotly_chart(px.line(monthly, x="month_start", y="revenue", markers=True, title="Monthly completed revenue"), use_container_width=True)

tab1, tab2, tab3 = st.tabs(["Top products", "Cohort retention", "Hierarchy rollup"])
with tab1:
    top = query("""WITH s AS (SELECT p.category,p.product_name,sum(i.quantity*i.unit_price_at_sale) revenue,
      row_number() OVER(PARTITION BY p.category ORDER BY sum(i.quantity*i.unit_price_at_sale) DESC) rn
      FROM metromart.vw_orders_deduplicated o JOIN metromart.order_items i USING(order_id)
      JOIN metromart.products p USING(product_id) WHERE o.status='completed' AND """ + predicate +
      " GROUP BY 1,2) SELECT * FROM s WHERE rn<=5 ORDER BY category,rn", params)
    st.dataframe(top, use_container_width=True, hide_index=True)
with tab2:
    cohort = query("""WITH a AS (SELECT DISTINCT c.customer_id,date_trunc('month',c.signup_date)::date cohort,
      date_trunc('month',o.order_date)::date activity FROM metromart.customers c
      JOIN metromart.vw_orders_deduplicated o USING(customer_id) WHERE o.status='completed' AND o.order_date>=c.signup_date),
      r AS (SELECT cohort,(extract(year FROM age(activity,cohort))*12+extract(month FROM age(activity,cohort)))::int month_no,
      count(DISTINCT customer_id) retained FROM a GROUP BY 1,2), s AS
      (SELECT date_trunc('month',signup_date)::date cohort,count(*) size FROM metromart.customers GROUP BY 1)
      SELECT r.cohort,r.month_no,round(100.0*r.retained/s.size,2) retention_pct FROM r JOIN s USING(cohort)
      WHERE r.month_no<=12 ORDER BY 1,2""")
    st.dataframe(cohort, use_container_width=True, hide_index=True)
with tab3:
    rollup = query("""WITH RECURSIVE leaf AS (SELECT p.subcategory leaf,sum(i.quantity*i.unit_price_at_sale) revenue
      FROM metromart.vw_orders_deduplicated o JOIN metromart.order_items i USING(order_id)
      JOIN metromart.products p USING(product_id) WHERE o.status='completed' AND """ + predicate + """ GROUP BY 1),
      climb AS (SELECT h.category_id,h.category_name,h.parent_category_id,l.revenue
      FROM metromart.category_hierarchy h JOIN leaf l ON l.leaf=h.category_name UNION ALL
      SELECT p.category_id,p.category_name,p.parent_category_id,c.revenue FROM climb c
      JOIN metromart.category_hierarchy p ON p.category_id=c.parent_category_id)
      SELECT category_name,sum(revenue)::numeric revenue FROM climb GROUP BY 1 ORDER BY 2 DESC""", params)
    st.dataframe(rollup, use_container_width=True, hide_index=True)
