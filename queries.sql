-- ============================================================
--  queries.sql
--  Basic & Complex Queries — Shopping Cart Management System
--  Author: Udit Asthana (240905310), CSE-D
-- ============================================================

-- ════════════════════════════════════════════════════════════
--  SECTION A: BASIC QUERIES
-- ════════════════════════════════════════════════════════════

-- Q1. List all books with their author and publisher
SELECT b.isbn, b.title, b.year, b.price, b.genre,
       a.name AS author, p.name AS publisher
FROM   BOOK b
JOIN   AUTHOR    a ON a.name = b.author_name
JOIN   PUBLISHER p ON p.name = b.publisher_name
ORDER  BY b.title;

-- Q2. View all items currently in a specific customer's active cart (cust_id = 1)
SELECT c.cart_id, b.isbn, b.title, b.price,
       ci.quantity,
       (b.price * ci.quantity) AS line_total
FROM   CART c
JOIN   CART_ITEMS ci ON ci.cart_id = c.cart_id
JOIN   BOOK b        ON b.isbn     = ci.isbn
WHERE  c.cust_id = 1
AND    c.status  = 'ACTIVE';

-- Q3. Check total stock of a book across all warehouses
SELECT b.title, SUM(i.quantity) AS total_stock
FROM   INVENTORY i
JOIN   BOOK b ON b.isbn = i.isbn
GROUP  BY b.title
ORDER  BY total_stock DESC;

-- Q4. List all customers with their registration date
SELECT cust_id, name, email, phone, created_at
FROM   CUSTOMER
ORDER  BY created_at DESC;

-- Q5. Find all books priced below 700
SELECT isbn, title, price, genre
FROM   BOOK
WHERE  price < 700
ORDER  BY price;

-- Q6. Get order history for a specific customer (cust_id = 2)
SELECT o.order_id, o.order_date, o.total_amount, o.status,
       pay.method AS payment_method, pay.status AS payment_status
FROM   ORDERS  o
LEFT JOIN PAYMENT pay ON pay.order_id = o.order_id
WHERE  o.cust_id = 2
ORDER  BY o.order_date DESC;

-- Q7. List all books stocked in a specific warehouse (WH-BLR)
SELECT b.title, b.author_name, i.quantity
FROM   INVENTORY i
JOIN   BOOK b ON b.isbn = i.isbn
WHERE  i.warehouse_code = 'WH-BLR'
ORDER  BY i.quantity DESC;

-- ════════════════════════════════════════════════════════════
--  SECTION B: COMPLEX QUERIES
-- ════════════════════════════════════════════════════════════

-- Q8. Cart summary: total items and cart value per active cart
SELECT  cu.name AS customer,
        c.cart_id,
        COUNT(ci.isbn)             AS distinct_titles,
        SUM(ci.quantity)           AS total_books,
        SUM(b.price * ci.quantity) AS cart_value
FROM    CART       c
JOIN    CUSTOMER   cu ON cu.cust_id  = c.cust_id
JOIN    CART_ITEMS ci ON ci.cart_id  = c.cart_id
JOIN    BOOK       b  ON b.isbn      = ci.isbn
WHERE   c.status = 'ACTIVE'
GROUP   BY cu.name, c.cart_id
ORDER   BY cart_value DESC;

-- Q9. Availability check: can a customer's cart be fully fulfilled?
--     (Checks if total inventory >= quantity wanted for each item in cart_id=1)
SELECT  b.title,
        ci.quantity           AS qty_wanted,
        NVL(SUM(i.quantity),0) AS total_available,
        CASE
            WHEN NVL(SUM(i.quantity),0) >= ci.quantity THEN 'IN STOCK'
            WHEN NVL(SUM(i.quantity),0) > 0            THEN 'PARTIAL'
            ELSE                                             'OUT OF STOCK'
        END AS availability
