CREATE SCHEMA IF NOT EXISTS staging;

-- stg_orders
DROP TABLE IF EXISTS staging.stg_orders;
CREATE TABLE staging.stg_orders AS
SELECT
    order_id,
    customer_id,
    LOWER(TRIM(order_status))                              AS order_status,
    NULLIF(order_purchase_timestamp,      '')::timestamp  AS purchased_at,
    NULLIF(order_approved_at,             '')::timestamp  AS approved_at,
    NULLIF(order_delivered_carrier_date,  '')::timestamp  AS delivered_carrier_at,
    NULLIF(order_delivered_customer_date, '')::timestamp  AS delivered_customer_at,
    NULLIF(order_estimated_delivery_date, '')::timestamp  AS estimated_delivery_at
FROM raw.orders
WHERE order_id IS NOT NULL;

-- stg_order_items
DROP TABLE IF EXISTS staging.stg_order_items;
CREATE TABLE staging.stg_order_items AS
SELECT
    order_id,
    NULLIF(order_item_id, '')::int            AS order_item_id,
    product_id,
    seller_id,
    NULLIF(shipping_limit_date, '')::timestamp AS shipping_limit_at,
    NULLIF(price,         '')::numeric(12,2)   AS price,
    NULLIF(freight_value, '')::numeric(12,2)   AS freight_value
FROM raw.order_items
WHERE order_id IS NOT NULL;

-- stg_order_reviews
-- Olist trae review_id repetidos; 
DROP TABLE IF EXISTS staging.stg_order_reviews;
CREATE TABLE staging.stg_order_reviews AS
WITH ranked AS (
    SELECT
        review_id,
        order_id,
        NULLIF(review_score, '')::int                  AS review_score,
        NULLIF(review_creation_date, '')::timestamp    AS review_created_at,
        NULLIF(review_answer_timestamp, '')::timestamp AS review_answered_at,
        ROW_NUMBER() OVER (
            PARTITION BY review_id
            ORDER BY NULLIF(review_answer_timestamp, '')::timestamp DESC NULLS LAST
        ) AS rn
    FROM raw.order_reviews
    WHERE review_id IS NOT NULL
)
SELECT review_id, order_id, review_score, review_created_at, review_answered_at
FROM ranked
WHERE rn = 1;

-- stg_order_payments
DROP TABLE IF EXISTS staging.stg_order_payments;
CREATE TABLE staging.stg_order_payments AS
SELECT
    order_id,
    NULLIF(payment_sequential,   '')::int          AS payment_sequential,
    LOWER(TRIM(payment_type))                       AS payment_type,
    NULLIF(payment_installments, '')::int          AS payment_installments,
    NULLIF(payment_value,        '')::numeric(12,2) AS payment_value
FROM raw.order_payments
WHERE order_id IS NOT NULL;

-- stg_products
DROP TABLE IF EXISTS staging.stg_products;
CREATE TABLE staging.stg_products AS
SELECT
    p.product_id,
    NULLIF(TRIM(p.product_category_name), '')                    AS category_pt,
    COALESCE(t.product_category_name_english,
             NULLIF(TRIM(p.product_category_name), ''),
             'unknown')                                          AS category_en,
    NULLIF(p.product_weight_g, '')::numeric  AS product_weight_g,
    NULLIF(p.product_length_cm, '')::numeric AS product_length_cm,
    NULLIF(p.product_height_cm, '')::numeric AS product_height_cm,
    NULLIF(p.product_width_cm, '')::numeric  AS product_width_cm
FROM raw.products p
LEFT JOIN raw.product_category_translation t
       ON t.product_category_name = p.product_category_name;

-- stg_customers
DROP TABLE IF EXISTS staging.stg_customers;
CREATE TABLE staging.stg_customers AS
SELECT
    customer_id,
    customer_unique_id,
    NULLIF(TRIM(customer_zip_code_prefix), '') AS zip_code_prefix,
    LOWER(TRIM(customer_city))                  AS city,
    UPPER(TRIM(customer_state))                 AS state
FROM raw.customers
WHERE customer_id IS NOT NULL;

-- stg_sellers
DROP TABLE IF EXISTS staging.stg_sellers;
CREATE TABLE staging.stg_sellers AS
SELECT
    seller_id,
    NULLIF(TRIM(seller_zip_code_prefix), '') AS zip_code_prefix,
    LOWER(TRIM(seller_city))                  AS city,
    UPPER(TRIM(seller_state))                 AS state
FROM raw.sellers
WHERE seller_id IS NOT NULL;
