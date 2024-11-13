# <p align="center"> Case Study #6: 🎣 Clique Bait
 
## <p align="center"> B. Digital Analysis.md

### Questions

Using the available datasets - answer the following questions using a single query for each one:

  1. [How many users are there?](#1-how-many-users-are-there)
  2. [How many cookies does each user have on average?](#2-how-many-cookies-does-each-user-have-on-average)
  3. [What is the unique number of visits by all users per month?](#3-what-is-the-unique-number-of-visits-by-all-users-per-month)
  4. [What is the number of events for each event type?](#4-what-is-the-number-of-events-for-each-event-type)
  5. [What is the percentage of visits which have a purchase event?](#5-what-is-the-percentage-of-visits-which-have-a-purchase-event)
  6. [What is the percentage of visits which view the checkout page but do not have a purchase event?](#6-what-is-the-percentage-of-visits-which-view-the-checkout-page-but-do-not-have-a-purchase-event)
  7. [What are the top 3 pages by number of views?](#7-what-are-the-top-3-pages-by-number-of-views)
  8. [What is the number of views and cart adds for each product category?](#8-what-is-the-number-of-views-and-cart-adds-for-each-product-category)
  9. [What are the top 3 products by purchases?](#9-what-are-the-top-3-products-by-purchases)

<br>

> *Note: 
The term **visit** can have different meanings depending on the context. It may refer to a **session**, representing a user's interaction with the website from entry to exit, or a **page view**, representing each individual page loaded during that session.  
For the purposes of this analysis, **visit** is treated as a session, unless otherwise specified.*


#### 1. How many users are there?

```sql
SELECT COUNT(DISTINCT user_id)  AS number_of_customers
FROM users;
```
##### Result: 
<img src="assets/cs6 - b1.png">

The dataset contains 500 unique users.

#### 2. How many cookies does each user have on average?

```sql
SELECT 
	COUNT(*) AS number_of_cookies,
	COUNT(DISTINCT user_id) AS number_of_users,
	CAST(COUNT(*) * 1.0 / COUNT(DISTINCT user_id) AS NUMERIC(3,1)) AS avg_number_of_cookies
FROM users;
```
##### Result: 
<img src="assets/cs6 - b2.png">

The averege number of cookies per user is 3.6. 


#### 3. What is the unique number of visits by all users per month?

```sql
SELECT 
	MONTH(event_time) AS month, -- extract the month from the date
	COUNT(DISTINCT visit_id) AS number_of_unique_visits
FROM events
GROUP BY MONTH(event_time)
ORDER BY MONTH(event_time);
```
##### Result: 
<img src="assets/cs6 - b3.png">

The dataset covers only 5 months (January to May). The highest number of visits occurred in February, while May had the lowest.

#### 4. What is the number of events for each event type?

```sql
SELECT 
	ei.event_name, -- event_name from event_identifier
	COUNT(*) AS number_of_events
FROM events e
LEFT JOIN event_identifier ei 
ON ei.event_type = e.event_type
GROUP BY ei.event_name
ORDER BY COUNT(*) DESC;
```
##### Result: 
<img src="assets/cs6 - b4.png">

The most common event on the Clique Bait website is a Page View (almost 21k hits), while the least common is an Ad Click. 

#### 5. What is the percentage of visits which have a purchase event?

```sql
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
```
##### Steps:
- Created two common table expressions (CTEs):
    - The first CTE, `n_purchases`, calculates the total number of purchases and the number of unique visits with at least one purchase.
    - The second CTE, `n_visits`, calculates the total number of unique visits on the website.
- Calculated the percentage of visits with purchase by deviding the number of visits with purchases by the total number of visits. The result was then multiplied by 100 to express it as a percentage. Finally, the result was cast to the `NUMERIC` type for precision.

##### Result: 
<img src="assets/cs6 - b5.png">

Almost half of all visit ends with a purchase (exactly 49,9%). This conversion rate is quite good for an e-commerce site. As always, it would be beneficial to monitor this parametr over time using a dashoboard to identify trends and fluctuations.


#### 6. What is the percentage of visits which view the checkout page but do not have a purchase event?

```sql
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
```

##### Steps:
- Created a common table expression (`n_visits`) to flag visits:
    - Visits that include a purchase event (`visit_with_purchase`).
    - Visits that include a checkout page view (`visit_with_checkout`).
- Calculated the number of visits where the checkout page was viewed but no purchase was made (checkout_without_purchase) by ensuring:
    - `visit_with_checkout` equals 1 (checkout page was viewed);
    - `visit_with_purchase` equals 0 (no purchase event occurred).
- Deviding the number of `checkout_without_purchase` visits by the total number of visits with a checkout page view (`visit_with_checkout`). The result was then multiplied by 100 to express it as a percentage. Finally, the result was cast to the `NUMERIC` type for precision.

##### Result: 
<img src="assets/cs6 - b6.png">

According to the collected data, 15.5% of visits that included a checkout page view did not result in a purchase. It would be helpful to analyze the checkout page further to identify potential reasons for cart abandonment.

#### 7. What are the top 3 pages by number of views?

```sql
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
```
##### Result: 
<img src="assets/cs6 - b7a.png">


**Visit - meaning session**. The most popular pages among users are All Products, Checkout and Home Page.

```sql
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
```
##### Result: 
<img src="assets/cs6 - b7b.png">

**Visit - meaning page view**. The most popular pages among users are All Products, Lobster and Crab. This suggests that many customers are particularly interested in Lobsters and Crabs.

#### 8. What is the number of views and cart adds for each product category?

```sql
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
```
##### Result: 
<img src="assets/cs6 - b8.png">

The Shellfish category has the highest number of views and cart adds, indicating strong customer interest in this type of product (e.g., Oyster, Crab, Lobster, and Abalone). Upon examining the metrics for each category, it is notable that all categories have a cart-add conversion rate (CR) of 60-61%.

#### 9. What are the top 3 products by purchases?

```sql
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
```

##### Steps:
- Created a common table expresion (`visit_purchase`) to identify visits that included a purchase event and determine the sequence number of the purchase within each visit.
- Created another common table expresion (`product_add_to_cart`) to select all events where products were added to the cart.
- Calculated the number of purchased products by joining `product_add_to_cart` with `visit_purchase` to ensure that the product added to the cart belongs to a visit that ended with a purchase.
Filtering to include only products that were added to the cart before the purchase occurred (based on sequence numbers).
- Grouped the results by product name (page_name) and sorted them in descending order of the number of purchases to determine the top 3 products.

##### Result: 
<img src="assets/cs6 - b9.png">

The most popular products in the store are Lobster, Oyster and Crab, all of which belong to the Shellfish category. Great job capitalizing on this high-demand category!

<br></br>
***

Thank you for your attention! 🫶️

[Next Section: *Product Funnel Analysis* ➔](https://github.com/ElaWajdzik/SQL-Challenge-Case-Study-6---Clique-Bait/blob/main/C.%20Product%20Funnel%20Analysis.md)

[Return to README ➔](https://github.com/ElaWajdzik/SQL-Challenge-Case-Study-6---Clique-Bait/blob/main/README.md)