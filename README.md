# fake-ecommerce-return-analysis-system
End-to-end SQL + Power BI project analyzing e-commerce returns
# 📊 Fake E-Commerce Return Analysis System

## 📌 Project Overview

This project focuses on analyzing return behavior in an e-commerce environment using real-world transactional data. Product returns are a major challenge in online retail, impacting profitability, logistics, and customer satisfaction.

One key challenge in this dataset is the absence of a direct "return" indicator. To address this, a proxy-based approach was used:

> Orders delivered after the estimated delivery date are classified as returns.

This approach simulates real-world analytical scenarios where business logic must be derived from incomplete data.

---

## 🎯 Objectives

- Analyze patterns and trends in return behavior  
- Identify key factors influencing returns (delivery delays, shipping cost, etc.)  
- Detect high-risk products and customers  
- Generate actionable business insights to reduce return rates  

---

## 📁 Dataset Description

The project uses the Brazilian e-commerce dataset with approximately:

| Dataset | Records | Description |
|--------|--------|------------|
| Customers | ~99,000 | Customer details & location |
| Orders | ~99,000 | Order lifecycle & timestamps |
| Order Items | ~112,000 | Product-level details |

### Key Relationships:
- One customer → Multiple orders  
- One order → Multiple products  

---

## 🧱 Data Engineering (MySQL)

### 🔹 Database Setup
- Created structured tables for customers, orders, and items  
- Used appropriate data types (DATETIME, DECIMAL, VARCHAR)  

### 🔹 Data Import
- Imported CSV files using `LOAD DATA INFILE.`  
- Handled real-world issues:
  - File permission errors  
  - Date format inconsistencies  
  - MySQL import restrictions  

---

## 🔄 Data Transformation

### 🔗 Master Table Creation

A denormalized table `ecommerce_analysis` was created by joining:
- Orders dataset  
- Order items dataset  

This resulted in a flat structure where each row represents a product within an order.

---

## 🧠 Feature Engineering

### 🔥 Return Logic (Core Concept)

```sql
CASE 
WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1
ELSE 0
END AS is_return


---

### 🧠 Why This Dataset is Useful

This dataset provides a multi-dimensional view of the business, allowing analysis across:

- Customer behavior  
- Product performance  
- Delivery efficiency  
- Pricing and shipping  
- Geographic trends  

---

## 🧱 Data Engineering (MySQL)

### 🔹 Database Setup

The raw CSV data was imported into MySQL by creating structured tables for each dataset. Proper data types were assigned to ensure efficient storage and querying:

- `VARCHAR` for identifiers  
- `DATETIME` for timestamps  
- `DECIMAL` for price-related fields  

---

### 🔹 Data Import Challenges

During the import process, several real-world issues were encountered:

- File permission restrictions (`ERROR 1290`)
- Incorrect date formats (`ERROR 1292`)
- Disabled local file loading (`ERROR 2068`)
- Missing table references (`ERROR 1146`)

These were resolved by configuring MySQL settings, enabling local file imports, and properly formatting date fields.

---

## 🔄 Data Transformation

### 🔗 Master Table Creation

To simplify analysis and improve performance, a denormalized master table called `ecommerce_analysis` was created by joining:

- Orders dataset  
- Order items dataset  

This resulted in a flat structure where each row represents a product within an order.

---

### 📊 Example Structure

| order_id | customer_id | product_id | price | freight | delivered | estimated |
|----------|------------|-----------|------|--------|----------|----------|
| O1001 | C001 | P500 | 500 | 50 | Jan 5 | Jan 4 |

---

## 🧠 Feature Engineering

To enable meaningful analysis, new variables were created:

---

### 🔥 Return Flag (`is_return`)

```sql
CASE 
WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1
ELSE 0
END

Raw CSV Data
   ↓
MySQL (Storage & Cleaning)
   ↓
Data Transformation
   ↓
Feature Engineering
   ↓
SQL Analysis
   ↓
Power BI Dashboard
   ↓
Business Insights
