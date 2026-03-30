-- creating a database "ecommerce_analysis"
CREATE DATABASE ecommerce_analysis;
USE ecommerce_analysis;

-- creating table "olist_customers_dataset" , this table shows Customer profiles and location data
CREATE TABLE olist_customers_dataset (
    customer_id VARCHAR(50),
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state VARCHAR(10)
);

-- creating table "olist_orders_dataset" , this table shows Order information including purchase dates, delivery estimates, and order statuses
CREATE TABLE olist_orders_dataset (
    order_id VARCHAR(50),
    customer_id VARCHAR(50),
    order_status VARCHAR(20),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME
);

-- creating table "olist_orders_dataset" , this table shows Line-item details for each order, including product ID, price, and shipping cost
CREATE TABLE olist_order_items_dataset (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date DATETIME,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2)
);

-- the only folder where MySQL allows file import/export.
SHOW VARIABLES LIKE 'secure_file_priv';

-- turns ON permission to import CSV files from your own computer.
SET GLOBAL local_infile = 1;

-- load external data from CSV file in to the SQL table "olist_orders_dataset"
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_orders_dataset.csv'
INTO TABLE olist_orders_dataset
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id,
 customer_id,
 order_status,
 @order_purchase_timestamp,
 @order_approved_at,
 @order_delivered_carrier_date,
 @order_delivered_customer_date,
 @order_estimated_delivery_date)
SET
order_purchase_timestamp = STR_TO_DATE(NULLIF(@order_purchase_timestamp,''), '%Y-%m-%d %H:%i:%s'),
order_approved_at = STR_TO_DATE(NULLIF(@order_approved_at,''), '%Y-%m-%d %H:%i:%s'),
order_delivered_carrier_date = STR_TO_DATE(NULLIF(@order_delivered_carrier_date,''), '%Y-%m-%d %H:%i:%s'),
order_delivered_customer_date = STR_TO_DATE(NULLIF(@order_delivered_customer_date,''), '%Y-%m-%d %H:%i:%s'),
order_estimated_delivery_date = STR_TO_DATE(NULLIF(@order_estimated_delivery_date,''), '%Y-%m-%d %H:%i:%s');

-- load external data from CSV file in to the SQL table "olist_order_items_dataset"
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_order_items_dataset.csv'
INTO TABLE olist_order_items_dataset
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id,
 order_item_id,
 product_id,
 seller_id,
 @shipping_limit_date,
 price,
 freight_value)
SET
shipping_limit_date = STR_TO_DATE(NULLIF(@shipping_limit_date,''), '%Y-%m-%d %H:%i:%s');

-- load external data from CSV file in to the SQL table "olist_customers_dataset"
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_customers_dataset.csv'
INTO TABLE olist_customers_dataset
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(customer_id,
 customer_unique_id,
 customer_zip_code_prefix,
 customer_city,
 customer_state);
 
-- Create Master Analysis Table
CREATE TABLE ecommerce_analysis AS
SELECT 
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    oi.product_id,
    oi.price,
    oi.freight_value
FROM olist_orders_dataset o
JOIN olist_order_items_dataset oi 
ON o.order_id = oi.order_id;

-- Create Return Logic (CORE PART): shows Late delivery → treated as return
CREATE TABLE returns_analysis AS
SELECT *,
    CASE 
        WHEN order_delivered_customer_date > order_estimated_delivery_date 
            THEN 1 
        ELSE 0 
    END AS is_return
FROM ecommerce_analysis;

-- Key Analysis Queries (IMPORTANT) -> main project outputs
-- 1. Overall Return Rate
SELECT 
    COUNT(CASE WHEN is_return = 1 THEN 1 END) * 100.0 / COUNT(*) AS return_rate
FROM returns_analysis;

-- 2. Top Products with Highest Returns
SELECT 
    product_id,
    COUNT(*) AS total_orders,
    SUM(is_return) AS total_returns,
    SUM(is_return) * 100.0 / COUNT(*) AS return_rate
FROM returns_analysis
GROUP BY product_id
ORDER BY return_rate DESC
LIMIT 10;

--  3. Delivery Delay Impact
SELECT 
    AVG(DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date)) AS avg_delay
FROM returns_analysis
WHERE is_return = 1;

-- 4. High Return Customers
SELECT 
    customer_id,
    COUNT(*) AS total_orders,
    SUM(is_return) AS total_returns
FROM returns_analysis
GROUP BY customer_id
HAVING total_returns > 5
ORDER BY total_returns DESC;

-- 5. Shipping Cost vs Returns
SELECT 
    CASE 
        WHEN freight_value < 50 THEN 'Low'
        WHEN freight_value BETWEEN 50 AND 100 THEN 'Medium'
        ELSE 'High'
    END AS shipping_category,
    COUNT(*) AS total_orders,
    SUM(is_return) AS returns
