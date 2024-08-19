--1)Retrieve the total number of orders placed.
SELECT COUNT(order_id) 
AS total_orders
FROM orders;



--2)Calculate the total revenue generated from pizza sales.
SELECT SUM(od.quantity * p.price) AS total_revenue
FROM order_details od
INNER JOIN pizzas p ON od.pizza_id = p.pizza_id;


--3)Identify the highest-priced pizza.
SELECT pizza_id, name, price
FROM pizzas
ORDER BY price DESC
LIMIT 1;



--4)Identify the most common pizza size ordered.
SELECT p.size, COUNT(od.order_id) AS order_count
FROM order_details od
INNER JOIN pizzas p ON od.pizza_id = p.pizza_id
GROUP BY p.size
ORDER BY order_count DESC
LIMIT 1;



--5)List the top 5 most ordered pizza types along with their quantities.
SELECT pt.name AS pizza_type, SUM(od.quantity) AS total_quantity
FROM order_details od
INNER JOIN pizzas p ON od.pizza_id = p.pizza_id
INNER JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name
ORDER BY total_quantity DESC
LIMIT 5;



--6)find the total quantity of each pizza category ordered.
Select public.pizza_types.category,Sum (public.order_details.quantity)
From pizzas
Join order_details ON pizzas.pizza_id =order_details.pizza_id
Join pizza_types ON pizza_types.pizza_type_id = pizzas.pizza_type_id
Group by 1
order by 2 desc 



--7)Determine the distribution of orders by hour of the day.
SELECT 
    EXTRACT(HOUR FROM orders.time) AS order_hour,
    COUNT(orders.order_id) AS order_count
FROM 
    orders
GROUP BY 
    order_hour
ORDER BY 
    order_hour;



--8)find the category-wise distribution of pizzas
SELECT pt.category, COUNT(p.pizza_id) AS pizza_count
FROM pizzas p
INNER JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.category
ORDER BY pizza_count DESC;


--9)Group the orders by date and calculate the average number of pizzas ordered per day.
SELECT 
    orders.date,
    AVG(daily_order_counts.total_pizzas) AS average_pizzas_per_day
FROM 
    orders
JOIN 
    (
        SELECT 
            orders.date,
            SUM(order_details.quantity) AS total_pizzas
        FROM 
            orders
        JOIN 
            order_details ON orders.order_id = order_details.order_id
        GROUP BY 
            orders.date
    ) AS daily_order_counts ON orders.date = daily_order_counts.date
GROUP BY 
    orders.date
ORDER BY 
    orders.date;






--10)Determine the top 3 most ordered pizza types based on revenue/Calculate the revenue for each pizza type and determine the top 3

WITH pizza_revenue 
AS 
(SELECT 
pt.pizza_type_id,
pt.name AS pizza_type_name,
SUM(od.quantity * p.price) AS total_revenue
FROM order_details od
JOIN  pizzas p ON od.pizza_id = p.pizza_id
JOIN  pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY  pt.pizza_type_id, pt.name)
SELECT 
pizza_type_name,
total_revenue
FROM 
pizza_revenue
ORDER BY total_revenue DESC
LIMIT 3;



--11)percentage contribution of each pizza type to total revenue 
WITH pizza_revenue AS (
SELECT pt.pizza_type_id, pt.name AS pizza_type_name, SUM(od.quantity * p.price) AS total_revenue
FROM order_details od
INNER JOIN pizzas p ON od.pizza_id = p.pizza_id
INNER JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.pizza_type_id, pt.name
),

total_revenue_sum AS
(SELECT SUM(total_revenue) AS grand_total
FROM pizza_revenue)

SELECT pr.pizza_type_name, pr.total_revenue, Round((pr.total_revenue / trs.grand_total) * 100,2) AS percentage_contribution
FROM pizza_revenue pr, total_revenue_sum trs
ORDER BY percentage_contribution DESC;



--12)Analyze the cumulative revenue generated over time.
WITH daily_revenue AS (
SELECT o.date, SUM(od.quantity * p.price) AS daily_total
FROM orders o
INNER JOIN order_details od ON o.order_id = od.order_id
INNER JOIN pizzas p ON od.pizza_id = p.pizza_id
GROUP BY o.date
ORDER BY o.date
)

SELECT date, daily_total,
SUM(daily_total) OVER (ORDER BY date) AS cumulative_revenue
FROM daily_revenue;



--13)Determine the top 3 most ordered pizza types based on revenue for each pizza category.
WITH pizza_revenue AS (
SELECT pt.category, pt.name AS pizza_type_name, 
SUM(od.quantity * p.price) AS total_revenue,
RANK() OVER (PARTITION BY pt.category ORDER BY SUM(od.quantity * p.price) DESC) AS rank_within_category
FROM order_details od
INNER JOIN pizzas p ON od.pizza_id = p.pizza_id
INNER JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.category, pt.name
)

SELECT category, pizza_type_name, total_revenue
FROM pizza_revenue
WHERE rank_within_category <= 3
ORDER BY category, rank_within_category;



--14)Customer Segmentation by Order Frequency:
SELECT 
    CASE 
        WHEN order_count BETWEEN 1 AND 2 THEN '1-2 Orders'
        WHEN order_count BETWEEN 3 AND 5 THEN '3-5 Orders'
        ELSE '6+ Orders'
    END AS order_frequency_segment,
    COUNT(order_id) AS customer_count
FROM (
    SELECT order_id, COUNT(order_id) AS order_count
    FROM orders
    GROUP BY order_id
) AS customer_orders
GROUP BY order_frequency_segment
ORDER BY order_frequency_segment;
