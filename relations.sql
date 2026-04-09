-- ============================================================
--  relations.sql
--  Sample data for Shopping Cart Management System
--  Run AFTER schema_setup.sql
--  Author: Udit Asthana (240905310), CSE-D
-- ============================================================

-- ── 1. AUTHORS ────────────────────────────────────────────────
INSERT INTO AUTHOR (name, address, url) VALUES ('Silberschatz', 'Yale University, USA', 'https://yale.edu/silberschatz');
INSERT INTO AUTHOR (name, address, url) VALUES ('Korth', 'Lehigh University, USA', 'https://lehigh.edu/korth');
INSERT INTO AUTHOR (name, address, url) VALUES ('Robert C. Martin', 'Chicago, USA', 'https://cleancoder.com');
INSERT INTO AUTHOR (name, address, url) VALUES ('Andrew Tanenbaum', 'Amsterdam, Netherlands', 'https://cs.vu.nl/~ast');
INSERT INTO AUTHOR (name, address, url) VALUES ('Yuval Noah Harari', 'Jerusalem, Israel', 'https://ynharari.com');

-- ── 2. PUBLISHERS ─────────────────────────────────────────────
INSERT INTO PUBLISHER (name, address, phone, url) VALUES ('McGraw-Hill', 'New York, USA', '+1-212-512-2000', 'https://mheducation.com');
INSERT INTO PUBLISHER (name, address, phone, url) VALUES ('Prentice Hall', 'New Jersey, USA', '+1-201-236-7000', 'https://pearson.com');
INSERT INTO PUBLISHER (name, address, phone, url) VALUES ('Pearson', 'London, UK', '+44-20-3771-5000', 'https://pearson.com');
INSERT INTO PUBLISHER (name, address, phone, url) VALUES ('Harper Collins', 'New York, USA', '+1-212-207-7000', 'https://harpercollins.com');

-- ── 3. BOOKS ──────────────────────────────────────────────────
INSERT INTO BOOK (isbn, title, year, price, genre, description, author_name, publisher_name)
VALUES ('978-0-07-352332-3', 'Database System Concepts', 2019, 899.00, 'Computer Science',
        'Comprehensive introduction to database systems', 'Silberschatz', 'McGraw-Hill');

INSERT INTO BOOK (isbn, title, year, price, genre, description, author_name, publisher_name)
VALUES ('978-0-13-468599-1', 'Operating System Concepts', 2018, 799.00, 'Computer Science',
        'Covers OS fundamentals with modern examples', 'Silberschatz', 'Prentice Hall');

INSERT INTO BOOK (isbn, title, year, price, genre, description, author_name, publisher_name)
VALUES ('978-0-13-235088-4', 'Clean Code', 2008, 649.00, 'Software Engineering',
        'A handbook of agile software craftsmanship', 'Robert C. Martin', 'Prentice Hall');

INSERT INTO BOOK (isbn, title, year, price, genre, description, author_name, publisher_name)
VALUES ('978-0-13-212227-1', 'Computer Networks', 2021, 749.00, 'Computer Science',
        'Top-down approach to modern networking', 'Andrew Tanenbaum', 'Pearson');

INSERT INTO BOOK (isbn, title, year, price, genre, description, author_name, publisher_name)
VALUES ('978-0-06-231609-7', 'Sapiens', 2015, 499.00, 'History',
        'A brief history of humankind', 'Yuval Noah Harari', 'Harper Collins');

INSERT INTO BOOK (isbn, title, year, price, genre, description, author_name, publisher_name)
VALUES ('978-0-06-244558-9', 'Homo Deus', 2017, 549.00, 'History',
        'A brief history of tomorrow', 'Yuval Noah Harari', 'Harper Collins');

-- ── 4. WAREHOUSES ─────────────────────────────────────────────
INSERT INTO WAREHOUSE (code, address, phone) VALUES ('WH-MUM', 'Andheri East, Mumbai, Maharashtra', '+91-22-4000-1111');
INSERT INTO WAREHOUSE (code, address, phone) VALUES ('WH-BLR', 'Whitefield, Bengaluru, Karnataka', '+91-80-4000-2222');
INSERT INTO WAREHOUSE (code, address, phone) VALUES ('WH-DEL', 'Okhla Phase II, New Delhi', '+91-11-4000-3333');

