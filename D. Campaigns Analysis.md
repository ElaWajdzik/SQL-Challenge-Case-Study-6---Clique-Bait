
# <p align="center"> Case Study #6: 🎣 Clique Bait
 
## <p align="center"> D. Campaigns Analysis

### Contents

1. [Summary table for each visit](#1-summary-table-for-each-visit)
2. [Campaign metrics analysis](#2-campaign-metrics-analysis)


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

#### 2. Campaign metrics analysis

##### A. Identifying users who have received impressions during each campaign period and comparing each metric with other users who did not have an impression event.

```sql
WITH ....

SELECT
	campaign_name,
	impression,
	COUNT(*) AS number_of_visits,
	CAST(SUM(page_views) * 1.0 / COUNT(*) AS NUMERIC(4,2)) AS avg_page_views_per_visit,
	CAST(SUM(purchase) * 100.0 / COUNT(*) AS NUMERIC(4,1)) AS cr_visit_to_purchase,
	CAST(SUM(cart_adds) * 1.0 / COUNT(*) AS NUMERIC(4,1)) AS avg_cart_adds_per_visit,
	CAST(SUM(CASE purchase WHEN 1 THEN cart_adds ELSE 0 END) * 1.0 / SUM(purchase) AS NUMERIC(3,1)) AS avg_purchased_items
FROM visit_summary
WHERE campaign_name IS NOT NULL
GROUP BY campaign_name, impression
ORDER BY campaign_name, impression;
```

<img src="assets/cs6 - d2.png">

<br> 

Visits with impressions during each campaign had higher metrics related to purchases. On average, visits with impressions viewed 3 more pages, added 3.5 more products to the cart, and purchased 3 more products than visits without impressions. The conversion rate (CR) for visits with impressions was more than twice as high (visits with impressions CR: 84%, visits without impressions CR: 38%).

However, there is an important difference between the number of visits in the group with impressions and those without. For each campaign, the group without impressions was three times larger.

If we treat the display of ads on the website as an A/B test, we can conclude that the presence of ads in the service has a **significantly positive influence on purchases**. In the next campaign, if possible, it would be beneficial to ensure a 50%/50% split between the two groups to confirm the distribution.


Results of A/B test for the campaign **25% Off - Living The Lux Life**:

<img src="assets/cs6 - d4a.png" width="600"> 
<img src="assets/cs6 - d4b.png" width="600">

<br>

Link to the AB Testguide for each campaign:
* [25% Off - Living The Lux Life](https://abtestguide.com/calc/?ua=300&ub=104&ca=115&cb=87)
* [BOGOF - Fishing For Compliments](https://abtestguide.com/calc/?ua=195&ub=65&ca=72&cb=55)
* [Half Off - Treat Your Shellf(ish)](https://abtestguide.com/calc/?ua=1810&ub=587&ca=578&cb=493)


##### B. Does clicking on an impression lead to higher purchase rates?

<img src="assets/cs6 - d3b.png">

Customers who clicked on impressions are represented by the blue line in the table above (`impression = 1` and `click = 1`). The best comparison would be between this group (`impression = 1` and `click = 1`) and the group that saw the impressions but did not click (`impression = 1` and `click = 0`), rather than with all visits without clicks.

Customers who clicked on impressions have **higher purchase rates** than those who only viewed the ads but did not click (CR for each campaign is at least 18 percentage points higher). The difference between these two groups has a **significant impact on the conversion rate**.

The ads from every campaign are highly effective in encouraging customers to click — around 80% of customers who see the ads click on them.

##### C. What is the uplift in purchase rate when comparing users who click on a campaign impression versus users who do not receive an impression? What if we compare them with users who just an impression but do not click?

The difference between **Group A** (users who clicked on a campaign impression, `impression = 1` and `click = 1`) and **Group B** (users who did not receive an impression, `impression = 0` and `click = 0`) is significant. The conversion rate (CR) for **Group A** was almost 2.5 times higher than for **Group B**.

When comparing these groups, we see that the CR in **Group A** is significantly higher. More importantly, even though **Group A** had far fewer visits, it contributed almost the same number of total purchases products as **Group B**. On average, people in **Group A** bought 2.5 more products than those in **Group B**, which likely resulted in greater profit for the company.

| group name | impression | click | number_of_visits | total_purchases | CR  | total_cart_adds |
|:----------:|:----------:|:-----:|:----------------:|:---------------:|:---:|:---------------:|
| Group A    |      1     |   1   |        599       |       537       | 90% |       3424      |
| Group B    |      0     |   0   |       2305       |       874       | 38% |       3437      |


##### D. What metrics can you use to quantify the success or failure of each campaign compared to eachother?

It would be good to compare the company's profit across all campaigns, as each campaign is linked to a higher number of purchases and lower product prices. The approach depends on the company's stage: if the company is still growing, has a small number of purchases, and wants to reach new audiences, keeping the profit at the same level may be a good strategy. However, if the goal of the campaigns is to increase the company's profit, it should be carefully calculated. The price shouldn't be too low, but low enough to drive more purchases.


<br></br>
***

Thank you for your attention! 🫶️

[Return to README ➔](https://github.com/ElaWajdzik/SQL-Challenge-Case-Study-6---Clique-Bait/blob/main/README.md)