-- Basic Queries

-- 1. Find the top 10 most frequently purchased products.
SELECT oi.product_id, p.product_category, 
	COUNT(oi.product_id) AS freq_purchased
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
GROUP BY oi.product_id, p.product_category
ORDER BY freq_purchased DESC
LIMIT 10;

-- 2. List the number of sellers operating in each state.
SELECT seller_state, 
	COUNT(DISTINCT seller_id) AS num_sellers
FROM sellers
GROUP BY seller_state
ORDER BY num_sellers DESC;

-- 3. Find the number of products listed in each category.
SELECT product_category, 
	COUNT(*) AS total_products
FROM products
WHERE product_category IS NOT NULL
GROUP BY product_category
ORDER BY total_products DESC;

-- 4. Find the total sales per category.
 -- I have included shipping cost as well.
SELECT p.product_category AS product_category, ROUND(SUM(oi.price + oi.freight_value),2) AS category_sales
FROM products p
JOIN order_items oi ON oi.product_id = p.product_id
GROUP BY p.product_category
ORDER BY category_sales DESC;

-- 5. Calculate the percentage of orders that were paid in installments.
SELECT 
COUNT((CASE WHEN payment_installments > 1 THEN order_id END))*100/COUNT(*) AS perc_of_installment_orders
FROM payments;

-- Intermediate Queries

-- 1. Calculate the average delivery time (difference between order purchase and delivery) by state.
SELECT c.customer_state, 
	AVG(datediff(o.order_delivered_customer_date, o.order_purchase_timestamp)) AS avg_delivery_time_days
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_delivery_time_days;


-- 2. Identify the top 5 product categories with the highest return rate.
-- To get different order status to decide which comes under returns.
SELECT DISTINCT order_status, 
	COUNT(*) AS num_orders
FROM orders
GROUP BY order_status;

-- For this analysis, assuming all order status other than delivered as returns/not delivered.
SELECT p.product_category AS top_return_product_category, 
	CONCAT(ROUND(COUNT(CASE WHEN o.order_status <> 'delivered' THEN 1 END)*100/ COUNT(*),2),'%') AS return_rate
FROM products p
JOIN order_items oi ON oi.product_id = p.product_id
JOIN orders o ON o.order_id = oi.order_id
WHERE p.product_category IS NOT NULL
GROUP BY p.product_category
ORDER BY COUNT(CASE WHEN o.order_status <> 'delivered' THEN 1 END)/ COUNT(*) DESC 
-- need for this instead return_rate in ORDER BY is because with concat of % retun_rate becomes string and hence sorts incorrectly
LIMIT 5;

-- 3. Find the relationship between installment payments and order value (average order value when paid in installments vs. full payment).
/*
In the payments table one order(i.e. one order_id) has multiple rows and they are not for different installments,
instead different payment_type i.e. customer has choosen to pay using different method
(credit card + multiple vouchers or UPI + multiple vouchers) for that order even if done in one-installment(full_payment at once).
For better understanding run the below query,
and match the total_payment_for_order_id with order_items table for a specific order_id

SELECT *,
	COUNT(*) OVER(PARTITION BY order_id) AS count_order_id,
	SUM(payment_value) OVER(PARTITION BY order_id) AS total_payment_for_order_id
FROM payments
ORDER BY count_order_id DESC, order_id, payment_sequential;

-- matching in order_items
SELECT * 
FROM order_items
WHERE order_id = 'fa65dad1b0e818e3ccc5cb0e39231352';
*/
WITH order_payments AS (
	SELECT order_id,
		-- Handling 2 outlier rows with '0' installments and treating them as '1'
        CASE WHEN MAX(payment_installments) = 0 THEN 1 
			ELSE MAX(payment_installments) 
		END AS installments,
        SUM(payment_value) AS total_payment
    FROM payments
    GROUP BY order_id
)
SELECT installments,
	ROUND(AVG(total_payment), 2) AS avg_order_value,
    COUNT(order_id) AS 'num_orders'
FROM order_payments
GROUP BY installments
ORDER BY installments;

-- 4. Find the average number of products per order, grouped by customer state.
WITH state_order_items AS (
	SELECT c.customer_state, oi.order_id, 
		COUNT(*) AS num_items
	FROM order_items oi
	JOIN orders o ON o.order_id = oi.order_id
	JOIN customers c ON c.customer_id = o.customer_id
	GROUP BY c.customer_state, oi.order_id
)
SELECT customer_state, 
	AVG(num_items) AS avg_items_per_order
FROM state_order_items
GROUP BY customer_state
ORDER BY avg_items_per_order DESC;

-- 5. Calculate the percentage of total revenue contributed by each product category.
SELECT p.product_category, 
    ROUND(SUM(oi.price)*100/(SELECT SUM(price) FROM order_items),2) AS perc_contribution_in_sales
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
GROUP BY p.product_category
ORDER BY perc_contribution_in_sales DESC;

-- Advanced Queries

