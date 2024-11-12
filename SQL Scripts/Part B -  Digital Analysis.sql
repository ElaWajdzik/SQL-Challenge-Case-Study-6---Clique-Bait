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
	MONTH(event_time) AS month,
	COUNT(DISTINCT visit_id) AS number_of_unique_visits
FROM events
GROUP BY MONTH(event_time)
ORDER BY MONTH(event_time);

--4. What is the number of events for each event type?

SELECT 
	ei.event_name,
	COUNT(*) AS number_of_events
FROM events e
LEFT JOIN event_identifier ei
ON ei.event_type = e.event_type
GROUP BY ei.event_name
ORDER BY COUNT(*) DESC;

--5. What is the percentage of visits which have a purchase event?

WITH n_purchases AS (
	SELECT 
		COUNT(*) AS number_of_purchases,
		COUNT(DISTINCT visit_id) AS number_of_visits_with_purchase
	FROM events
	WHERE event_type = 3),

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
	MAX(CASE event_type WHEN 3 THEN 1 ELSE 0 END) AS visit_with_purchase,
	MAX(CASE page_id WHEN 12 THEN 1 ELSE 0 END) AS visit_with_checkout
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
	p.page_name,
	COUNT(DISTINCT visit_id) AS number_of_visits
FROM events e
LEFT JOIN page_hierarchy p
ON e.page_id = p.page_id
GROUP BY p.page_name
ORDER BY number_of_visits DESC;

-- visit - meaning page view
SELECT
	TOP 3
	p.page_name,
	COUNT(*) AS number_of_visits
FROM events e
LEFT JOIN page_hierarchy p
ON e.page_id = p.page_id
GROUP BY p.page_name
ORDER BY number_of_visits DESC;

--8. What is the number of views and cart adds for each product category?

-- add to cart -> event_type = 2

SELECT 
	p.product_category,
	COUNT(*) AS number_of_add_to_cart,
	COUNT(DISTINCT e.visit_id) AS number_of_session_with_add_to_cart
FROM events e
LEFT JOIN page_hierarchy p
ON p.page_id = e.page_id
WHERE e.event_type = 2
GROUP BY p.product_category
ORDER BY number_of_add_to_cart DESC;

--9. What are the top 3 products by purchases?

WITH visit_purchase AS (
	SELECT
		visit_id,
		MAX(sequence_number) AS purchase_sequence_number
	FROM events
	WHERE event_type = 3
	GROUP BY visit_id),

product_add_to_cart AS (
	SELECT
		*
	FROM events
	WHERE event_type = 2)

SELECT TOP 3
	ph.page_name AS product_name,
	COUNT(*) AS number_of_purchase
FROM visit_purchase vp
LEFT JOIN product_add_to_cart p
ON p.visit_id = vp.visit_id
LEFT JOIN page_hierarchy ph
ON ph.page_id = p.page_id
WHERE p.sequence_number < vp.purchase_sequence_number
GROUP BY ph.page_name
ORDER BY number_of_purchase DESC;