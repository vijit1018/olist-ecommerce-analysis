SELECT 'customers' AS tabl, COUNT(*) FROM customers
UNION ALL SELECT 'geolocation', COUNT(*) FROM geolocation
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL SELECT 'order_reviews', COUNT(*) FROM order_reviews
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL SELECT 'category_translation', COUNT(*) FROM category_translation;

select count(*) AS "Total Orders" from orders;
select sum(payment_value) as "Total Revenue" from order_payments;
select count(*) as "Total Customers" from customers; 
-- Headline numbers
SELECT 
	COUNT(DISTINCT o.order_id) AS total_orders,
	ROUND(SUM(oi.price), 2) AS total_revenue,
	COUNT(DISTINCT c.customer_unique_id) AS total_customers
fROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status NOT IN ('canceled', 'unavailable');
-- Monthly revenue & orders
SELECT
	DATE_TRUNC('month', o.order_purchase_timestamp)::date AS month,
	count(DISTINCT o.order_id) AS orders,
	ROUND(SUM(oi.price), 2) AS revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
AND o.order_purchase_timestamp >= '2017-01-01'
AND o.order_purchase_timestamp < '2018-09-01'
GROUP BY 1
ORDER BY 1;
-- Top 10 categories by Revenue
SELECT
	COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category,
	count(DISTINCT oi.order_id) as orders,
	ROUND(SUM(oi.price), 2) as revenue
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN category_translation t ON p.product_category_name = t.product_category_name
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY category
ORDER BY revenue DESC
LIMIT 10;

--Revenue by customer state
SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS orders,
    ROUND(SUM(oi.price), 2)    AS revenue,
    ROUND(100.0 * SUM(oi.price) / SUM(SUM(oi.price)) OVER (), 1) AS pct_of_total
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN customers c    ON o.customer_id = c.customer_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY c.customer_state
ORDER BY revenue DESC;

--Payment type distribution 
SELECT
	payment_type,
	COUNT(DISTINCT order_id) AS orders,
	ROUND(SUM(payment_value), 2) AS total_paid,
	ROUND(AVG(payment_value), 2) AS avg_payment,
	ROUND(AVG(payment_installments), 1) AS avg_installments
FROM order_payments
GROUP BY payment_type
ORDER BY orders DESC;
--Summarizing orders count and avg items for the orders by their price range.
WITH order_size AS (
SELECT order_id, COUNT(*) AS items, SUM(price) AS order_value
FROM order_items
GROUP BY order_id
)
SELECT 
	CASE WHEN order_value < 50 THEN '1. Under 50'
		 WHEN order_value < 150 THEN '2. 50-150'
		 WHEN order_value < 500 THEN '3. 150-500'
		 ELSE '4. 500+' END AS value_band,
		 COUNT(*) AS orders,
		 ROUND(avg(items),2) AS avg_items
	FROM order_size
	GROUP BY 1
	ORDER BY 1;