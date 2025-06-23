
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
![image_alt](https://github.com/Jalpa-08/SQL_Project_Zepto_Analysis/blob/171a3cb6f5b1d9319a8a39861cee4e3827b84259/TDV_M184_02.jpg)
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

First 10 Records
``` sql 
SELECT * FROM zepto LIMIT 10;
 ```

Check Null Values in all columns
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

Average price before and after discount by category:
```sql SELECT 
    Category,
    AVG(mrp) AS avg_mrp,
    AVG(discountedSellingPrice) AS avg_discounted_price
FROM zepto
GROUP BY Category;
```

Products with more than 10% discount and still available
```sql SELECT name, discountPercent, availableQuantity 
FROM zepto
WHERE discountPercent > 10 AND outOfStock = FALSE;
```

Products with price = 0 /* Data Cleaning is Require */
```sql SELECT * FROM zepto
WHERE mrp = 0 OR discountedSellingPrice = 0;

DELETE FROM zepto
WHERE mrp = 0;
```

Total weight of all available stock (in kg)
```sql SELECT SUM(weightInGms * availableQuantity) / 1000.0 AS total_weight_kg
FROM zepto
WHERE outOfStock = FALSE;
```

Convert paise to rupees
```sql UPDATE zepto
SET mrp = mrp / 100.0,
discountedSellingPrice = discountedSellingPrice / 100.0;
```

Q1. Find the top 10 best-value products based on the discount percentage.
```sql SELECT DISTINCT name, mrp, discountPercent
FROM zepto
ORDER BY discountPercent DESC
LIMIT 10;
```

Q2.What are the Products with High MRP but Out of Stock
```sql SELECT DISTINCT name,mrp
FROM zepto
WHERE outOfStock = TRUE and mrp > 300
ORDER BY mrp DESC;
```

Q3.Calculate Estimated Revenue for each category
```sql SELECT category,
SUM(discountedSellingPrice * availableQuantity) AS total_revenue
FROM zepto
GROUP BY category
ORDER BY total_revenue;
```

Q4. Find all products where MRP is greater than ₹500 and discount is less than 10%.
```sql SELECT DISTINCT name, mrp, discountPercent
FROM zepto
WHERE mrp > 500 AND discountPercent < 10
ORDER BY mrp DESC, discountPercent DESC;
```

Q5. Identify the top 5 categories offering the highest average discount percentage.
```sql SELECT category,
ROUND(AVG(discountPercent),2) AS avg_discount
FROM zepto
GROUP BY category
ORDER BY avg_discount DESC
LIMIT 5;
```

Q6. Find the price per gram for products above 100g and sort by best value.
```sql SELECT DISTINCT name, weightInGms, discountedSellingPrice,
ROUND(discountedSellingPrice/weightInGms,2) AS price_per_gram
FROM zepto
WHERE weightInGms >= 100
ORDER BY price_per_gram;
```

Q7.Group the products into categories like Low, Medium, Bulk.
```sql SELECT DISTINCT name, weightInGms,
CASE WHEN weightInGms < 1000 THEN 'Low'
	WHEN weightInGms < 5000 THEN 'Medium'
	ELSE 'Bulk'
	END AS weight_category
FROM zepto;
```

Q8.What is the Total Inventory Weight Per Category 
```sql SELECT category,
SUM(weightInGms * availableQuantity) AS total_weight
FROM zepto
GROUP BY category
ORDER BY total_weight;
```

Q9.Find the top product in each category with the highest discount percentage
```sql SELECT zp.Category, zp.name, zp.discountPercent
FROM zepto zp
JOIN (
    SELECT Category, MAX(discountPercent) AS max_discount
    FROM zepto
    GROUP BY Category
) AS max_discounts
ON zp.Category = max_discounts.Category
AND zp.discountPercent = max_discounts.max_discount;
```

Q10. Calculate stock value loss due to discount per category
```sql SELECT 
    Category,
    SUM((mrp - discountedSellingPrice) * availableQuantity) / 100.0 AS total_discount_loss_rupees
FROM zepto
WHERE outOfStock = FALSE
GROUP BY Category
ORDER BY total_discount_loss_rupees DESC;
```

Q11.Use a window function to rank products by discount percentage within each category
```sql SELECT 
    Category, 
    name, 
    discountPercent,
    RANK() OVER (PARTITION BY Category ORDER BY discountPercent DESC) AS discount_rank
FROM zepto;
```

Q12. CTE: Show average discounted price and deviation of each product from category average
```sql WITH CategoryAverages AS (
    SELECT 
        Category, 
        AVG(discountedSellingPrice) AS avg_discount_price
    FROM zepto
    GROUP BY Category
)
SELECT 
    zp.Category,
    zp.name,
    zp.discountedSellingPrice,
    ca.avg_discount_price,
    zp.discountedSellingPrice - ca.avg_discount_price AS price_deviation
FROM zepto zp
JOIN CategoryAverages ca ON zp.Category = ca.Category;
```

Q13. Find the heaviest item (by weight × quantity) in stock
```sql
SELECT name, Category, weightInGms, availableQuantity,
       (weightInGms * availableQuantity) AS total_weight
FROM zepto
WHERE outOfStock = FALSE
ORDER BY total_weight DESC
LIMIT 1;
```

Q14. Show percent contribution of each product to its category's total available stock
```sql SELECT 
    name,
    Category,
    availableQuantity,
    ROUND(availableQuantity * 100.0 / 
        SUM(availableQuantity) OVER (PARTITION BY Category), 2) AS stock_percentage_in_category
FROM zepto;
```
```sql
/* -----------------------------------------------------------
   Stored Procedure: sp_category_inventory_summary
   -----------------------------------------------------------
   Returns, for every category that still has items in stock:
     • total_products            – how many distinct items
     • total_units_in_stock      – sum of availableQuantity
     • total_weight_kg           – physical weight in kilograms
     • total_mrp_value_rupees    – full-price value of all stock
     • total_sale_value_rupees   – value after discount
     • total_discount_loss_rupees– revenue reduction due to discount
   ----------------------------------------------------------- */
```

```sql DELIMITER $$
DROP PROCEDURE IF EXISTS sp_category_inventory_summary $$
CREATE PROCEDURE sp_category_inventory_summary()
BEGIN
    SELECT 
        Category,
        COUNT(*) AS total_products,
        SUM(availableQuantity) AS total_units_in_stock,
        ROUND(SUM(weightInGms * availableQuantity) / 1000, 2) AS total_weight_kg,
        ROUND(SUM(mrp * availableQuantity) / 100, 2) AS total_mrp_value_rupees,
        ROUND(SUM(discountedSellingPrice * availableQuantity) / 100, 2) AS total_sale_value_rupees,
        ROUND(SUM((mrp - discountedSellingPrice) * availableQuantity) / 100, 2) AS total_discount_loss_rupees
    FROM zepto
    WHERE outOfStock = FALSE                     -- ignore items that aren’t on the shelf
    GROUP BY Category
    ORDER BY total_discount_loss_rupees DESC;    -- biggest “loss” on top
END $$

DELIMITER ;
```

-- Call Store Procedure
```sql
CALL sp_category_inventory_summary();
```
