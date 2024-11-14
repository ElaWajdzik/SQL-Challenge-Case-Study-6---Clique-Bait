------------------------------
--C. Product Funnel Analysis--
------------------------------

--Author: Ela Wajdzik
--Date: 14.11.2024
--Tool used: Microsoft SQL Server

--Using a single SQL query - create a new output table which has the following details:
	--How many times was each product viewed?
	--How many times was each product added to cart?
	--How many times was each product added to a cart but not purchased (abandoned)?
	--How many times was each product purchased?

WITH CTE_events AS (
--flag visits with purchases
	SELECT 
		*,
		MAX(CASE event_type WHEN 3 THEN 1 ELSE 0 END) OVER(PARTITION BY visit_id) AS has_purchase --flag if a visit contains a purchase event
	FROM events),

product_views AS (
--calculate product views
	SELECT 
		p.page_name AS product_name,
		COUNT(*) AS number_of_views
	FROM events e
	LEFT JOIN page_hierarchy p
	ON p.page_id = e.page_id
	WHERE event_type = 1 -- page view -> event_type = 1
	AND e.page_id BETWEEN 3 AND 11 --restrict to specific product-related pages
	GROUP BY p.page_name),

product_cart_adds AS (
--calculate cart adds, purchases, and abandoned carts
	SELECT 
		p.page_name AS product_name,
		COUNT(*) AS number_of_cart_adds,
		SUM(has_purchase) AS number_of_purchases,
		SUM(CASE has_purchase WHEN 0 THEN 1 ELSE 0 END) AS number_of_abandoned_carts
	FROM CTE_events e
	LEFT JOIN page_hierarchy p
	ON p.page_id = e.page_id
	WHERE event_type = 2 -- add to cart -> event_type = 2
	AND e.page_id BETWEEN 3 AND 11 --restrict to specific product-related pages
	GROUP BY p.page_name)

SELECT 
	pv.product_name,
	pv.number_of_views,
	pca.number_of_cart_adds,
	pca.number_of_purchases,
	pca.number_of_abandoned_carts
FROM product_views pv
LEFT JOIN product_cart_adds pca
ON pv.product_name = pca.product_name;

--Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.

WITH CTE_events AS (
	SELECT 
		*,
		MAX(CASE event_type WHEN 3 THEN 1 ELSE 0 END) OVER(PARTITION BY visit_id) AS has_purchase
	FROM events),

product_views AS (
	SELECT 
		p.product_category AS product_category,
		COUNT(*) AS number_of_views
	FROM events e
	LEFT JOIN page_hierarchy p
	ON p.page_id = e.page_id
	WHERE event_type = 1 -- page view -> event_type = 1
	AND e.page_id BETWEEN 3 AND 11 --restrict to specific product-related pages
	GROUP BY p.product_category),

product_cart_adds AS (
	SELECT 
		p.product_category AS product_category,
		COUNT(*) AS number_of_cart_adds,
		SUM(has_purchase) AS number_of_purchases,
		SUM(CASE has_purchase WHEN 0 THEN 1 ELSE 0 END) AS number_of_abandoned_carts
	FROM CTE_events e
	LEFT JOIN page_hierarchy p
	ON p.page_id = e.page_id
	WHERE event_type = 2 -- add to cart -> event_type = 2
	AND e.page_id BETWEEN 3 AND 11 --restrict to specific product-related pages
	GROUP BY p.product_category)

SELECT 
	pv.product_category,
	pv.number_of_views,
	pca.number_of_cart_adds,
	pca.number_of_purchases,
	pca.number_of_abandoned_carts
FROM product_views pv
LEFT JOIN product_cart_adds pca
ON pv.product_category = pca.product_category;

--Use your 2 new output tables - answer the following questions:

--1. Which product had the most views, cart adds and purchases?
--2. Which product was most likely to be abandoned?
--3. Which product had the highest view to purchase percentage?

WITH ....

SELECT 
	pv.product_name,
	pv.number_of_views,
	pca.number_of_cart_adds,
	pca.number_of_purchases,
	pca.number_of_abandoned_carts,
	CAST(pca.number_of_abandoned_carts * 100.0 / pca.number_of_cart_adds AS NUMERIC(4,1)) AS abandoned_rate,
	CAST(pca.number_of_purchases * 100.0 / pv.number_of_views AS NUMERIC(4,1)) AS cr --view-to-purchase conversion rate
FROM product_views pv
LEFT JOIN product_cart_adds pca
ON pv.product_name = pca.product_name;



-- 4. What is the average conversion rate from view to cart add?
-- 5. What is the average conversion rate from cart add to purchase?

WITH ....

SELECT 
	SUM(pv.number_of_views) AS total_visits,
	SUM(pca.number_of_cart_adds) AS total_cart_adds,
	SUM(pca.number_of_purchases) AS total_purchases,
	CAST(SUM(pca.number_of_cart_adds) * 100.0 / SUM(pv.number_of_views) AS NUMERIC(4,1)) AS cr_view_to_cart_add,
	CAST(SUM(pca.number_of_purchases) * 100.0 / SUM(pca.number_of_cart_adds) AS NUMERIC(4,1)) AS c_cart_add_to_purchase,
	CAST(SUM(pca.number_of_purchases) * 100.0 / SUM(pv.number_of_views) AS NUMERIC(4,1)) AS cr_view_to_purchase
FROM product_views pv
LEFT JOIN product_cart_adds pca
ON pv.product_name = pca.product_name;

