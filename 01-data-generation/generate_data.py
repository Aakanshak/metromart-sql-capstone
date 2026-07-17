"""Generate deterministic, deliberately messy MetroMart CSV data.

Python is used only to create source-system shaped data. All cleaning, analysis,
and reporting lives in PostgreSQL. Run from any directory with:
    python 01-data-generation/generate_data.py
"""
from __future__ import annotations

import csv
import json
import random
from collections import Counter, defaultdict
from datetime import date, timedelta
from pathlib import Path

import numpy as np
from faker import Faker

SEED = 20260717
NUM_CUSTOMERS = 12_000
NUM_PRODUCTS = 250
NUM_ORDERS = 200_000
NUM_STORES = 20
START_DATE = date(2023, 7, 1)
END_DATE = date(2026, 6, 30)
REGIONS = ["North", "South", "East", "West"]
BLACKOUT_DATES = {
    date(2023, 9, 12), date(2023, 9, 13), date(2024, 2, 29),
    date(2024, 8, 18), date(2024, 8, 19), date(2025, 3, 4),
    date(2025, 10, 21), date(2025, 10, 22), date(2026, 1, 15),
}
OUT = Path(__file__).resolve().parent
fake = Faker("en_US")
Faker.seed(SEED)
random.seed(SEED)
np.random.seed(SEED)

HIERARCHY = [
    (1, "Electronics", None), (2, "Computers", 1), (3, "Laptops", 2),
    (4, "Gaming Laptops", 3), (5, "Business Laptops", 3), (6, "Desktops", 2),
    (7, "Phones", 1), (8, "Smartphones", 7), (9, "Accessories", 1),
    (10, "Home", None), (11, "Kitchen", 10), (12, "Small Appliances", 11),
    (13, "Home Care", 10), (14, "Vacuums", 13), (15, "Clothing", None),
    (16, "Men", 15), (17, "Women", 15), (18, "Athleisure", 15),
]
LEAVES = [
    ("Gaming Laptop", "Electronics", "Gaming Laptops", 899, 2499),
    ("Business Laptop", "Electronics", "Business Laptops", 649, 1899),
    ("Desktop PC", "Electronics", "Desktops", 499, 1799),
    ("Smartphone", "Electronics", "Smartphones", 199, 1499),
    ("Wireless Headphones", "Electronics", "Accessories", 29, 399),
    ("Air Fryer", "Home", "Small Appliances", 49, 299),
    ("Blender", "Home", "Small Appliances", 25, 249),
    ("Vacuum", "Home", "Vacuums", 79, 699),
    ("Men's T-Shirt", "Clothing", "Men", 12, 89),
    ("Women's Dress", "Clothing", "Women", 25, 249),
    ("Athleisure Hoodie", "Clothing", "Athleisure", 30, 159),
]


def write_csv(name: str, header: list[str], rows: list[tuple]) -> None:
    with (OUT / name).open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(header)
        writer.writerows(rows)


def customers_and_addresses():
    customers, addresses, canonical = [], [], {}
    for customer_id in range(1, NUM_CUSTOMERS + 1):
        name = fake.name()
        local = f"{name.lower().replace(' ', '.').replace("'", '')}.{customer_id}"
        email = f"{local}@{random.choice(['gmail.com', 'outlook.com', 'yahoo.com'])}"
        if random.random() < .045:
            email = email.upper()
        region = random.choice(REGIONS)
        signup = START_DATE + timedelta(days=random.randrange((END_DATE - START_DATE).days + 1))
        customers.append((customer_id, name, email, region, signup))
        canonical[customer_id] = customer_id

        move_count = random.choices([0, 1, 2], [.70, .23, .07])[0]
        starts = [signup]
        for _ in range(move_count):
            remaining = (END_DATE - starts[-1]).days
            if remaining > 150:
                starts.append(starts[-1] + timedelta(days=random.randint(90, min(450, remaining))))
        for i, effective in enumerate(starts):
            end = starts[i + 1] if i + 1 < len(starts) else None
            # 2% of movers contain a realistic source-system coverage gap.
            if i > 0 and random.random() < .02:
                effective += timedelta(days=random.randint(2, 14))
            addresses.append((customer_id, fake.street_address(), random.choice(REGIONS), effective, end))

    # Near-duplicate CRM identities: new IDs, same person, casing/plus-alias variation.
    for source_id in random.sample(range(1, NUM_CUSTOMERS + 1), 240):
        original = customers[source_id - 1]
        new_id = len(customers) + 1
        email = original[2]
        email = email.replace("@", "+promo@") if random.random() < .55 else email.swapcase()
        name = original[1].upper() if random.random() < .5 else f" {original[1]} "
        customers.append((new_id, name, email, original[3], original[4]))
        canonical[new_id] = source_id
        addresses.append((new_id, fake.street_address(), original[3], original[4], None))
    return customers, addresses, canonical


def products():
    rows = []
    for product_id in range(1, NUM_PRODUCTS + 1):
        base, category, subcategory, low, high = LEAVES[(product_id - 1) % len(LEAVES)]
        price = round(float(np.exp(np.random.uniform(np.log(low), np.log(high)))), 2)
        rows.append((product_id, f"{base} {product_id:03d}", category, subcategory, price))
    return rows


