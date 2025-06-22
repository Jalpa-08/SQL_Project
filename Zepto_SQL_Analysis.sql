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

DROP TABLE ZEPTO;

LOAD DATA INFILE 'D:/zepto.csv'
INTO TABLE ZEPTO
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM ZEPTO;

-- Count Number of Records
SELECT COUNT(*) FROM ZEPTO;

-- First 10 Records
SELECT * FROM zepto LIMIT 10;

-- Check Null Values in all columns
SELECT * FROM zepto
WHERE name IS NULL OR
category IS NULL OR
mrp IS NULL OR
discountPercent IS NULL OR
discountedSellingPrice IS NULL OR
weightInGms IS NULL OR
availableQuantity IS NULL OR
outOfStock IS NULL OR
quantity IS NULL;

-- Find out different product categories
SELECT DISTINCT category
FROM zepto
ORDER BY category;

-- List all out-of-stock products:
SELECT name, Category FROM zepto
WHERE outOfStock = TRUE;

SELECT name, Category FROM zepto
WHERE outOfStock = False;

-- Top 5 products with highest discount
SELECT name, discountPercent FROM zepto
ORDER BY discountPercent DESC
LIMIT 5;

-- Average price before and after discount by category:
SELECT 
    Category,
    AVG(mrp) AS avg_mrp,
    AVG(discountedSellingPrice) AS avg_discounted_price
FROM zepto
GROUP BY Category;

-- Products with more than 10% discount and still available
SELECT name, discountPercent, availableQuantity 
FROM zepto
WHERE discountPercent > 10 AND outOfStock = FALSE;

-- Products with price = 0 /* Data Cleaning is Require */
SELECT * FROM zepto
WHERE mrp = 0 OR discountedSellingPrice = 0;

DELETE FROM zepto
WHERE mrp = 0;

-- Total weight of all available stock (in kg)
SELECT SUM(weightInGms * availableQuantity) / 1000.0 AS total_weight_kg
FROM zepto
WHERE outOfStock = FALSE;

-- Convert paise to rupees
UPDATE zepto
SET mrp = mrp / 100.0,
discountedSellingPrice = discountedSellingPrice / 100.0;

SELECT mrp, discountedSellingPrice FROM zepto;


-- Q1. Find the top 10 best-value products based on the discount percentage.
SELECT DISTINCT name, mrp, discountPercent
FROM zepto
ORDER BY discountPercent DESC
LIMIT 10;

-- Q2.What are the Products with High MRP but Out of Stock
SELECT DISTINCT name,mrp
FROM zepto
WHERE outOfStock = TRUE and mrp > 300
ORDER BY mrp DESC;

-- Q3.Calculate Estimated Revenue for each category
SELECT category,
SUM(discountedSellingPrice * availableQuantity) AS total_revenue
FROM zepto
GROUP BY category
ORDER BY total_revenue;

-- Q4. Find all products where MRP is greater than ₹500 and discount is less than 10%.
SELECT DISTINCT name, mrp, discountPercent
FROM zepto
WHERE mrp > 500 AND discountPercent < 10
ORDER BY mrp DESC, discountPercent DESC;

-- Q5. Identify the top 5 categories offering the highest average discount percentage.
SELECT category,
ROUND(AVG(discountPercent),2) AS avg_discount
FROM zepto
GROUP BY category
ORDER BY avg_discount DESC
LIMIT 5;

-- Q6. Find the price per gram for products above 100g and sort by best value.
SELECT DISTINCT name, weightInGms, discountedSellingPrice,
ROUND(discountedSellingPrice/weightInGms,2) AS price_per_gram
FROM zepto
WHERE weightInGms >= 100
ORDER BY price_per_gram;

-- Q7.Group the products into categories like Low, Medium, Bulk.
SELECT DISTINCT name, weightInGms,
CASE WHEN weightInGms < 1000 THEN 'Low'
	WHEN weightInGms < 5000 THEN 'Medium'
	ELSE 'Bulk'
	END AS weight_category
FROM zepto;

-- Q8.What is the Total Inventory Weight Per Category 
SELECT category,
SUM(weightInGms * availableQuantity) AS total_weight
FROM zepto
GROUP BY category
ORDER BY total_weight;

-- Q9.Find the top product in each category with the highest discount percentage
SELECT zp.Category, zp.name, zp.discountPercent
FROM zepto zp
JOIN (
    SELECT Category, MAX(discountPercent) AS max_discount
    FROM zepto
    GROUP BY Category
) AS max_discounts
ON zp.Category = max_discounts.Category
AND zp.discountPercent = max_discounts.max_discount;

-- Q10. Calculate stock value loss due to discount per category
SELECT 
    Category,
    SUM((mrp - discountedSellingPrice) * availableQuantity) / 100.0 AS total_discount_loss_rupees
FROM zepto
WHERE outOfStock = FALSE
GROUP BY Category
ORDER BY total_discount_loss_rupees DESC;

-- Q11.Use a window function to rank products by discount percentage within each category
SELECT 
    Category, 
    name, 
    discountPercent,
    RANK() OVER (PARTITION BY Category ORDER BY discountPercent DESC) AS discount_rank
FROM zepto;

-- Q.12 CTE: Show average discounted price and deviation of each product from category average
WITH CategoryAverages AS (
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

-- Q13. Find the heaviest item (by weight × quantity) in stock
SELECT name, Category, weightInGms, availableQuantity,
       (weightInGms * availableQuantity) AS total_weight
FROM zepto
WHERE outOfStock = FALSE
ORDER BY total_weight DESC
LIMIT 1;

-- Q14. Show percent contribution of each product to its category's total available stock
SELECT 
    name,
    Category,
    availableQuantity,
    ROUND(availableQuantity * 100.0 / 
        SUM(availableQuantity) OVER (PARTITION BY Category), 2) AS stock_percentage_in_category
FROM zepto;

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

DELIMITER $$
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

-- Run the summary
CALL sp_category_inventory_summary();

