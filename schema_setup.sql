-- ============================================================
--  schema_setup.sql
--  Shopping Cart Management System
--  Oracle 21c XE | Connect to: XEPDB1
--  Author: Udit Asthana (240905310), CSE-D
-- ============================================================
--  Run as:
--    sqlplus udit/password@localhost:1521/XEPDB1 @schema_setup.sql
-- ============================================================

-- ── 0. CLEAN SLATE (drop in reverse dependency order) ────────
BEGIN
    FOR t IN (
        SELECT table_name FROM user_tables
        WHERE table_name IN (
            'PAYMENT','ORDER_ITEMS','ORDERS',
            'CART_ITEMS','CART',
            'INVENTORY','BOOK',
            'AUTHOR','PUBLISHER','CUSTOMER','WAREHOUSE'
        )
    ) LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS';
    END LOOP;
END;
/

BEGIN
    FOR s IN (
        SELECT sequence_name FROM user_sequences
        WHERE sequence_name IN (
            'SEQ_CUSTOMER','SEQ_CART','SEQ_ORDERS','SEQ_PAYMENT'
        )
    ) LOOP
        EXECUTE IMMEDIATE 'DROP SEQUENCE ' || s.sequence_name;
    END LOOP;
END;
/

-- ── 1. SEQUENCES (Oracle's SERIAL equivalent) ────────────────
CREATE SEQUENCE SEQ_CUSTOMER START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SEQ_CART     START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SEQ_ORDERS   START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SEQ_PAYMENT  START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

-- ── 2. AUTHOR ─────────────────────────────────────────────────
--  From original E-R schema (Exercise 6.21)
CREATE TABLE AUTHOR (
    name     VARCHAR2(100)  NOT NULL,
    address  VARCHAR2(255),
    url      VARCHAR2(255),
    CONSTRAINT pk_author PRIMARY KEY (name)
);

-- ── 3. PUBLISHER ──────────────────────────────────────────────
CREATE TABLE PUBLISHER (
    name     VARCHAR2(100)  NOT NULL,
    address  VARCHAR2(255),
    phone    VARCHAR2(20),
    url      VARCHAR2(255),
    CONSTRAINT pk_publisher PRIMARY KEY (name),
    CONSTRAINT chk_pub_phone CHECK (REGEXP_LIKE(phone, '^\+?[0-9 \-]{7,20}$'))
);

-- ── 4. BOOK ───────────────────────────────────────────────────
CREATE TABLE BOOK (
    isbn           VARCHAR2(20)    NOT NULL,
    title          VARCHAR2(255)   NOT NULL,
    year           NUMBER(4)       NOT NULL,
    price          NUMBER(8,2)     NOT NULL,
    genre          VARCHAR2(50),
    description    VARCHAR2(1000),
    author_name    VARCHAR2(100)   NOT NULL,
    publisher_name VARCHAR2(100)   NOT NULL,
    CONSTRAINT pk_book          PRIMARY KEY (isbn),
    CONSTRAINT fk_book_author   FOREIGN KEY (author_name)    REFERENCES AUTHOR(name),
    CONSTRAINT fk_book_pub      FOREIGN KEY (publisher_name) REFERENCES PUBLISHER(name),
    CONSTRAINT chk_book_price   CHECK (price > 0),
    CONSTRAINT chk_book_year    CHECK (year BETWEEN 1000 AND 2100)
);

-- ── 5. CUSTOMER ───────────────────────────────────────────────
CREATE TABLE CUSTOMER (
    cust_id        NUMBER          DEFAULT SEQ_CUSTOMER.NEXTVAL NOT NULL,
    email          VARCHAR2(150)   NOT NULL,
    name           VARCHAR2(100)   NOT NULL,
    address        VARCHAR2(255),
    phone          VARCHAR2(20),
    password_hash  VARCHAR2(255)   NOT NULL,
    created_at     DATE            DEFAULT SYSDATE,
    CONSTRAINT pk_customer       PRIMARY KEY (cust_id),
    CONSTRAINT uq_customer_email UNIQUE (email),
    CONSTRAINT chk_cust_email    CHECK (email LIKE '%@%.%')
);

-- ── 6. WAREHOUSE ──────────────────────────────────────────────
CREATE TABLE WAREHOUSE (
    code     VARCHAR2(20)   NOT NULL,
    address  VARCHAR2(255),
    phone    VARCHAR2(20),
    CONSTRAINT pk_warehouse PRIMARY KEY (code)
);

-- ── 7. INVENTORY (warehouse stocks book, with quantity) ───────
--  Extends original 'stocks' relationship from E-R schema
CREATE TABLE INVENTORY (
    warehouse_code  VARCHAR2(20)  NOT NULL,
    isbn            VARCHAR2(20)  NOT NULL,
    quantity        NUMBER(6)     DEFAULT 0 NOT NULL,
    CONSTRAINT pk_inventory      PRIMARY KEY (warehouse_code, isbn),
    CONSTRAINT fk_inv_warehouse  FOREIGN KEY (warehouse_code) REFERENCES WAREHOUSE(code),
    CONSTRAINT fk_inv_book       FOREIGN KEY (isbn)           REFERENCES BOOK(isbn),
    CONSTRAINT chk_inv_qty       CHECK (quantity >= 0)
);

-- ── 8. CART ───────────────────────────────────────────────────
--  Extends original 'shopping_basket' entity
CREATE TABLE CART (
    cart_id     NUMBER        DEFAULT SEQ_CART.NEXTVAL NOT NULL,
    cust_id     NUMBER        NOT NULL,
    status      VARCHAR2(20)  DEFAULT 'ACTIVE' NOT NULL,
    created_at  DATE          DEFAULT SYSDATE,
    updated_at  DATE          DEFAULT SYSDATE,
    CONSTRAINT pk_cart        PRIMARY KEY (cart_id),
    CONSTRAINT fk_cart_cust   FOREIGN KEY (cust_id) REFERENCES CUSTOMER(cust_id),
    CONSTRAINT chk_cart_status CHECK (status IN ('ACTIVE','CHECKED_OUT','ABANDONED'))
);

-- ── 9. CART_ITEMS ─────────────────────────────────────────────
--  Extends original 'contains' relationship (book ↔ basket with number)
CREATE TABLE CART_ITEMS (
    cart_id   NUMBER        NOT NULL,
    isbn      VARCHAR2(20)  NOT NULL,
    quantity  NUMBER(4)     DEFAULT 1 NOT NULL,
    CONSTRAINT pk_cart_items     PRIMARY KEY (cart_id, isbn),
    CONSTRAINT fk_ci_cart        FOREIGN KEY (cart_id) REFERENCES CART(cart_id),
    CONSTRAINT fk_ci_book        FOREIGN KEY (isbn)    REFERENCES BOOK(isbn),
    CONSTRAINT chk_ci_qty        CHECK (quantity > 0)
);

-- ── 10. ORDERS ────────────────────────────────────────────────
CREATE TABLE ORDERS (
    order_id      NUMBER          DEFAULT SEQ_ORDERS.NEXTVAL NOT NULL,
    cust_id       NUMBER          NOT NULL,
    cart_id       NUMBER          NOT NULL,
    order_date    DATE            DEFAULT SYSDATE,
    total_amount  NUMBER(10,2)    NOT NULL,
    status        VARCHAR2(20)    DEFAULT 'PLACED' NOT NULL,
    CONSTRAINT pk_orders        PRIMARY KEY (order_id),
    CONSTRAINT fk_ord_cust      FOREIGN KEY (cust_id)  REFERENCES CUSTOMER(cust_id),
    CONSTRAINT fk_ord_cart      FOREIGN KEY (cart_id)  REFERENCES CART(cart_id),
    CONSTRAINT chk_ord_status   CHECK (status IN ('PLACED','SHIPPED','DELIVERED','CANCELLED')),
    CONSTRAINT chk_ord_total    CHECK (total_amount >= 0)
);

-- ── 11. ORDER_ITEMS ───────────────────────────────────────────
CREATE TABLE ORDER_ITEMS (
    order_id        NUMBER        NOT NULL,
    isbn            VARCHAR2(20)  NOT NULL,
    quantity        NUMBER(4)     NOT NULL,
    price_at_order  NUMBER(8,2)   NOT NULL,   -- snapshot of price when ordered
    CONSTRAINT pk_order_items    PRIMARY KEY (order_id, isbn),
    CONSTRAINT fk_oi_order       FOREIGN KEY (order_id) REFERENCES ORDERS(order_id),
    CONSTRAINT fk_oi_book        FOREIGN KEY (isbn)     REFERENCES BOOK(isbn),
    CONSTRAINT chk_oi_qty        CHECK (quantity > 0),
    CONSTRAINT chk_oi_price      CHECK (price_at_order > 0)
);

-- ── 12. PAYMENT ───────────────────────────────────────────────
CREATE TABLE PAYMENT (
    payment_id      NUMBER          DEFAULT SEQ_PAYMENT.NEXTVAL NOT NULL,
    order_id        NUMBER          NOT NULL,
    amount          NUMBER(10,2)    NOT NULL,
    method          VARCHAR2(30)    NOT NULL,
    payment_date    DATE            DEFAULT SYSDATE,
    status          VARCHAR2(20)    DEFAULT 'PENDING' NOT NULL,
    CONSTRAINT pk_payment        PRIMARY KEY (payment_id),
    CONSTRAINT fk_pay_order      FOREIGN KEY (order_id) REFERENCES ORDERS(order_id),
    CONSTRAINT chk_pay_method    CHECK (method IN ('CREDIT_CARD','DEBIT_CARD','UPI','NET_BANKING','WALLET')),
    CONSTRAINT chk_pay_status    CHECK (status IN ('PENDING','SUCCESS','FAILED','REFUNDED')),
    CONSTRAINT chk_pay_amount    CHECK (amount > 0)
);

-- ── 13. TRIGGERS ──────────────────────────────────────────────

-- Trigger 1: Auto-decrement inventory on order item insert
CREATE OR REPLACE TRIGGER trg_decrement_stock
AFTER INSERT ON ORDER_ITEMS
FOR EACH ROW
BEGIN
    UPDATE INVENTORY
    SET    quantity = quantity - :NEW.quantity
    WHERE  isbn = :NEW.isbn;

    -- Raise error if stock went negative (belt-and-suspenders)
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'No inventory record found for ISBN: ' || :NEW.isbn);
    END IF;
END;
/

-- Trigger 2: Mark cart as CHECKED_OUT when order is placed
CREATE OR REPLACE TRIGGER trg_checkout_cart
AFTER INSERT ON ORDERS
FOR EACH ROW
BEGIN
    UPDATE CART
    SET    status     = 'CHECKED_OUT',
           updated_at = SYSDATE
    WHERE  cart_id = :NEW.cart_id;
END;
/

-- Trigger 3: Update cart timestamp when items change
CREATE OR REPLACE TRIGGER trg_cart_updated
AFTER INSERT OR UPDATE OR DELETE ON CART_ITEMS
FOR EACH ROW
BEGIN
    UPDATE CART
    SET    updated_at = SYSDATE
    WHERE  cart_id = COALESCE(:NEW.cart_id, :OLD.cart_id);
END;
/

-- ── Done ──────────────────────────────────────────────────────
PROMPT Schema created successfully.
PROMPT Tables: AUTHOR, PUBLISHER, BOOK, CUSTOMER, WAREHOUSE, INVENTORY,
PROMPT         CART, CART_ITEMS, ORDERS, ORDER_ITEMS, PAYMENT
PROMPT Triggers: trg_decrement_stock, trg_checkout_cart, trg_cart_updated
