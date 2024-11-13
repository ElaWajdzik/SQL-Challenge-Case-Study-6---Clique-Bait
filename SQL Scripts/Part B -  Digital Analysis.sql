-----------------------
--B. Digital Analysis--
-----------------------

--Author: Ela Wajdzik
--Date: 11.11.2024
--Tool used: Microsoft SQL Server


--1. How many users are there?

SELECT COUNT(DISTINCT user_id)  AS number_of_customers
FROM users;

--2. How many cookies does each user have on average?

SELECT 
	COUNT(*) AS number_of_cookies,
	COUNT(DISTINCT user_id) AS number_of_users,
	CAST(COUNT(*) * 1.0 / COUNT(DISTINCT user_id) AS NUMERIC(3,1)) AS avg_number_of_cookies
FROM users;

--3. What is the unique number of visits by all users per month?

SELECT 
	MONTH(event_time) AS month, -- extract the month from the date
	COUNT(DISTINCT visit_id) AS number_of_unique_visits
FROM events
GROUP BY MONTH(event_time)
ORDER BY MONTH(event_time);

--4. What is the number of events for each event type?

SELECT 
	ei.event_name, -- event_name from event_identifier
	COUNT(*) AS number_of_events
FROM events e
LEFT JOIN event_identifier ei 
ON ei.event_type = e.event_type
GROUP BY ei.event_name
ORDER BY COUNT(*) DESC;

--5. What is the percentage of visits which have a purchase event?

WITH n_purchases AS (
	SELECT 
		COUNT(*) AS number_of_purchases, --total number of purchase events
		COUNT(DISTINCT visit_id) AS number_of_visits_with_purchase --visits with at least one purchase
	FROM events
	WHERE event_type = 3 --filter purchase events (event_type = 3)
	),

n_visits AS (
	SELECT 
		COUNT(DISTINCT visit_id) AS number_of_visits
	FROM events)

SELECT 
	CAST (p.number_of_visits_with_purchase * 100.0 / v.number_of_visits AS NUMERIC (4,1)) AS perc_of_visits_with_purchase,
	*
FROM n_visits v, n_purchases p

--6. What is the percentage of visits which view the checkout page but do not have a purchase event?

WITH n_visits AS (
SELECT 
	visit_id,
	MAX(CASE event_type WHEN 3 THEN 1 ELSE 0 END) AS visit_with_purchase, --flag visits with purchase events
	MAX(CASE page_id WHEN 12 THEN 1 ELSE 0 END) AS visit_with_checkout --flag visits with checkout page views
FROM events
GROUP BY visit_id)

SELECT 
	SUM(visit_with_purchase) AS number_of_purchases,
	SUM(visit_with_checkout) AS number_of_visits_with_checkout,
	SUM(CASE WHEN visit_with_purchase = 0 AND visit_with_checkout = 1 THEN 1 ELSE 0 END) AS checkout_without_purchase,
	CAST(SUM(CASE WHEN visit_with_purchase = 0 AND visit_with_checkout = 1 THEN 1 ELSE 0 END) * 100.0 / SUM(visit_with_checkout) AS NUMERIC(4,1)) perc_checkout_without_purchase
FROM n_visits;

--7. What are the top 3 pages by number of views?

-- visit - meaning session
SELECT
	TOP 3
	p.page_name, --page_name from page_hierarchy
	COUNT(DISTINCT visit_id) AS number_of_visits
FROM events e
LEFT JOIN page_hierarchy p
ON e.page_id = p.page_id
GROUP BY p.page_name
ORDER BY number_of_visits DESC;

-- visit - meaning page view/loads
SELECT
	TOP 3
	p.page_name, --page_name from page_hierarchy
	COUNT(*) AS number_of_visits
FROM events e
LEFT JOIN page_hierarchy p
ON e.page_id = p.page_id
GROUP BY p.page_name
ORDER BY number_of_visits DESC;

--8. What is the number of views and cart adds for each product category?

SELECT 
	p.product_category,
	SUM(CASE e.event_type WHEN 2 THEN 1 ELSE 0 END) AS cart_adds, --add to cart (event_type = 2)
	SUM(CASE e.event_type WHEN 1 THEN 1 ELSE 0 END) AS pages_views --page view (event_type = 1)
FROM events e
LEFT JOIN page_hierarchy p
ON p.page_id = e.page_id
WHERE p.product_category IS NOT NULL 
GROUP BY p.product_category
ORDER BY cart_adds DESC;

--9. What are the top 3 products by purchases?

WITH visit_purchase AS (
	SELECT
		visit_id,
		MAX(sequence_number) AS purchase_sequence_number --identify purchase event position in the visit sequence
	FROM events
	WHERE event_type = 3 --filter for purchase events (event_type = 3)
	GROUP BY visit_id),

product_add_to_cart AS (
	SELECT
		*
	FROM events
	WHERE event_type = 2 --filter for "Add to Cart" events (event_type = 2)
	)

SELECT TOP 3
	ph.page_name AS product_name,
	COUNT(*) AS number_of_purchases
FROM visit_purchase vp
LEFT JOIN product_add_to_cart p
ON p.visit_id = vp.visit_id
LEFT JOIN page_hierarchy ph
ON ph.page_id = p.page_id
WHERE p.sequence_number < vp.purchase_sequence_number --ensure the product was added to cart before the purchase
GROUP BY ph.page_name
ORDER BY number_of_purchases DESC;