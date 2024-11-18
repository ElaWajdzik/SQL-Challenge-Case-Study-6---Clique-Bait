
# <p align="center"> Case Study #6: 🎣 Clique Bait
 
## <p align="center"> D. Campaigns Analysis

### Contents

1. [Summary table for each visit](#1-summary-table-for-each-visit)
2. 


#### 1. Summary table for each visit

Generate a table that has 1 single row for every unique `visit_id` record and has the following columns:

- `user_id`
- `visit_id`
- `visit_start_time`: the earliest `event_time` for each visit
- `page_views`: count of page views for each visit
- `cart_adds`: count of product cart add events for each visit
- `purchase`: 1/0 flag if a purchase event exists for each visit
- `campaign_name`: map the visit to a campaign if the `visit_start_time` falls between the `start_date` and `end_date`
- `impression`: count of ad impressions for each visit
- `click`: count of ad clicks for each visit
- (Optional column) `cart_products`: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the `sequence_number`)


```sql
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
```
*Note: sample of data, 15 random rows*
<img src="assets/cs6 - d1.png">





<br></br>
***

Thank you for your attention! 🫶️

[Return to README ➔](https://github.com/ElaWajdzik/SQL-Challenge-Case-Study-6---Clique-Bait/blob/main/README.md)