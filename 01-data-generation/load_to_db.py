"""Create the schema, bulk-load CSVs, and fail fast on referential/data checks."""
import os
from pathlib import Path
import psycopg2
from psycopg2 import sql

HERE = Path(__file__).resolve().parent
DB = dict(dbname=os.getenv("POSTGRES_DB", "metromart_db"),
          user=os.getenv("POSTGRES_USER", "metromart_user"),
          password=os.getenv("POSTGRES_PASSWORD", "metromart_pass"),
          host=os.getenv("POSTGRES_HOST", "127.0.0.1"),
          port=os.getenv("POSTGRES_PORT", "5432"))
FILES = ["customers", "customer_addresses", "category_hierarchy", "products", "orders",
         "order_items", "inventory_online", "inventory_instore",
         "marketing_email_list", "marketing_sms_list"]


def main():
    with psycopg2.connect(**DB) as conn:
        with conn.cursor() as cur:
            cur.execute((HERE / "schema.sql").read_text(encoding="utf-8"))
            for table in FILES:
                print(f"Loading {table}...")
                with (HERE / f"{table}.csv").open("r", encoding="utf-8") as handle:
                    cols = handle.readline().strip().split(",")
                    statement = sql.SQL("COPY metromart.{} ({}) FROM STDIN WITH (FORMAT CSV, NULL '', HEADER FALSE)").format(
                        sql.Identifier(table), sql.SQL(",").join(map(sql.Identifier, cols)))
                    cur.copy_expert(statement.as_string(cur), handle)
            cur.execute("""
                SELECT count(*) FROM metromart.order_items i
                WHERE NOT EXISTS (SELECT 1 FROM metromart.orders o WHERE o.order_id=i.order_id)
            """)
            if cur.fetchone()[0]:
                raise RuntimeError("Orphan order_items detected")
            cur.execute("ANALYZE")
        conn.commit()
    print("Load and validation complete.")


if __name__ == "__main__":
    main()
