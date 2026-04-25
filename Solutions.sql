-- Q1. What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, SUM(m.price) as total_amount
FROM sales s
JOIN menu m ON s.product_id = m.product_id
GROUP BY s.customer_id;


---Q2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date) FROM sales
GROUP BY customer_id;


--Q3. What was the first item from the menu purchased by each customer?
WITH firstOrder AS( 
	SELECT 
			s.customer_id,
			m.product_name, 
			s.order_date, 
			DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS rank
			FROM sales s
			JOIN menu m on s.product_id  = m.product_id
)
SELECT 
		customer_id,
		product_name
FROM firstOrder
WHERE rank=1
GROUP BY  customer_id, product_name;



-- Q4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT 
    m.product_name, 
    COUNT(s.product_id) AS order_count
FROM sales s
JOIN menu m ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY order_count DESC -- Sorts from highest to lowest
LIMIT 1;                 -- Keeps only the top row


--Q5. Which item was the most popular for each customer?
WITH PopularItems AS (
    SELECT 
        s.customer_id, 
        m.product_name, 
        COUNT(s.product_id) AS order_count,
        DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) as rank
    FROM sales s
    JOIN menu m ON s.product_id = m.product_id
    GROUP BY s.customer_id, m.product_name
)
SELECT 
    customer_id, 
    product_name, 
    order_count
FROM PopularItems
WHERE rank = 1;


-- Q6. Which item was purchased first by the customer after they became a member?
WITH memberFirstOrder AS(
		SELECT s.customer_id,
               s.order_date,
			   mu.product_name,
			   RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date ASC) as rnk
			   FROM sales s 
			   JOIN members m ON s.customer_id = m.customer_id
			   JOIN MENU mu ON s.product_id = mu.product_id
			   WHERE s.order_date >= m.join_date
)
select customer_id, product_name FROM memberFirstOrder WHERE rnk=1;



--Q7. Which item was purchased just before the customer became a member?
WITH beforeMemberOrder AS(
		SELECT s.customer_id,
			   s.order_date,
			   mu.product_name,
			   RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) as rk
			   FROM sales s 
			   JOIN members m on s.customer_id = m.customer_id
			   JOIN menu mu on s.product_id = mu.product_id
			   WHERE s.order_date < m.join_date
)
select customer_id, product_name FROM beforeMemberOrder WHERE rk=1;


--Q8. What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id, COUNT(s.product_id) AS total_items_ordered, SUM(mu.price) AS amount_spent  FROM sales s 
FULL JOIN menu mu ON s.product_id = mu.product_id
FULL JOIN members m ON s.customer_id = m.customer_id
WHERE m.join_date IS NULL OR s.order_date < m.join_date
GROUP BY s.customer_id;


-- Q9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier 
-- how many points would each customer have?
SELECT s.customer_id,
	   SUM(
			CASE
			WHEN mu.product_name='sushi' THEN mu.price*20
			ELSE mu.price*10
			END
	   ) AS total_points
FROM sales s
JOIN menu mu  ON s.product_id=mu.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;
	   

--Q10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items,
-- not just sushi - how many points do customer A and B have at the end of January?
SELECT s.customer_id,
	   SUM(
			CASE 
			--1. The Magic Week : Everythings gets 2x points
				WHEN s.order_date>=m.join_date 
				AND s.order_date < m.join_date + INTERVAL '7 days' THEN mu.price*20
			--2. Normal Days -- Sushi stills gets 2x points
				WHEN mu.product_name = 'sushi' THEN mu.price*20
			--3. Normal Days -- Everything else gets 1x points
				ELSE mu.price*10
			END 
	   ) AS total_points
FROM sales s 
JOIN menu mu ON s.product_id = mu.product_id
JOIN members m ON s.customer_id = m.customer_id
GROUP BY s.customer_id
ORDER BY s.customer_id;