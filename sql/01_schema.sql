-- Olist Delivery Performance — Schema
-- SQLite dialect. Dates stored as ISO TEXT.

CREATE TABLE orders (
    order_id                     TEXT PRIMARY KEY,
    customer_id                  TEXT NOT NULL,
    order_status                 TEXT NOT NULL,
    order_purchase_timestamp     TEXT NOT NULL,
    order_approved_at            TEXT,
    order_delivered_carrier_date TEXT,
    order_delivered_customer_date TEXT,
    order_estimated_delivery_date TEXT NOT NULL,
    sequence_anomaly             INTEGER NOT NULL,
    sequence_anomaly_severe      INTEGER NOT NULL,
    impossible_delivery          INTEGER NOT NULL,
    migration_artifact           INTEGER NOT NULL,
    approval_days                REAL,
    handoff_days                 REAL,
    last_mile_days               REAL,
    delivery_days                REAL,
    lateness_days                REAL,
    is_late                      INTEGER
);

CREATE TABLE customers (
    customer_id              TEXT PRIMARY KEY,
    customer_unique_id       TEXT NOT NULL,
    customer_zip_code_prefix TEXT,
    customer_city            TEXT,
    customer_state           TEXT
);

CREATE TABLE order_items (
    order_id           TEXT NOT NULL,
    order_item_id      REAL NOT NULL,
    product_id         TEXT NOT NULL,
    seller_id          TEXT NOT NULL,
    shipping_limit_date TEXT,
    price              REAL NOT NULL,
    freight_value      REAL NOT NULL,
    PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE order_reviews (
    review_id              TEXT NOT NULL,
    order_id               TEXT PRIMARY KEY,
    review_score           REAL NOT NULL,
    review_comment_title   TEXT,
    review_comment_message TEXT,
    review_creation_date   TEXT,
    review_answer_timestamp TEXT
);

CREATE TABLE products (
    product_id               TEXT PRIMARY KEY,
    product_category_name    TEXT,
    product_name_lenght      REAL,
    product_description_lenght REAL,
    product_photos_qty       REAL,
    product_weight_g         REAL,
    product_length_cm        REAL,
    product_height_cm        REAL,
    product_width_cm         REAL
);

CREATE TABLE sellers (
    seller_id              TEXT PRIMARY KEY,
    seller_zip_code_prefix TEXT,
    seller_city            TEXT,
    seller_state           TEXT
);

CREATE TABLE category_translation (
    product_category_name         TEXT PRIMARY KEY,
    product_category_name_english TEXT
);
