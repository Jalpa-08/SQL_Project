
## Project Overview
### Project Title: Zepto analysis
### Level: Intermediate to Advanced 
### Database: zepto
 
This project presents a comprehensive analysis of a product inventory dataset from Zepto, an online grocery delivery platform. The dataset includes detailed information about various grocery items such as fruits, vegetables, dairy, and bakery products, focusing on their retail pricing, discounts, stock availability, and weights.

The main objective of this analysis is to derive actionable insights regarding:

📉 Discount strategies and their impact on potential revenue loss

📊 Stock distribution across categories and products

⚖️ Product weight and pricing efficiency

🔍 Identification of high-value and underperforming items

By leveraging SQL queries and stored procedures, this analysis simulates how business stakeholders (e.g., supply chain managers, pricing analysts, and inventory controllers) could monitor performance, detect revenue leaks due to heavy discounts, and prioritize restocking based on product metrics.
## 🎯 Objective
The primary objective of this project is to analyze product-level inventory and pricing data from Zepto to uncover meaningful insights that can inform better business decisions. Specifically, the analysis aims to:

Evaluate the impact of discounts on potential revenue and profit margins.

Assess stock availability across different product categories.

Identify high-value and underperforming products based on price, quantity, and discount metrics.

Analyze product weight and volume contributions to overall inventory.

Enable dynamic restocking decisions by identifying which products are out of stock or low in inventory.

Rank products within categories based on discount depth and sales value.

Develop reusable stored procedures to automate recurring inventory reports.

This data-driven approach can support supply chain optimization, pricing strategy refinement, and real-time business intelligence for online retail operations like Zepto.

## Project Structure
1. Database Setup
2. Database Creation: Created a database named zepto.
3. Table Creation

```sql
CREATE DATABASE ZEPTO;
USE ZEPTO;

CREATE TABLE IF NOT EXISTS ZEPTO (
category VARCHAR(120),
name VARCHAR(150) NOT NULL,
mrp INT(10),
discountPercent INT(10),
availableQuantity INT(10),
discountedSellingPrice INT(10),
weightInGms INT(10),
outOfStock VARCHAR(10),	
quantity INT(10)
);
```
4. Upload Data
```sql
LOAD DATA INFILE 'D:/zepto.csv'
INTO TABLE ZEPTO
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
```

-- First 10 Records
``` sql 
SELECT * FROM zepto LIMIT 10;
 ```

-- Check Null Values in all columns
```sql SELECT * FROM zepto
WHERE name IS NULL OR
category IS NULL OR
mrp IS NULL OR
discountPercent IS NULL OR
discountedSellingPrice IS NULL OR
weightInGms IS NULL OR
availableQuantity IS NULL OR
outOfStock IS NULL OR
quantity IS NULL;
```

-- Average price before and after discount by category:
```sql SELECT 
    Category,
    AVG(mrp) AS avg_mrp,
    AVG(discountedSellingPrice) AS avg_discounted_price
FROM zepto
GROUP BY Category;
```

-- Products with more than 10% discount and still available
```sql SELECT name, discountPercent, availableQuantity 
FROM zepto
WHERE discountPercent > 10 AND outOfStock = FALSE;
```

-- Products with price = 0 /* Data Cleaning is Require */
```sql SELECT * FROM zepto
WHERE mrp = 0 OR discountedSellingPrice = 0;

DELETE FROM zepto
WHERE mrp = 0;
```

-- Total weight of all available stock (in kg)
```sql SELECT SUM(weightInGms * availableQuantity) / 1000.0 AS total_weight_kg
FROM zepto
WHERE outOfStock = FALSE;
```

-- Convert paise to rupees
```sql UPDATE zepto
SET mrp = mrp / 100.0,
discountedSellingPrice = discountedSellingPrice / 100.0;
```
