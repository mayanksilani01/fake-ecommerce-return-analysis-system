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
- Imported CSV files using `LOAD DATA INFILE`  
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