-- 1. Distribute the orders across spend tiers (Very Low, Low, Medium, High, Very High).
-- Let's create a grouped frequency distribution table first to get appropriate spending groups
WITH order_totals AS (
    SELECT o.order_id,
        SUM(p.payment_value) AS total_order_value
    FROM orders o
    JOIN payments p ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY o.order_id
)
SELECT 
    CONCAT(FLOOR(total_order_value/100)*100, '-', FLOOR(total_order_value/100)*100 + 99) AS value_range,
    COUNT(*) AS order_count
FROM order_totals
GROUP BY FLOOR(total_order_value/100)
ORDER BY FLOOR(total_order_value/100);

-- On basis of above table clustering orders into 5 tiers as:-
WITH order_totals AS (
    SELECT o.order_id,
		SUM(p.payment_value) AS total_order_value
    FROM orders o
    JOIN payments p ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY o.order_id
),
order_tiers AS (
    SELECT order_id,
        CASE 
            WHEN total_order_value < 50 THEN 'Very Low'
            WHEN total_order_value BETWEEN 50 AND 100 THEN 'Low'
            WHEN total_order_value BETWEEN 100 AND 300 THEN 'Medium'
            WHEN total_order_value BETWEEN 300 AND 500 THEN 'High'
            ELSE 'Very High'
        END AS spend_tier
    FROM order_totals
)
SELECT spend_tier,
    COUNT(*) AS order_count,
    CONCAT(ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2),'%') AS percentage_distribution
FROM order_tiers
GROUP BY spend_tier
ORDER BY -- custom sorting
    CASE spend_tier
        WHEN 'Very Low' THEN 1
        WHEN 'Low' THEN 2
        WHEN 'Medium' THEN 3
        WHEN 'High' THEN 4
        WHEN 'Very High' THEN 5
    END;


-- 2. Find top 5 sellers' market share in each category.
WITH seller_category_sales AS(
	SELECT p.product_category, oi.seller_id,
		ROUND(SUM(oi.price + oi.freight_value),2) AS seller_category_sale,
        DENSE_RANK() OVER(PARTITION BY p.product_category ORDER BY SUM(oi.price + oi.freight_value) DESC) AS seller_rank
    FROM order_items oi
	JOIN products p ON p.product_id = oi.product_id
	WHERE p.product_category IS NOT NULL
	GROUP BY p.product_category, oi.seller_id
)
SELECT product_category, seller_id, seller_category_sale,
    seller_rank,
	ROUND(seller_category_sale*100/SUM(seller_category_sale) OVER(PARTITION BY product_category),2) AS market_share_perc
FROM seller_category_sales
WHERE seller_rank <= 5
ORDER BY product_category, seller_category_sale DESC;

-- CTE could be avoided here by calculating market_share directly in select without using CTE, but for better readability I used CTE

-- 3. Calculate the month_on_month growth rate of total sales.
WITH monthly_sales AS (
SELECT 
	YEAR(o.order_purchase_timestamp) AS year, 
    MONTH(o.order_purchase_timestamp) AS month_num, 
    MONTHNAME(o.order_purchase_timestamp) AS month,
    ROUND(SUM(p.payment_value),2) AS monthly_sales
FROM orders o 
JOIN payments p ON p.order_id = o.order_id
GROUP BY year, month_num, month
ORDER BY year, month_num
)
SELECT year, month, monthly_sales,
    LAG(monthly_sales,1) OVER(ORDER BY year, month_num) AS prev_month_sale,
    ROUND((monthly_sales - LAG(monthly_sales,1) OVER(ORDER BY year, month_num))*100/LAG(monthly_sales,1) OVER(ORDER BY year, month_num),2) AS
    Mom_growth
    FROM monthly_sales;

-- 4. Calculate the cumulative sales per month for each year.
WITH monthly_sales AS (
SELECT 
	YEAR(o.order_purchase_timestamp) AS year, 
    MONTH(o.order_purchase_timestamp) AS month_num, 
    MONTHNAME(o.order_purchase_timestamp) AS month,
    ROUND(SUM(p.payment_value),2) AS monthly_sales
FROM orders o 
JOIN payments p ON p.order_id = o.order_id
GROUP BY year, month_num, month
ORDER BY year, month_num
)
SELECT 
	CONCAT(month,' ', year) AS Month,
    monthly_sales,
    ROUND(SUM(monthly_sales) OVER(PARTITION BY year ORDER BY month_num),2) AS monthly_cumulative_sales    
FROM monthly_sales
ORDER BY year, month_num;
    
-- 5. Statewise Delivery performance (Eary, On Time, Late).
WITH delivery_performance AS (
    SELECT c.customer_state,
        CASE 
            WHEN DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) < 0 THEN 'Early'
            WHEN DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) = 0 THEN 'On Time'
            ELSE 'Late'
        END AS delivery_status
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
)
SELECT customer_state, delivery_status,
    COUNT(*) AS orders_count,
    ROUND(COUNT(*)*100.0 / SUM(COUNT(*)) OVER(PARTITION BY customer_state), 2) AS percentage
FROM delivery_performance
GROUP BY customer_state, delivery_status
ORDER BY customer_state, delivery_status;