FROM    CART_ITEMS ci
JOIN    BOOK       b  ON b.isbn  = ci.isbn
LEFT JOIN INVENTORY i ON i.isbn  = ci.isbn
WHERE   ci.cart_id = 1
GROUP   BY b.title, ci.quantity;

-- Q10. Most popular books by order volume
SELECT  b.title, b.author_name,
        SUM(oi.quantity)  AS total_units_sold,
        COUNT(DISTINCT o.order_id) AS times_ordered
FROM    ORDER_ITEMS oi
JOIN    BOOK        b  ON b.isbn     = oi.isbn
JOIN    ORDERS      o  ON o.order_id = oi.order_id
WHERE   o.status != 'CANCELLED'
GROUP   BY b.title, b.author_name
ORDER   BY total_units_sold DESC;

-- Q11. Revenue per publisher (from completed orders)
SELECT  p.name AS publisher,
        COUNT(DISTINCT o.order_id)  AS total_orders,
        SUM(oi.quantity)            AS books_sold,
        SUM(oi.price_at_order * oi.quantity) AS revenue
FROM    ORDER_ITEMS oi
JOIN    BOOK        b  ON b.isbn          = oi.isbn
JOIN    PUBLISHER   p  ON p.name          = b.publisher_name
JOIN    ORDERS      o  ON o.order_id      = oi.order_id
WHERE   o.status IN ('PLACED','SHIPPED','DELIVERED')
GROUP   BY p.name
ORDER   BY revenue DESC;

-- Q12. Customers who have an active cart but have NEVER placed an order
SELECT  cu.cust_id, cu.name, cu.email, c.cart_id, c.created_at AS cart_since
FROM    CUSTOMER cu
JOIN    CART     c  ON c.cust_id = cu.cust_id
WHERE   c.status = 'ACTIVE'
AND     cu.cust_id NOT IN (
            SELECT DISTINCT cust_id FROM ORDERS
        )
ORDER   BY c.created_at;

-- Q13. Books in carts but with low inventory (potential stock risk)
--      Flags books where total carted quantity >= 50% of available stock
SELECT  b.title,
        SUM(ci.quantity)            AS qty_in_active_carts,
        NVL(SUM(DISTINCT i.quantity),0) AS total_stock,
        ROUND(SUM(ci.quantity) / NULLIF(SUM(i.quantity),0) * 100, 1) AS demand_pct
FROM    CART_ITEMS ci
JOIN    CART       c  ON c.cart_id = ci.cart_id AND c.status = 'ACTIVE'
JOIN    BOOK       b  ON b.isbn    = ci.isbn
LEFT JOIN INVENTORY i ON i.isbn    = ci.isbn
GROUP   BY b.title
HAVING  SUM(ci.quantity) >= 0.5 * NULLIF(SUM(i.quantity),0)
ORDER   BY demand_pct DESC;

-- Q14. Full order receipt view — joins 5 tables
SELECT  o.order_id,
        cu.name            AS customer,
        cu.email,
        b.title            AS book,
        oi.quantity,
        oi.price_at_order  AS unit_price,
        (oi.quantity * oi.price_at_order) AS subtotal,
        o.total_amount,
        pay.method         AS paid_via,
        pay.status         AS payment_status,
        o.status           AS order_status
FROM    ORDERS      o
JOIN    CUSTOMER    cu  ON cu.cust_id  = o.cust_id
JOIN    ORDER_ITEMS oi  ON oi.order_id = o.order_id
JOIN    BOOK        b   ON b.isbn      = oi.isbn
LEFT JOIN PAYMENT   pay ON pay.order_id = o.order_id
ORDER   BY o.order_id, b.title;

-- Q15. Genre-wise average price and count using GROUP BY + HAVING
SELECT  genre,
        COUNT(*)              AS book_count,
        ROUND(AVG(price), 2)  AS avg_price,
        MIN(price)            AS min_price,
        MAX(price)            AS max_price
FROM    BOOK
GROUP   BY genre
HAVING  COUNT(*) > 1
ORDER   BY avg_price DESC;