FROM returns_analysis
GROUP BY shipping_category;

-- CTE Version (No Master Table Needed)
WITH ecommerce_data AS (
    SELECT 
        o.order_id,
        o.customer_id,
        o.order_purchase_timestamp,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,
        oi.product_id,
        oi.price,
        oi.freight_value
    FROM olist_orders_dataset o
    JOIN olist_order_items_dataset oi 
    ON o.order_id = oi.order_id
),
returns_data AS (
    SELECT *,
        CASE 
            WHEN order_delivered_customer_date > order_estimated_delivery_date 
                THEN 1 
            ELSE 0 
        END AS is_return
    FROM ecommerce_data
)

SELECT * FROM returns_data;

WITH returns_data AS (
    SELECT 
        oi.product_id,
        CASE 
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date 
                THEN 1 ELSE 0 
        END AS is_return
    FROM olist_orders_dataset o
    JOIN olist_order_items_dataset oi 
    ON o.order_id = oi.order_id
)

-- Top Products (with Ranking)
SELECT 
    product_id,
    SUM(is_return) AS total_returns,
    RANK() OVER (ORDER BY SUM(is_return) DESC) AS product_rank
FROM returns_data
GROUP BY product_id;

WITH returns_data AS (
    SELECT 
        o.customer_id,
        CASE 
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date 
                THEN 1 ELSE 0 
        END AS is_return
    FROM olist_orders_dataset o
)

-- Customer Segmentation
SELECT 
    customer_id,
    COUNT(*) AS total_orders,
    SUM(is_return) AS total_returns,
    CASE 
        WHEN SUM(is_return) >= 5 THEN 'High Risk'
        WHEN SUM(is_return) >= 2 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS customer_segment
FROM returns_data
GROUP BY customer_id;

WITH returns_data AS (
    SELECT 
        DATE(order_purchase_timestamp) AS order_date,
        CASE 
            WHEN order_delivered_customer_date > order_estimated_delivery_date 
                THEN 1 ELSE 0 
        END AS is_return
    FROM olist_orders_dataset
)

-- Running Return Rate (Trend Analysis)
SELECT 
    order_date,
    AVG(is_return) OVER (ORDER BY order_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) 
    AS cumulative_return_rate
FROM returns_data;

WITH returns_data AS (
    SELECT 
        oi.freight_value,
        CASE 
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date 
                THEN 1 ELSE 0 
        END AS is_return
    FROM olist_orders_dataset o
    JOIN olist_order_items_dataset oi 
    ON o.order_id = oi.order_id
)

-- Shipping Cost Impact (Bucket + %)
SELECT 
    CASE 
        WHEN freight_value < 50 THEN 'Low'
        WHEN freight_value BETWEEN 50 AND 100 THEN 'Medium'
        ELSE 'High'
    END AS shipping_category,
    COUNT(*) AS total_orders,
    SUM(is_return) AS returns,
    ROUND(SUM(is_return)*100.0/COUNT(*),2) AS return_rate
FROM returns_data
GROUP BY shipping_category;

-- Creates a view "return_summary"
CREATE VIEW return_summary AS
SELECT 
    oi.product_id,
    COUNT(*) AS total_orders,
    SUM(
        CASE 
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date 
                THEN 1 ELSE 0 
        END
    ) AS total_returns
FROM olist_orders_dataset o
JOIN olist_order_items_dataset oi 
ON o.order_id = oi.order_id
GROUP BY oi.product_id;

SELECT * FROM return_summary;

DELIMITER //

-- creates a stored procedure "get_high_return_products" to automates analysis
CREATE PROCEDURE get_high_return_products()
BEGIN
    SELECT 
        product_id,
        SUM(
            CASE 
                WHEN order_delivered_customer_date > order_estimated_delivery_date 
                    THEN 1 ELSE 0 
            END
        ) AS total_returns
    FROM olist_orders_dataset o
    JOIN olist_order_items_dataset oi 
    ON o.order_id = oi.order_id
    GROUP BY product_id
    ORDER BY total_returns DESC
    LIMIT 10;
END //

DELIMITER ;

CALL get_high_return_products();

-- creates triggers to Auto-update something when data changes
CREATE TRIGGER before_insert_order
BEFORE INSERT ON olist_orders_dataset
FOR EACH ROW
SET NEW.order_status = LOWER(NEW.order_status);

-- creates a function for reusable logic 
DELIMITER //

CREATE FUNCTION get_return_flag(delivered DATETIME, estimated DATETIME)
RETURNS INT
DETERMINISTIC
BEGIN
    RETURN CASE 
        WHEN delivered > estimated THEN 1
        ELSE 0
    END;
END //

DELIMITER ;

SELECT get_return_flag(order_delivered_customer_date, order_estimated_delivery_date)
FROM olist_orders_dataset;