def orders_and_items(customer_rows, product_rows):
    valid_dates = [START_DATE + timedelta(days=i) for i in range((END_DATE - START_DATE).days + 1)
                   if START_DATE + timedelta(days=i) not in BLACKOUT_DATES]
    customer_ids = [r[0] for r in customer_rows]
    orders, items = [], []
    item_id = 1
    prices = {r[0]: r[4] for r in product_rows}
    for order_id in range(1, NUM_ORDERS + 1):
        customer_id = random.choice(customer_ids)
        order_date = random.choice(valid_dates)
        channel = random.choices(["online", "in-store"], [.62, .38])[0]
        status = random.choices(["completed", "returned", "cancelled"], [.88, .08, .04])[0]
        region = random.choice(REGIONS)
        loaded_at = order_date + timedelta(days=random.randint(0, 2))
        orders.append((order_id, customer_id, order_date, channel, status, region, loaded_at))
        for _ in range(random.choices([1, 2, 3, 4], [.52, .31, .12, .05])[0]):
            pid = random.randint(1, NUM_PRODUCTS)
            sale_price = round(prices[pid] * random.uniform(.72, 1.05), 2)
            items.append((item_id, order_id, pid, random.choices([1, 2, 3, 4], [.72, .19, .07, .02])[0], sale_price))
            item_id += 1
    # Exact raw-header duplicates with distinct ingestion row IDs assigned by Postgres.
    duplicated_ids = random.sample(range(1, NUM_ORDERS + 1), 800)
    by_id = {r[0]: r for r in orders}
    orders.extend(by_id[x] for x in duplicated_ids)
    random.shuffle(orders)
    return orders, items, duplicated_ids


def inventory(product_rows):
    online, instore = [], []
    store_region = {store: REGIONS[(store - 1) % 4] for store in range(1, NUM_STORES + 1)}
    for pid, *_ in product_rows:
        for region in REGIONS:
            if (pid + REGIONS.index(region)) % 23 != 0:  # deterministic online-only gaps
                online.append((pid, region, random.randint(0, 220), END_DATE))
        for store, region in store_region.items():
            if (pid * 3 + store) % 19 != 0:  # different deterministic in-store gaps
                instore.append((pid, store, region, random.randint(0, 160), END_DATE))
    return online, instore


def marketing(customer_rows, canonical):
    email_rows, sms_rows = [], []
    for customer_id, _, email, _, _ in customer_rows:
        identity = canonical[customer_id]
        selector = identity % 10
        if selector in {0, 1, 2, 3, 4, 5}:  # 60%, includes overlap
            email_rows.append((customer_id if identity % 7 else None, email, random.choice(["welcome", "holiday", "loyalty"])))
        if selector in {3, 4, 5, 6, 7}:  # 50%; overlap=30%, email-only=30%, sms-only=20%
            sms_rows.append((customer_id if identity % 5 else None, email.lower(), random.choice(["flash_sale", "winback", "loyalty"])))
    return email_rows, sms_rows


def main() -> None:
    customer_rows, address_rows, canonical = customers_and_addresses()
    product_rows = products()
    order_rows, item_rows, duplicated_ids = orders_and_items(customer_rows, product_rows)
    online_rows, instore_rows = inventory(product_rows)
    email_rows, sms_rows = marketing(customer_rows, canonical)

    write_csv("customers.csv", ["customer_id", "name", "email", "region", "signup_date"], customer_rows)
    write_csv("customer_addresses.csv", ["customer_id", "address", "region", "effective_date", "end_date"], address_rows)
    write_csv("products.csv", ["product_id", "product_name", "category", "subcategory", "unit_price"], product_rows)
    write_csv("category_hierarchy.csv", ["category_id", "category_name", "parent_category_id"], HIERARCHY)
    write_csv("orders.csv", ["order_id", "customer_id", "order_date", "channel", "status", "region", "loaded_at"], order_rows)
    write_csv("order_items.csv", ["order_item_id", "order_id", "product_id", "quantity", "unit_price_at_sale"], item_rows)
    write_csv("inventory_online.csv", ["product_id", "region", "stock_qty", "last_updated"], online_rows)
    write_csv("inventory_instore.csv", ["product_id", "store_id", "region", "stock_qty", "last_updated"], instore_rows)
    write_csv("marketing_email_list.csv", ["customer_id", "email", "campaign_source"], email_rows)
    write_csv("marketing_sms_list.csv", ["customer_id", "email", "campaign_source"], sms_rows)

    email_keys = {((str(r[0]) if r[0] else ""), r[1].lower()) for r in email_rows}
    sms_keys = {((str(r[0]) if r[0] else ""), r[1].lower()) for r in sms_rows}
    report = {
        "seed": SEED, "date_range": [str(START_DATE), str(END_DATE)],
        "customers": len(customer_rows), "near_duplicate_customer_identities": 240,
        "address_rows": len(address_rows), "orders_raw_rows": len(order_rows),
        "unique_order_ids": NUM_ORDERS, "exact_duplicate_order_rows": len(duplicated_ids),
        "order_items": len(item_rows), "guaranteed_zero_order_dates": sorted(map(str, BLACKOUT_DATES)),
        "online_inventory_rows": len(online_rows), "instore_inventory_rows": len(instore_rows),
        "marketing_email_rows": len(email_rows), "marketing_sms_rows": len(sms_rows),
        "marketing_exact_identity_overlap": len(email_keys & sms_keys),
    }
    (OUT / "data_quality_report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
