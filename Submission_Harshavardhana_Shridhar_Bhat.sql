/* ----------------------------------------------------------------------------------------------------------------------------------
 * Name : Harshavardhana Shridhar Bhat
 * Batch : AIML Online December 2023 A
 * ----------------------------------------------------------------------------------------------------------------------------------/

/* -----------------------------------------------------------------------------------------------------------------------------------
                                                         Queries                                               
-----------------------------------------------------------------------------------------------------------------------------------*/

/*-- QUESTIONS RELATED TO CUSTOMERS
     [Q1] What is the distribution of customers across states?
     Hint: For each state, count the number of customers.*/

SELECT 
      cus.state AS "State", 
      COUNT(customer_id) AS "Number of Customers"
FROM customer_t AS cus
GROUP BY cus.state
ORDER BY COUNT(cus.customer_id) DESC;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q2] What is the average rating in each quarter?
-- Very Bad is 1, Bad is 2, Okay is 3, Good is 4, Very Good is 5.

Hint: Use a common table expression and in that CTE, assign numbers to the different customer ratings. 
      Now average the feedback for each quarter. */

WITH quarterly_feedback_count AS
(
    SELECT 
	CASE 
			WHEN ordr.customer_feedback = 'Very Good' THEN 5
			WHEN ordr.customer_feedback = 'Good' THEN 4
			WHEN ordr.customer_feedback = 'Okay' THEN 3
			WHEN ordr.customer_feedback = 'Bad' THEN 2
			WHEN ordr.customer_feedback = 'Very Bad' THEN 1
			END AS feedback_count,
            ordr.quarter_number
	FROM order_t AS ordr
)
SELECT 
      qfc.quarter_number AS "Quarter Number",
      avg(qfc.feedback_count) AS "Average Feedback"
FROM quarterly_feedback_count AS qfc
GROUP BY quarter_number
ORDER BY quarter_number;


-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q3] Are customers getting more dissatisfied over time?

Hint: Need the percentage of different types of customer feedback in each quarter. Use a common table expression and
	  determine the number of customer feedback in each category as well as the total number of customer feedback in each quarter.
	  Now use that common table expression to find out the percentage of different types of customer feedback in each quarter.
      Eg: (total number of very good feedback/total customer feedback)* 100 gives you the percentage of very good feedback. */
      
WITH quarterly_customer_feedback AS
(
	SELECT 
		ordr.quarter_number,
		SUM(CASE WHEN ordr.customer_feedback = 'Very Good' THEN 1 ELSE 0 END) AS very_good,
		SUM(CASE WHEN ordr.customer_feedback = 'Good' THEN 1 ELSE 0 END) AS good,
		SUM(CASE WHEN ordr.customer_feedback = 'Okay' THEN 1 ELSE 0 END) AS okay,
		SUM(CASE WHEN ordr.customer_feedback = 'Bad' THEN 1 ELSE 0 END) AS bad,
		SUM(CASE WHEN ordr.customer_feedback = 'Very Bad' THEN 1 ELSE 0 END) AS very_bad,
		COUNT(ordr.customer_feedback) AS total_feedbacks
	FROM order_t AS ordr
	GROUP BY ordr.quarter_number
)
SELECT qfc.quarter_number AS "Quarter Number",
        (qfc.very_good / qfc.total_feedbacks) * 100 AS "Very Good (%)",
        (qfc.good / qfc.total_feedbacks) * 100 AS "Good (%)",
        (qfc.okay / qfc.total_feedbacks) * 100 AS "Okay (%)",
        (qfc.bad / qfc.total_feedbacks) * 100 AS "Bad (%)",
        (qfc.very_bad / qfc.total_feedbacks)*100 AS "Very Bad (%)"
FROM quarterly_customer_feedback AS qfc
ORDER BY qfc.quarter_number;

-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q4] Which are the top 5 vehicle makers preferred by the customer.

Hint: For each vehicle make what is the count of the customers.*/

SELECT
      prod.vehicle_maker AS "Vehicle Maker",
      COUNT(cust.customer_id) AS "Number of Customers"
