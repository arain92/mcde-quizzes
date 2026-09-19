------------QUIZ#01-----------------
-----------------Q1-----------------
SELECT
    o.order_id,
    c.first_name + ' ' + c.last_name AS customer_name,
    s.store_name,
    st.first_name + ' ' + st.last_name AS staff_name
FROM sales.orders o
INNER JOIN sales.customers c
    ON o.customer_id = c.customer_id
INNER JOIN sales.stores s
    ON o.store_id = s.store_id
INNER JOIN sales.staffs st
    ON o.staff_id = st.staff_id;



-----------Q2----------


SELECT
    p.product_name,
    b.brand_name,
    c.category_name
FROM production.products p
LEFT JOIN production.brands b
    ON p.brand_id = b.brand_id
LEFT JOIN production.categories c
    ON p.category_id = c.category_id;


-----------------------Q3--------------
SELECT * FROM sales.customers
SELECT * FROM sales.orders


SELECT 
c.first_name,
c.email,
c.city
FROM sales.customers c
LEFT JOIN sales.orders o
ON c.customer_id = o.customer_id
WHERE  o.customer_id is NULL



---------------------Q4--------------------


SELECT
    s.store_id,
    s.store_name,
    SUM(
        oi.quantity * oi.list_price * (1 - oi.discount)
    ) AS total_revenue
FROM sales.stores s
JOIN sales.orders o
    ON s.store_id = o.store_id
JOIN sales.order_items oi
    ON o.order_id = oi.order_id
GROUP BY
    s.store_id,
    s.store_name
ORDER BY total_revenue DESC;



------------------Q5---------------

SELECT
    b.brand_name,
    COUNT(p.product_id) AS product_count,
    AVG(p.list_price) AS average_price,
    MAX(p.list_price) AS highest_price
FROM production.brands b
JOIN production.products p
    ON b.brand_id = p.brand_id
GROUP BY
    b.brand_name
HAVING COUNT(p.product_id) > 5;

----------------Q6-------------

SELECT
    MONTH(o.order_date) AS order_month,
    COUNT(DISTINCT o.order_id) AS number_of_orders,
    SUM(
        oi.quantity * oi.list_price * (1 - oi.discount)
    ) AS total_revenue
FROM sales.orders o
JOIN sales.order_items oi
    ON o.order_id = oi.order_id
WHERE YEAR(o.order_date) = 2017
GROUP BY MONTH(o.order_date)
ORDER BY order_month;

--------------------------Q7-------------------
SELECT
    p.product_name,
    p.list_price,
    p.category_id
FROM production.products p
WHERE p.list_price >
(
    SELECT AVG(p2.list_price)
    FROM production.products p2
    WHERE p2.category_id = p.category_id
);


--------------------------Q8------------


SELECT
    c.customer_id,
    c.first_name + ' ' + c.last_name AS customer_name,
    COUNT(o.order_id) AS order_count
FROM sales.customers c
JOIN sales.orders o
    ON c.customer_id = o.customer_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
HAVING COUNT(o.order_id) >
(
    SELECT AVG(order_count)
    FROM
    (
        SELECT
            customer_id,
            COUNT(*) AS order_count
        FROM sales.orders
        GROUP BY customer_id
    ) AS customer_orders
);



--------------------------Q9-----------------------

WITH customer_spending AS
(
    SELECT
        c.customer_id,
        c.first_name + ' ' + c.last_name AS customer_name,
        SUM(
            oi.quantity * oi.list_price * (1 - oi.discount)
        ) AS total_spend
    FROM sales.customers c
    JOIN sales.orders o
        ON c.customer_id = o.customer_id
    JOIN sales.order_items oi
        ON o.order_id = oi.order_id
    GROUP BY
        c.customer_id,
        c.first_name,
        c.last_name
),
customer_labels AS
(
    SELECT
        customer_id,
        customer_name,
        total_spend,
        CASE
            WHEN total_spend >
                (SELECT AVG(total_spend)
                 FROM customer_spending)
            THEN 'High'
            ELSE 'Regular'
        END AS customer_type
    FROM customer_spending
)
SELECT TOP 10
    customer_id,
    customer_name,
    total_spend,
    customer_type,
    RANK() OVER (
        ORDER BY total_spend DESC
    ) AS customer_rank
FROM customer_labels
ORDER BY total_spend DESC;









--------------------------------------Q10----------------------



WITH product_sales AS
(
    SELECT
        p.product_id,
        p.product_name,
        p.category_id,
        SUM(oi.quantity) AS total_quantity
    FROM production.products p
    JOIN sales.order_items oi
        ON p.product_id = oi.product_id
    GROUP BY
        p.product_id,
        p.product_name,
        p.category_id
),
ranked_products AS
(
    SELECT
        product_id,
        product_name,
        category_id,
        total_quantity,
        ROW_NUMBER() OVER (
            PARTITION BY category_id
            ORDER BY total_quantity DESC
        ) AS product_rank
    FROM product_sales
),
best_products AS
(
    SELECT
        product_id,
        product_name,
        category_id,
        total_quantity
    FROM ranked_products
    WHERE product_rank = 1
)
SELECT
    bp.category_id,
    bp.product_name,
    bp.total_quantity,
    SUM(s.quantity) AS available_stock
FROM best_products bp
JOIN production.stocks s
    ON bp.product_id = s.product_id
GROUP BY
    bp.category_id,
    bp.product_name,
    bp.total_quantity
ORDER BY bp.category_id;

--------Bonus 1 — Q8 using CTE-----------------------


WITH customer_orders AS
(
    SELECT
        customer_id,
        COUNT(*) AS order_count
    FROM sales.orders
    GROUP BY customer_id
),
average_orders AS
(
    SELECT
        AVG(order_count) AS avg_order_count
    FROM customer_orders
)
SELECT
    c.customer_id,
    c.first_name + ' ' + c.last_name AS customer_name,
    co.order_count
FROM customer_orders co
JOIN sales.customers c
    ON co.customer_id = c.customer_id
CROSS JOIN average_orders ao
WHERE co.order_count > ao.avg_order_count;

-------Bonus 2 — Q8 using CTE-------------------------
WITH store_revenue AS
(
    SELECT
        s.store_id,
        s.store_name,
        SUM(
            oi.quantity * oi.list_price * (1 - oi.discount)
        ) AS total_revenue
    FROM sales.stores s
    JOIN sales.orders o
        ON s.store_id = o.store_id
    JOIN sales.order_items oi
        ON o.order_id = oi.order_id
    GROUP BY
        s.store_id,
        s.store_name
)
SELECT
    store_name,
    total_revenue,
    total_revenue * 100.0 /
        SUM(total_revenue) OVER () AS revenue_percentage
FROM store_revenue
ORDER BY total_revenue DESC;



