-- =========================
-- 1. CREATE DATA WAREHOUSE
-- =========================
DROP DATABASE IF EXISTS dw_sales;
CREATE DATABASE dw_sales;
USE dw_sales;


-- =========================
-- 2. CREATE DIMENSION TABLES
-- =========================

CREATE TABLE dim_customer (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    phone VARCHAR(20),
    email VARCHAR(100),
    city VARCHAR(50),
    state VARCHAR(50),
    zip_code VARCHAR(10)
);

CREATE TABLE dim_brand (
    brand_id INT PRIMARY KEY,
    brand_name VARCHAR(100)
);

CREATE TABLE dim_category (
    category_id INT PRIMARY KEY,
    category_name VARCHAR(100)
);

CREATE TABLE dim_product (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(255),
    brand_id INT,
    category_id INT,
    model_year INT,
    list_price DECIMAL(10,2),
    FOREIGN KEY (brand_id) REFERENCES dim_brand(brand_id),
    FOREIGN KEY (category_id) REFERENCES dim_category(category_id)
);

CREATE TABLE dim_store (
    store_id INT PRIMARY KEY,
    store_name VARCHAR(100),
    phone VARCHAR(20),
    email VARCHAR(100),
    city VARCHAR(50),
    state VARCHAR(50),
    zip_code VARCHAR(10)
);

CREATE TABLE dim_staff (
    staff_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    phone VARCHAR(20),
    active INT,
    store_id INT
);


-- =========================
-- 3. LOAD DIMENSION DATA
-- =========================

INSERT INTO dim_customer
SELECT * FROM bicycle.customers;

INSERT INTO dim_brand
SELECT * FROM bicycle.brands;

INSERT INTO dim_category
SELECT * FROM bicycle.categories;

INSERT INTO dim_product
SELECT * FROM bicycle.products;

INSERT INTO dim_store
SELECT * FROM bicycle.stores;

INSERT INTO dim_staff
SELECT staff_id, first_name, last_name, email, phone, active, store_id
FROM bicycle.staffs;


-- =========================
-- 4. CREATE FACT TABLE
-- =========================

CREATE TABLE fact_sales (
    order_id INT,
    product_id INT,
    customer_id INT,
    staff_id INT,
    store_id INT,
    order_date DATETIME,
    quantity INT,
    list_price DECIMAL(10,2),
    discount DECIMAL(4,2),
    PRIMARY KEY (order_id, product_id),
    FOREIGN KEY (product_id) REFERENCES dim_product(product_id),
    FOREIGN KEY (customer_id) REFERENCES dim_customer(customer_id),
    FOREIGN KEY (staff_id) REFERENCES dim_staff(staff_id),
    FOREIGN KEY (store_id) REFERENCES dim_store(store_id)
);


-- =========================
-- 5. LOAD FACT DATA
-- =========================

INSERT INTO fact_sales (
    order_id,
    product_id,
    customer_id,
    staff_id,
    store_id,
    order_date,
    quantity,
    list_price,
    discount
)
SELECT
    oi.order_id,
    oi.product_id,
    o.customer_id,
    o.staff_id,
    o.store_id,
    o.order_date,
    oi.quantity,
    oi.list_price,
    oi.discount
FROM bicycle.order_items oi
JOIN bicycle.orders o
    ON oi.order_id = o.order_id;


-- =========================
-- 6. SAMPLE ANALYSIS QUERY
-- =========================

-- Total sales per brand
SELECT 
    b.brand_name,
    SUM(f.quantity * f.list_price * (1 - f.discount)) AS total_sales
FROM fact_sales f
JOIN dim_product p ON f.product_id = p.product_id
JOIN dim_brand b ON p.brand_id = b.brand_id
GROUP BY b.brand_name
ORDER BY total_sales DESC;

INSERT INTO dim_customer (
    customer_id,
    first_name,
    last_name,
    phone,
    email,
    city,
    state,
    zip_code
)
SELECT
    customer_id,
    first_name,
    last_name,
    phone,
    email,
    city,
    state,
    zip_code
