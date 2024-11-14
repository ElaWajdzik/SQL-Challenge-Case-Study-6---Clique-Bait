# <p align="center"> Case Study #6: 🎣 Clique Bait
 
## <p align="center"> C. Product Funnel Analysis

### Questions

1. [The table that aggregates data for each product](#1-the-table-that-aggregates-data-for-each-product)  
2. [The table that aggregates data for each product category](#2-the-table-that-aggregates-data-for-each-product-category)  
3. [Additional questions](#3-additional-questions):  
   a. [Which product had the most views cart adds and purchases](#3-1-which-product-had-the-most-views-cart-adds-and-purchases)  
   b. [Which product was most likely to be abandoned](#3-2-which-product-was-most-likely-to-be-abandoned)  
   c. [Which product had the highest view to purchase percentage](#3-3-which-product-had-the-highest-view-to-purchase-percentage)  
   d. [What is the average conversion rate from view to cart add](#3-4-what-is-the-average-conversion-rate-from-view-to-cart-add)  
   e. [What is the average conversion rate from cart add to purchase](#3-5-what-is-the-average-conversion-rate-from-cart-add-to-purchase)  




#### 1. The table that aggregates data for each product.

Using a single SQL query - create a new output table which has the following details:

- How many times was each product viewed?
- How many times was each product added to cart?
- How many times was each product added to a cart but not purchased (abandoned)?
- How many times was each product purchased?


```sql
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
```
##### Steps:
- Created a common table expresion `CTE_events` to flag visits with purchases.
- Created a common table expresion `product_views` to calculated the number of views for each product page.
- Used the table `CTE_events` to calculate the number of cart adds, purchases and abandoned carts for each product.
- Joined the tables `product_views` and `product_cart_adds` to calculate the final result. 


##### Result: 
<img src="assets/cs6 - c1a.png">

#### 2. The table that aggregates data for each product category

Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.

```sql
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
```

The process for creating this table was very similar to the table with aggregations for each product. The only change was replacing `p.page_name` with `p.product_category`.

##### Result: 
<img src="assets/cs6 - c1b.png">

#### 3. Additional questions

Use your 2 new output tables - answer the following questions:

#### a. Which product had the most views, cart adds and purchases?

##### Result: 
<img src="assets/cs6 - c2.png">

The shop recorded the most views for Oyster, and the most cart adds and purchases for Lobster.

#### b. Which product was most likely to be abandoned?
#### c. Which product had the highest view to purchase percentage?

```sql
	CAST(pca.number_of_abandoned_carts * 100.0 / pca.number_of_cart_adds AS NUMERIC(4,1)) AS abandoned_rate,
	CAST(pca.number_of_purchases * 100.0 / pv.number_of_views AS NUMERIC(4,1)) AS cr --view-to-purchase conversion rate
```

Added two columns `abandoned_rate` and `cr` to the previous table.

##### Result: 
<img src="assets/cs6 - c3.png">

More than one in four Russian Caviar items was abandoned (26.3% of all cart adds).
The highest conversion rate (48.7%) was achieved by Lobster.

#### d. What is the average conversion rate from view to cart add?
#### e. What is the average conversion rate from cart add to purchase?

```sql
WITH .... --like before

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
```


##### Result: 
<img src="assets/cs6 - c4.png">

The overall conversion rate for the Clique Bait shop was 46.3%.
The conversion rate from view to cart add was 60.9%, and the conversion rate from cart add to purchase was 75.9%.

<br></br>
***

Thank you for your attention! 🫶️

[Next Section: *Campaigns Analysis* ➔](https://github.com/ElaWajdzik/SQL-Challenge-Case-Study-6---Clique-Bait/blob/main/D.%20Campaigns%20Analysis.md)

[Return to README ➔](https://github.com/ElaWajdzik/SQL-Challenge-Case-Study-6---Clique-Bait/blob/main/README.md)