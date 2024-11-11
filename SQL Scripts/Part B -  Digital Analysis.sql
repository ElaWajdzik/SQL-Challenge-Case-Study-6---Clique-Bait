-----------------------
--B. Digital Analysis--
-----------------------

--Author: Ela Wajdzik
--Date: 11.11.2024
--Tool used: Microsoft SQL Server

--How many users are there?

SELECT COUNT(DISTINCT user_id)  AS number_of_customers
FROM users;

--How many cookies does each user have on average?

SELECT 
	COUNT(*) AS number_of_cookies,
	COUNT(DISTINCT user_id) AS number_of_users,
	CAST(COUNT(*) * 1.0 / COUNT(DISTINCT user_id) AS NUMERIC(4,2)) AS avg_of_cookies
FROM users;

--What is the unique number of visits by all users per month?

SELECT 
	MONTH(event_time) AS month,
	COUNT(DISTINCT visit_id) AS number_of_q_visit
FROM events
GROUP BY MONTH(event_time);

--What is the number of events for each event type?

SELECT 
	ei.event_name,
	COUNT(*) AS number_of_events
FROM events e
LEFT JOIN event_identifier ei
ON ei.event_type = e.event_type
GROUP BY ei.event_name
ORDER BY COUNT(*) DESC;

--What is the percentage of visits which have a purchase event?

WITH visits_with_purchase AS (
	SELECT 
		COUNT(*) AS number_of_purchases,
		COUNT(DISTINCT visit_id) AS number_of_visits_with_purchase
	FROM events
	WHERE event_type = 3),

visits AS (
	SELECT 
		COUNT(DISTINCT visit_id) AS number_of_visits
	FROM events)

SELECT 
	CAST (number_of_visits_with_purchase * 100.0 / number_of_visits AS NUMERIC (4,1)) AS perc_of_visits_with_purchase,
	*
FROM visits
CROSS JOIN visits_with_purchase vp

--What is the percentage of visits which view the checkout page but do not have a purchase event?

WITH visits_with_purchase AS (
	SELECT 
		visit_id,
		1 AS visit_with_purchase
	FROM events
	WHERE event_type = 3
	GROUP BY visit_id),

visit_checkout AS (
	SELECT 
		visit_id,
		1 AS visit_checkout
	FROM events
	WHERE page_id = 12
	GROUP BY visit_id)

SELECT 
	SUM(c.visit_checkout) AS number_of_visits_with_checkout,
	SUM(visit_with_purchase) AS number_of_purchases,
	CAST(SUM(visit_with_purchase) * 100.0 / SUM(c.visit_checkout) AS NUMERIC(4,1)) AS perc_purchases_from_checkout
FROM visit_checkout c
LEFT JOIN visits_with_purchase p
ON p.visit_id = c.visit_id