FROM bicycle.customers;

SELECT COUNT(*) FROM dim_brand;
SELECT COUNT(*) FROM dim_category;
SELECT COUNT(*) FROM dim_product;
SELECT COUNT(*) FROM dim_store;
SELECT COUNT(*) FROM dim_staff;

SHOW TABLES;

CREATE TABLE fact_sales (
    order_id INT,
    product_id INT,
    customer_id INT,
    staff_id INT,
    store_id INT,
    order_date DATETIME,
    quantity INT,
    list_price DECIMAL(10,2),
    discount DECIMAL(4,2),
    PRIMARY KEY (order_id, product_id)
);

INSERT INTO fact_sales (
    order_id,
    product_id,
    customer_id,
    staff_id,
    store_id,
    order_date,
    quantity,
    list_price,
    discount
)
SELECT
    oi.order_id,
    oi.product_id,
    o.customer_id,
    o.staff_id,
    o.store_id,
    o.order_date,
    oi.quantity,
    oi.list_price,
    oi.discount
FROM bicycle.order_items oi
JOIN bicycle.orders o
    ON oi.order_id = o.order_id;

SELECT COUNT(*) FROM fact_sales;

INSERT INTO fact_sales (
    order_id,
    product_id,
    customer_id,
    staff_id,
    store_id,
    order_date,
    quantity,
    list_price,
    discount
)
SELECT
    oi.order_id,
    oi.product_id,
    o.customer_id,
    o.staff_id,
    o.store_id,
    STR_TO_DATE(o.order_date, '%m/%d/%Y'),
    oi.quantity,
    oi.list_price,
    oi.discount
FROM bicycle.order_items oi
JOIN bicycle.orders o
    ON oi.order_id = o.order_id;

SELECT 
    b.brand_name,
    SUM(f.quantity * f.list_price * (1 - f.discount)) AS total_sales
FROM fact_sales f
JOIN dim_product p ON f.product_id = p.product_id
JOIN dim_brand b ON p.brand_id = b.brand_id
GROUP BY b.brand_name
ORDER BY total_sales DESC;

SELECT 
    c.category_name,
    SUM(f.quantity * f.list_price * (1 - f.discount)) AS total_sales
FROM fact_sales f
JOIN dim_product p ON f.product_id = p.product_id
JOIN dim_category c ON p.category_id = c.category_id
GROUP BY c.category_name
ORDER BY total_sales DESC;

SELECT COUNT(*) FROM dim_product;

INSERT INTO dim_product (
    product_id,
    product_name,
    brand_id,
    category_id,
    model_year,
    list_price
)
SELECT
    product_id,
    product_name,
    brand_id,
    category_id,
    model_year,
    list_price
FROM bicycle.products;

SELECT 
    CONCAT(d.first_name, ' ', d.last_name) AS customer_name,
    SUM(f.quantity * f.list_price * (1 - f.discount)) AS total_spent
FROM fact_sales f
JOIN dim_customer d ON f.customer_id = d.customer_id
GROUP BY customer_name
ORDER BY total_spent DESC
LIMIT 10;

SELECT COUNT(*) FROM fact_sales f
JOIN dim_product p ON f.product_id = p.product_id;

TRUNCATE TABLE fact_sales;

SELECT COUNT(*) FROM dim_product;

INSERT INTO fact_sales (
    order_id,
    product_id,
    customer_id,
    staff_id,
    store_id,
    order_date,
    quantity,
    list_price,
    discount
)
SELECT
    oi.order_id,
    oi.product_id,
    o.customer_id,
    o.staff_id,
    o.store_id,
    STR_TO_DATE(o.order_date, '%m/%d/%Y'),
    oi.quantity,
    oi.list_price,
    oi.discount
FROM bicycle.order_items oi
JOIN bicycle.orders o
    ON oi.order_id = o.order_id;

