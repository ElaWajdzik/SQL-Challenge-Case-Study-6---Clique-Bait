-------------------------
--D. Campaigns Analysis--
-------------------------

--Author: Ela Wajdzik
--Date: 15.11.2024
--Tool used: Microsoft SQL Server


--Generate a table that has 1 single row for every unique visit_id record and has the following columns:

    --user_id
    --visit_id
    --visit_start_time: the earliest event_time for each visit
    --page_views: count of page views for each visit
    --cart_adds: count of product cart add events for each visit
    --purchase: 1/0 flag if a purchase event exists for each visit
    --campaign_name: map the visit to a campaign if the visit_start_time falls between the start_date and end_date
    --impression: count of ad impressions for each visit
    --click: count of ad clicks for each visit
    --(Optional column) cart_products: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the sequence_number)



WITH CTE_event AS (
-- CTE to aggregate visit-level data
	SELECT 
		u.user_id,
		e.visit_id,
		MIN(event_time) AS visit_start_time, --earliest event time for the visit
		SUM(CASE event_type WHEN 1 THEN 1 ELSE 0 END)  AS page_views,
		SUM(CASE event_type WHEN 2 THEN 1 ELSE 0 END) AS cart_adds,
		MAX(CASE event_type WHEN 3 THEN 1 ELSE 0 END) AS purchase, --flag for purchase event (1 if exists)
		SUM(CASE event_type WHEN 4 THEN 1 ELSE 0 END) AS impression,
		SUM(CASE event_type WHEN 5 THEN 1 ELSE 0 END) AS click,
        --concatenate product names added to cart in the order they were added
		STRING_AGG(CASE WHEN event_type = 2 THEN p.page_name ELSE NULL END, ', ') WITHIN GROUP (ORDER BY e.sequence_number ASC) AS cart_products
	FROM events e
	LEFT JOIN users u
	ON u.cookie_id = e.cookie_id
	LEFT JOIN page_hierarchy p
	ON e.page_id = p.page_id
	GROUP BY u.user_id, e.visit_id)

--final table with all aggregated data with and campaign information
SELECT 
	user_id,
	visit_id,
	visit_start_time,
	page_views,
	cart_adds,
	purchase,
	c.campaign_name, --campaign name based on visit_start_time
	impression,
	click,
	cart_products
FROM CTE_event e
LEFT JOIN campaign_identifier c
ON e.visit_start_time BETWEEN c.start_date AND c.end_date; --match visits to campaigns by date




--Identifying users who have received impressions during each campaign period and comparing each metric with other users who did not have an impression event
--Does clicking on an impression lead to higher purchase rates?
--What is the uplift in purchase rate when comparing users who click on a campaign impression versus users who do not receive an impression? What if we compare them with users who just an impression but do not click?
--What metrics can you use to quantify the success or failure of each campaign compared to eachother?

WITH CTE_event AS (
	SELECT 
		u.user_id,
		e.visit_id,
		MIN(event_time) AS visit_start_time,
		SUM(CASE event_type WHEN 1 THEN 1 ELSE 0 END)  AS page_views,
		SUM(CASE event_type WHEN 2 THEN 1 ELSE 0 END) AS cart_adds,
		MAX(CASE event_type WHEN 3 THEN 1 ELSE 0 END) AS purchase,
		SUM(CASE event_type WHEN 4 THEN 1 ELSE 0 END) AS impression,
		SUM(CASE event_type WHEN 5 THEN 1 ELSE 0 END) AS click,
		STRING_AGG(CASE WHEN event_type = 2 THEN p.page_name ELSE NULL END, ', ') WITHIN GROUP (ORDER BY e.sequence_number ASC) AS cart_products
	FROM events e
	LEFT JOIN users u
	ON u.cookie_id = e.cookie_id
	LEFT JOIN page_hierarchy p
	ON e.page_id = p.page_id
	GROUP BY u.user_id, e.visit_id),

visit_summary AS (
	SELECT 
		user_id,
		visit_id,
		visit_start_time,
		page_views,
		cart_adds,
		purchase,
		c.campaign_name,
		impression,
		click,
		cart_products
	FROM CTE_event e
	LEFT JOIN campaign_identifier c
	ON e.visit_start_time BETWEEN c.start_date AND c.end_date)

SELECT
	campaign_name,
	impression,
	click,
	COUNT(*) AS number_of_visits,
	--SUM(page_views) AS total_page_views,
	--SUM(cart_adds) AS total_cart_adds,
	--SUM(purchase) AS total_purchases,
	CAST(SUM(page_views) * 1.0 / COUNT(*) AS NUMERIC(4,2)) AS avg_page_views_per_visit,
	CAST(SUM(purchase) * 100.0 / COUNT(*) AS NUMERIC(4,1)) AS cr_visit_to_purchase,
	CAST(SUM(cart_adds) * 1.0 / COUNT(*) AS NUMERIC(4,1)) AS avg_cart_adds_per_visit,
	CAST(SUM(CASE purchase WHEN 1 THEN cart_adds ELSE 0 END) * 1.0 / SUM(purchase) AS NUMERIC(3,1)) AS avg_purchased_items
FROM visit_summary
WHERE campaign_name IS NOT NULL
--AND impression = 1
GROUP BY campaign_name, impression, click
ORDER BY campaign_name, impression, click;