-- ── 5. INVENTORY ──────────────────────────────────────────────
INSERT INTO INVENTORY (warehouse_code, isbn, quantity) VALUES ('WH-MUM', '978-0-07-352332-3', 50);
INSERT INTO INVENTORY (warehouse_code, isbn, quantity) VALUES ('WH-MUM', '978-0-13-468599-1', 30);
INSERT INTO INVENTORY (warehouse_code, isbn, quantity) VALUES ('WH-MUM', '978-0-13-235088-4', 20);
INSERT INTO INVENTORY (warehouse_code, isbn, quantity) VALUES ('WH-BLR', '978-0-07-352332-3', 25);
INSERT INTO INVENTORY (warehouse_code, isbn, quantity) VALUES ('WH-BLR', '978-0-13-212227-1', 40);
INSERT INTO INVENTORY (warehouse_code, isbn, quantity) VALUES ('WH-BLR', '978-0-06-231609-7', 60);
INSERT INTO INVENTORY (warehouse_code, isbn, quantity) VALUES ('WH-DEL', '978-0-06-244558-9', 35);
INSERT INTO INVENTORY (warehouse_code, isbn, quantity) VALUES ('WH-DEL', '978-0-13-235088-4', 15);
INSERT INTO INVENTORY (warehouse_code, isbn, quantity) VALUES ('WH-DEL', '978-0-13-212227-1', 10);

-- ── 6. CUSTOMERS ──────────────────────────────────────────────
INSERT INTO CUSTOMER (email, name, address, phone, password_hash)
VALUES ('udit@example.com', 'Udit Asthana', 'MIT Manipal, Manipal, Karnataka', '+91-9876543210',
        'hashed_pw_001');
INSERT INTO CUSTOMER (email, name, address, phone, password_hash)
VALUES ('alice@example.com', 'Alice Sharma', 'Koramangala, Bengaluru', '+91-9123456780',
        'hashed_pw_002');
INSERT INTO CUSTOMER (email, name, address, phone, password_hash)
VALUES ('bob@example.com', 'Bob Nair', 'Bandra West, Mumbai', '+91-9988776655',
        'hashed_pw_003');
INSERT INTO CUSTOMER (email, name, address, phone, password_hash)
VALUES ('carol@example.com', 'Carol Mendes', 'Connaught Place, New Delhi', '+91-9871234560',
        'hashed_pw_004');

-- ── 7. CARTS ──────────────────────────────────────────────────
-- Udit: active cart
INSERT INTO CART (cust_id, status) VALUES (1, 'ACTIVE');
-- Alice: checked out cart
INSERT INTO CART (cust_id, status) VALUES (2, 'CHECKED_OUT');
-- Bob: active cart
INSERT INTO CART (cust_id, status) VALUES (3, 'ACTIVE');
-- Carol: abandoned
INSERT INTO CART (cust_id, status) VALUES (4, 'ABANDONED');
-- Alice: second active cart (new session after checkout)
INSERT INTO CART (cust_id, status) VALUES (2, 'ACTIVE');

-- ── 8. CART ITEMS ─────────────────────────────────────────────
-- Udit's cart (cart_id=1)
INSERT INTO CART_ITEMS (cart_id, isbn, quantity) VALUES (1, '978-0-07-352332-3', 1);
INSERT INTO CART_ITEMS (cart_id, isbn, quantity) VALUES (1, '978-0-13-235088-4', 2);

-- Alice's old checked-out cart (cart_id=2)
INSERT INTO CART_ITEMS (cart_id, isbn, quantity) VALUES (2, '978-0-06-231609-7', 1);
INSERT INTO CART_ITEMS (cart_id, isbn, quantity) VALUES (2, '978-0-06-244558-9', 1);

-- Bob's cart (cart_id=3)
INSERT INTO CART_ITEMS (cart_id, isbn, quantity) VALUES (3, '978-0-13-212227-1', 1);

-- Alice's new cart (cart_id=5)
INSERT INTO CART_ITEMS (cart_id, isbn, quantity) VALUES (5, '978-0-13-468599-1', 1);

-- ── 9. ORDERS ─────────────────────────────────────────────────
-- Alice's completed order (from cart_id=2)
INSERT INTO ORDERS (cust_id, cart_id, total_amount, status)
VALUES (2, 2, 1048.00, 'DELIVERED');

-- ── 10. ORDER ITEMS ───────────────────────────────────────────
-- NOTE: trg_decrement_stock fires here and reduces inventory
INSERT INTO ORDER_ITEMS (order_id, isbn, quantity, price_at_order)
VALUES (1, '978-0-06-231609-7', 1, 499.00);
INSERT INTO ORDER_ITEMS (order_id, isbn, quantity, price_at_order)
VALUES (1, '978-0-06-244558-9', 1, 549.00);

-- ── 11. PAYMENTS ──────────────────────────────────────────────
INSERT INTO PAYMENT (order_id, amount, method, status)
VALUES (1, 1048.00, 'UPI', 'SUCCESS');

COMMIT;

PROMPT Sample data inserted successfully.
PROMPT Customers: 4 | Books: 6 | Warehouses: 3 | Orders: 1 (delivered)