SELECT COUNT(*)
FROM fact_sales f
JOIN dim_product p
ON f.product_id = p.product_id;

INSERT INTO dim_product (
    product_id,
    product_name,
    brand_id,
    category_id,
    model_year,
    list_price
)
SELECT
    product_id,
    product_name,
    brand_id,
    category_id,
    model_year,
    list_price
FROM bicycle.products;

SELECT COUNT(*) FROM dim_product;

SELECT COUNT(*)
FROM fact_sales f
JOIN dim_product p
ON f.product_id = p.product_id;

INSERT INTO dim_product (
    product_id,
    product_name,
    brand_id,
    category_id,
    model_year,
    list_price
)
SELECT
    product_id,
    product_name,
    brand_id,
    category_id,
    model_year,
    list_price
FROM bicycle.products;

SELECT COUNT(*) FROM dim_product;

SELECT COUNT(*) FROM dim_brand;
SELECT COUNT(*) FROM dim_category;

INSERT INTO dim_brand
SELECT brand_id, brand_name
FROM bicycle.brands;

SELECT COUNT(*) FROM dim_brand;

INSERT INTO dim_category
SELECT category_id, category_name
FROM bicycle.categories;

SELECT COUNT(*) FROM dim_category;

INSERT INTO dim_product (
    product_id,
    product_name,
    brand_id,
    category_id,
    model_year,
    list_price
)
SELECT
    product_id,
    product_name,
    brand_id,
    category_id,
    model_year,
    list_price
FROM bicycle.products;

TRUNCATE TABLE fact_sales;

INSERT INTO fact_sales (
    order_id,
    product_id,
    customer_id,
    staff_id,
    store_id,
    order_date,
    quantity,
    list_price,
    discount
)
SELECT
    oi.order_id,
    oi.product_id,
    o.customer_id,
    o.staff_id,
    o.store_id,
    STR_TO_DATE(o.order_date, '%m/%d/%Y'),
    oi.quantity,
    oi.list_price,
    oi.discount
FROM bicycle.order_items oi
JOIN bicycle.orders o
    ON oi.order_id = o.order_id;

SELECT COUNT(*)
FROM fact_sales f
JOIN dim_product p
ON f.product_id = p.product_id;

SELECT 
    b.brand_name,
    SUM(f.quantity * f.list_price * (1 - f.discount)) AS total_sales
FROM fact_sales f
JOIN dim_product p ON f.product_id = p.product_id
JOIN dim_brand b ON p.brand_id = b.brand_id
GROUP BY b.brand_name
ORDER BY total_sales DESC;

SELECT 
    c.category_name,
    SUM(f.quantity * f.list_price * (1 - f.discount)) AS total_sales
FROM fact_sales f
JOIN dim_product p ON f.product_id = p.product_id
JOIN dim_category c ON p.category_id = c.category_id
GROUP BY c.category_name
ORDER BY total_sales DESC;

SELECT 
    c.category_name,
    SUM(f.quantity * f.list_price * (1 - f.discount)) AS total_sales
FROM fact_sales f
JOIN dim_product p ON f.product_id = p.product_id
JOIN dim_category c ON p.category_id = c.category_id
GROUP BY c.category_name
ORDER BY total_sales DESC;

SELECT 
    c.category_name,
    SUM(f.quantity * f.list_price * (1 - f.discount)) AS total_sales
FROM fact_sales f
JOIN dim_product p ON f.product_id = p.product_id
JOIN dim_category c ON p.category_id = c.category_id
GROUP BY c.category_name
ORDER BY total_sales DESC
LIMIT 1;

SELECT 
    CONCAT(d.first_name, ' ', d.last_name) AS customer_name,
    SUM(f.quantity * f.list_price * (1 - f.discount)) AS total_spent
FROM fact_sales f
JOIN dim_customer d ON f.customer_id = d.customer_id
GROUP BY customer_name
ORDER BY total_spent DESC
LIMIT 10;



