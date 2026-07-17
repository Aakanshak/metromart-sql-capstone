/*
Business question: What relational model preserves source-system defects while enforcing every safe business rule?
*/
CREATE EXTENSION IF NOT EXISTS tablefunc;
DROP SCHEMA IF EXISTS metromart CASCADE;
CREATE SCHEMA metromart;
SET search_path TO metromart, public;

CREATE TABLE customers (
  customer_id bigint PRIMARY KEY, name text NOT NULL, email text NOT NULL,
  region text NOT NULL CHECK (region IN ('North','South','East','West')),
  signup_date date NOT NULL
);
CREATE TABLE customer_addresses (
  address_version_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  customer_id bigint NOT NULL REFERENCES customers, address text NOT NULL,
  region text NOT NULL, effective_date date NOT NULL, end_date date,
  CHECK (end_date IS NULL OR end_date >= effective_date), UNIQUE(customer_id, effective_date)
);
CREATE TABLE category_hierarchy (
  category_id int PRIMARY KEY, category_name text UNIQUE NOT NULL,
  parent_category_id int REFERENCES category_hierarchy
);
CREATE TABLE products (
  product_id bigint PRIMARY KEY, product_name text NOT NULL, category text NOT NULL,
  subcategory text NOT NULL REFERENCES category_hierarchy(category_name),
  unit_price numeric(12,2) NOT NULL CHECK (unit_price > 0)
);
CREATE TABLE orders (
  order_row_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  order_id bigint NOT NULL, customer_id bigint NOT NULL REFERENCES customers,
  order_date date NOT NULL, channel text NOT NULL CHECK(channel IN ('online','in-store')),
  status text NOT NULL CHECK(status IN ('completed','returned','cancelled')),
  region text NOT NULL, loaded_at date NOT NULL
);
CREATE TABLE order_items (
  order_item_id bigint PRIMARY KEY, order_id bigint NOT NULL,
  product_id bigint NOT NULL REFERENCES products, quantity int NOT NULL CHECK(quantity > 0),
  unit_price_at_sale numeric(12,2) NOT NULL CHECK(unit_price_at_sale >= 0)
);
CREATE TABLE inventory_online (
  product_id bigint REFERENCES products, region text, stock_qty int CHECK(stock_qty >= 0),
  last_updated date, PRIMARY KEY(product_id, region)
);
CREATE TABLE inventory_instore (
  product_id bigint REFERENCES products, store_id int, region text,
  stock_qty int CHECK(stock_qty >= 0), last_updated date, PRIMARY KEY(product_id, store_id)
);
CREATE TABLE marketing_email_list (customer_id bigint, email text, campaign_source text NOT NULL);
CREATE TABLE marketing_sms_list (customer_id bigint, email text, campaign_source text NOT NULL);

-- Safe canonical layer: one header per business order. All analytics should use it.
CREATE VIEW vw_orders_deduplicated AS
SELECT order_id, customer_id, order_date, channel, status, region, loaded_at
FROM (
  SELECT o.*, row_number() OVER (PARTITION BY order_id ORDER BY loaded_at, order_row_id) AS rn
  FROM orders o
) x WHERE rn = 1;

COMMENT ON TABLE orders IS 'Raw source landing table. Duplicate order_id rows intentionally model a double-insert incident.';
COMMENT ON COLUMN order_items.order_id IS 'Logical order key; enforced by data-load validation rather than FK because raw orders intentionally duplicate it.';
/*
So what: A surrogate raw-row key preserves double inserts, while checks, dimension FKs, and a canonical view keep analytics trustworthy.
*/
