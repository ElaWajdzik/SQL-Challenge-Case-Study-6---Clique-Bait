# <p align="center"> Case Study #6: 🎣 Clique Bait
 
## <p align="center"> A. Enterprise Relationship Diagram

Using the following DDL schema details to create an ERD for all the Clique Bait datasets.

The ERD for the Clique Bait datasets can look like this. It is based on the description tables provided on the challenge website.

<img src="assets/Clique Bait.png" height="400">

---

If we look closer at the database, we can see that the table `campaign_identifier` is not well-designed because one of its columns contains non-atomic values. Specifically, the `products` column holds a range of product values, which violates the principle of atomicity.

``Table 4: campaign_identifier``

| campaign_id | products | campaign_name                    | start_date          | end_date            |
|-------------|----------|----------------------------------|---------------------|---------------------|
| 1           | 1-3      | BOGOF - Fishing For Compliments | 2020-01-01 00:00:00 | 2020-01-14 00:00:00 |
| 2           | 4-5      | 25% Off - Living The Lux Life   | 2020-01-15 00:00:00 | 2020-01-28 00:00:00 |
| 3           | 6-8      | Half Off - Treat Your Shellf(ish) | 2020-02-01 00:00:00 | 2020-03-31 00:00:00 |

To fix this problem, we should add a table that contains information about which products are included in each campaign (a table named `product_campaign`). Additionally, it would be a good idea to create a new table to store all information about products. Currently, this information is included in the `page_hierarchy` table, but the primary purpose of that table is to store information about pages, not available products.

After applying all the changes, the ERD will look like this:

<img src="assets/Clique Bait v2.png" height="400">


<br></br>

### ``Table 1: users`` - without changes

<details><summary>
    Sample of data, 10 random rows.
  </summary> 

  user_id	| cookie_id	| start_date
--	| --	| --
397	| 3759ff	| 2020-03-30 00:00:00
215	| 863329	| 2020-01-26 00:00:00
191	| eefca9	| 2020-03-15 00:00:00
89	| 764796	| 2020-01-07 00:00:00
127	| 17ccc5	| 2020-01-22 00:00:00
81	| b0b666	| 2020-03-01 00:00:00
260	| a4f236	| 2020-01-08 00:00:00
203	| d1182f	| 2020-04-18 00:00:00
23	| 12dbc8	| 2020-01-18 00:00:00
375	| f61d69	| 2020-01-03 00:00:00
  </details>


#### ``Table 2: events`` - without changes

<details><summary>
    Sample of data, 10 random rows.
  </summary>  

| visit_id | cookie_id | page_id | event_type | sequence_number | event_time                 |
|----------|-----------|---------|------------|-----------------|---------------------------|
| 719fd3   | 3d83d3    | 5       | 1          | 4               | 2020-03-02 00:29:09.975502 |
| fb1eb1   | c5ff25    | 5       | 2          | 8               | 2020-01-22 07:59:16.761931 |
| 23fe81   | 1e8c2d    | 10      | 1          | 9               | 2020-03-21 13:14:11.745667 |
| ad91aa   | 648115    | 6       | 1          | 3               | 2020-04-27 16:28:09.824606 |
| 5576d7   | ac418c    | 6       | 1          | 4               | 2020-01-18 04:55:10.149236 |
| 48308b   | c686c1    | 8       | 1          | 5               | 2020-01-29 06:10:38.702163 |
| 46b17d   | 78f9b3    | 7       | 1          | 12              | 2020-02-16 09:45:31.926407 |
| 9fd196   | ccf057    | 4       | 1          | 5               | 2020-02-14 08:29:12.922164 |
| edf853   | f85454    | 1       | 1          | 1               | 2020-02-22 12:59:07.652207 |
| 3c6716   | 02e74f    | 3       | 2          | 5               | 2020-01-31 17:56:20.777383 |
  </details>

#### ``Table 3: event_identifier`` - without changes

<details><summary>
    All data.
  </summary>  

| event_type | event_name    |
|------------|---------------|
| 1          | Page View     |
| 2          | Add to Cart   |
| 3          | Purchase      |
| 4          | Ad Impression |
| 5          | Ad Click      |

  </details>

#### ``Table 4: campaign_identifier`` - without column `products`

| campaign_id  | campaign_name                    | start_date          | end_date            |
|-------------|----------------------------------|---------------------|---------------------|
| 1           | BOGOF - Fishing For Compliments | 2020-01-01 00:00:00 | 2020-01-14 00:00:00 |
| 2           | 25% Off - Living The Lux Life   | 2020-01-15 00:00:00 | 2020-01-28 00:00:00 |
| 3           | Half Off - Treat Your Shellf(ish) | 2020-02-01 00:00:00 | 2020-03-31 00:00:00 |



#### ``Table 5: page_hierarchy`` - without column `product_category`

| page_id | page_name          | product_id |
|---------|--------------------|------------|
| 1       | Home Page          | null       |
| 2       | All Products       | null       |
| 3       | Salmon             | 1          |
| 4       | Kingfish           | 2          |
| 5       | Tuna               | 3          |
| 6       | Russian Caviar     | 4          |
| 7       | Black Truffle      | 5          |
| 8       | Abalone            | 6          |
| 9       | Lobster            | 7          |
| 10      | Crab               | 8          |
| 11      | Oyster             | 9          |
| 12      | Checkout           | null       |
| 13      | Confirmation       | null       |


#### ``Table 6: products`` - the new dimension table

| product_id | product_name    | product_category |
|------------|-----------------|------------------|
| 1          | Salmon          | Fish             |
| 2          | Kingfish        | Fish             |
| 3          | Tuna            | Fish             |
| 4          | Russian Caviar  | Luxury           |
| 5          | Black Truffle   | Luxury           |
| 6          | Abalone         | Shellfish        |
| 7          | Lobster         | Shellfish        |
| 8          | Crab            | Shellfish        |
| 9          | Oyster          | Shellfish        |

#### ``Table 7: product_campaign`` - the new junction table

| product_id | campaign_id |
|------------|-------------|
| 1          | 1           |
| 2          | 1           |
| 3          | 1           |
| 4          | 2           |
| 5          | 2           |
| 6          | 3           |
| 7          | 3           |
| 8          | 3           |

<br></br>
***

Thank you for your attention! 🫶️

[Next Section: *Digital Analysis* ➔](https://github.com/ElaWajdzik/SQL-Challenge-Case-Study-6---Clique-Bait/blob/main/B.%20Digital%20Analysis.md)

[Return to README ➔](https://github.com/ElaWajdzik/SQL-Challenge-Case-Study-6---Clique-Bait/blob/main/README.md)