FROM product_t prod 
	INNER JOIN order_t AS ordr
	    ON prod.product_id = ordr.product_id
	INNER JOIN customer_t AS cust
	    ON ordr.customer_id = cust.customer_id
GROUP BY 1
ORDER BY 2 desc
LIMIT 5;

-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q5] What is the most preferred vehicle make in each state?

Hint: Use the window function RANK() to rank based on the count of customers for each state and vehicle maker. 
After ranking, take the vehicle maker whose rank is 1.*/
SELECT state AS "State", GROUP_CONCAT(vehicle_maker SEPARATOR ', ') AS "Vehicle Maker" FROM (
	SELECT
		  state,
		  vehicle_maker,
		  COUNT(cust.customer_id) no_of_cust,
		  RANK() OVER (PARTITION BY state ORDER BY COUNT(customer_id) DESC) _rank
FROM product_t AS prod 
	INNER JOIN order_t AS ordr
	    ON prod.product_id = ordr.product_id
	INNER JOIN customer_t AS cust
	    ON ordr.customer_id = cust.customer_id
	GROUP BY cust.state, prod.vehicle_maker) tbl
WHERE _rank = 1
GROUP BY state;


-- ---------------------------------------------------------------------------------------------------------------------------------

/*QUESTIONS RELATED TO REVENUE and ORDERS 

-- [Q6] What is the trend of number of orders by quarters?

Hint: Count the number of orders for each quarter.*/

SELECT 
	  ordr.quarter_number AS "Quarter Number", 
	  COUNT(ordr.order_id) AS "Total Orders"
FROM order_t AS ordr
GROUP BY ordr.quarter_number
ORDER BY ordr.quarter_number ASC;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q7] What is the quarter over quarter % change in revenue? 

Hint: Quarter over Quarter percentage change in revenue means what is the change in revenue from the subsequent quarter to the previous quarter in percentage.
      To calculate you need to use the common table expression to find out the sum of revenue for each quarter.
      Then use that CTE along with the LAG function to calculate the QoQ percentage change in revenue.
*/
      
WITH quarter_over_quarter AS 
(
	SELECT
		  ordr.quarter_number,
		  SUM(ordr.quantity * (ordr.vehicle_price - ((ordr.discount / 100) * ordr.vehicle_Price))) AS revenue
	FROM order_t AS ordr
	GROUP BY ordr.quarter_number
)
SELECT
      qoq.quarter_number AS "Quarter Number",
  	  qoq.revenue AS "Revenue",
      LAG(qoq.revenue) OVER(ORDER BY qoq.quarter_number) AS "Previous Revenue",
      (qoq.revenue - LAG(qoq.revenue) OVER(ORDER BY qoq.quarter_number))/LAG(qoq.revenue) OVER(ORDER BY qoq.quarter_number) AS "Quarter over Quarter Change (%)"
FROM quarter_over_quarter AS qoq; 

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q8] What is the trend of revenue and orders by quarters?

Hint: Find out the sum of revenue and count the number of orders for each quarter.*/

SELECT  
      quarter_number AS "Quarter Number",
      SUM(quantity * (vehicle_price - ((discount/100)*vehicle_Price))) AS "Revenue",
      COUNT(order_id) "Total Orders"
FROM order_t
GROUP BY quarter_number
ORDER BY quarter_number;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* QUESTIONS RELATED TO SHIPPING 
    [Q9] What is the average discount offered for different types of credit cards?

Hint: Find out the average of discount for each credit card type.*/

SELECT 
     credit_card_type AS "Credit Card Type", 
     avg(ordr.discount) AS "Average Discount"
FROM order_t ordr 
INNER JOIN customer_t cust
	ON ordr.customer_id = cust.customer_id
GROUP BY 1
ORDER BY 2 DESC;


-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q10] What is the average time taken to ship the placed orders for each quarters?
	Hint: Use the datediff function to find the difference between the ship date and the order date.
*/

SELECT 
      quarter_number AS "Quarter Number", 
      AVG(DATEDIFF(ship_date, order_date)) AS "Average Shipping Time"
FROM order_t AS ordr
GROUP BY ordr.quarter_number
ORDER BY ordr.quarter_number;

-- --------------------------------------------------------Done----------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------------------------------



