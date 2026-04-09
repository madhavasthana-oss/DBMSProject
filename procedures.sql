-- ============================================================
--  procedures.sql
--  PL/SQL Procedures, Functions & Triggers
--  Shopping Cart Management System
--  Author: Udit Asthana (240905310), CSE-D
-- ============================================================

-- ════════════════════════════════════════════════════════════
--  SECTION A: FUNCTIONS
-- ════════════════════════════════════════════════════════════

-- F1. Get total stock of a book across all warehouses
CREATE OR REPLACE FUNCTION get_total_stock(p_isbn IN VARCHAR2)
RETURN NUMBER IS
    v_total NUMBER := 0;
BEGIN
    SELECT NVL(SUM(quantity), 0)
    INTO   v_total
    FROM   INVENTORY
    WHERE  isbn = p_isbn;
    RETURN v_total;
END get_total_stock;
/

-- F2. Calculate cart total for a given cart_id
CREATE OR REPLACE FUNCTION get_cart_total(p_cart_id IN NUMBER)
RETURN NUMBER IS
    v_total NUMBER := 0;
BEGIN
    SELECT NVL(SUM(b.price * ci.quantity), 0)
    INTO   v_total
    FROM   CART_ITEMS ci
    JOIN   BOOK b ON b.isbn = ci.isbn
    WHERE  ci.cart_id = p_cart_id;
    RETURN v_total;
END get_cart_total;
/

-- ════════════════════════════════════════════════════════════
--  SECTION B: PROCEDURES
-- ════════════════════════════════════════════════════════════

-- P1. Add item to cart (creates cart if none active, updates qty if already present)
CREATE OR REPLACE PROCEDURE add_to_cart(
    p_cust_id  IN NUMBER,
    p_isbn     IN VARCHAR2,
    p_quantity IN NUMBER DEFAULT 1
) AS
    v_cart_id   NUMBER;
    v_stock     NUMBER;
    v_existing  NUMBER;
BEGIN
    -- Check stock availability
    v_stock := get_total_stock(p_isbn);
    IF v_stock < p_quantity THEN
        RAISE_APPLICATION_ERROR(-20010,
            'Insufficient stock. Available: ' || v_stock || ', Requested: ' || p_quantity);
    END IF;

    -- Get or create active cart
    BEGIN
        SELECT cart_id INTO v_cart_id
        FROM   CART
        WHERE  cust_id = p_cust_id AND status = 'ACTIVE'
        AND    ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO CART (cust_id, status)
            VALUES (p_cust_id, 'ACTIVE')
            RETURNING cart_id INTO v_cart_id;
    END;

    -- Insert or update cart item
    BEGIN
        SELECT quantity INTO v_existing
        FROM   CART_ITEMS
        WHERE  cart_id = v_cart_id AND isbn = p_isbn;

        UPDATE CART_ITEMS
        SET    quantity = quantity + p_quantity
        WHERE  cart_id = v_cart_id AND isbn = p_isbn;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO CART_ITEMS (cart_id, isbn, quantity)
            VALUES (v_cart_id, p_isbn, p_quantity);
    END;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Added ' || p_quantity || ' copy/copies of ISBN ' ||
                          p_isbn || ' to cart #' || v_cart_id);
END add_to_cart;
/

-- P2. Remove item from cart
CREATE OR REPLACE PROCEDURE remove_from_cart(
    p_cust_id IN NUMBER,
    p_isbn    IN VARCHAR2
) AS
    v_cart_id NUMBER;
BEGIN
    SELECT cart_id INTO v_cart_id
    FROM   CART
    WHERE  cust_id = p_cust_id AND status = 'ACTIVE'
    AND    ROWNUM = 1;

    DELETE FROM CART_ITEMS
    WHERE  cart_id = v_cart_id AND isbn = p_isbn;

    IF SQL%ROWCOUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Item not found in cart.');
    ELSE
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Item removed from cart #' || v_cart_id);
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20020, 'No active cart found for customer ' || p_cust_id);
END remove_from_cart;
/

-- P3. CHECKOUT — atomically places an order from active cart
--     Verifies stock, creates order + order_items, triggers handle the rest
CREATE OR REPLACE PROCEDURE checkout(
    p_cust_id       IN  NUMBER,
    p_payment_method IN VARCHAR2,
    p_order_id      OUT NUMBER
) AS
    v_cart_id    NUMBER;
    v_total      NUMBER;
    v_stock      NUMBER;
    v_isbn       VARCHAR2(20);
    v_qty        NUMBER;

    CURSOR cur_items IS
        SELECT ci.isbn, ci.quantity
        FROM   CART_ITEMS ci
        WHERE  ci.cart_id = v_cart_id;
BEGIN
    -- 1. Find active cart
    SELECT cart_id INTO v_cart_id
    FROM   CART
    WHERE  cust_id = p_cust_id AND status = 'ACTIVE'
    AND    ROWNUM = 1;

    -- 2. Validate cart is not empty
    SELECT COUNT(*) INTO v_qty FROM CART_ITEMS WHERE cart_id = v_cart_id;
    IF v_qty = 0 THEN
        RAISE_APPLICATION_ERROR(-20030, 'Cart is empty. Add items before checkout.');
    END IF;

    -- 3. Stock validation pass — check ALL items before committing anything
    FOR item IN cur_items LOOP
        v_stock := get_total_stock(item.isbn);
        IF v_stock < item.quantity THEN
            RAISE_APPLICATION_ERROR(-20031,
                'Insufficient stock for ISBN: ' || item.isbn ||
                '. Available: ' || v_stock || ', Requested: ' || item.quantity);
        END IF;
    END LOOP;

    -- 4. Calculate total
    v_total := get_cart_total(v_cart_id);

    -- 5. Insert order
    INSERT INTO ORDERS (cust_id, cart_id, total_amount, status)
    VALUES (p_cust_id, v_cart_id, v_total, 'PLACED')
    RETURNING order_id INTO p_order_id;

    -- 6. Copy cart items to order items (trigger handles stock decrement)
    INSERT INTO ORDER_ITEMS (order_id, isbn, quantity, price_at_order)
    SELECT p_order_id, ci.isbn, ci.quantity, b.price
    FROM   CART_ITEMS ci
    JOIN   BOOK b ON b.isbn = ci.isbn
    WHERE  ci.cart_id = v_cart_id;

    -- 7. Record payment
    INSERT INTO PAYMENT (order_id, amount, method, status)
    VALUES (p_order_id, v_total, p_payment_method, 'SUCCESS');

    -- trg_checkout_cart trigger auto-marks cart as CHECKED_OUT
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Order #' || p_order_id || ' placed. Total: Rs.' || v_total);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20032, 'No active cart found for customer ' || p_cust_id);
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END checkout;
/

-- P4. Update item quantity in cart
CREATE OR REPLACE PROCEDURE update_cart_qty(
    p_cust_id  IN NUMBER,
    p_isbn     IN VARCHAR2,
    p_new_qty  IN NUMBER
) AS
    v_cart_id NUMBER;
BEGIN
    IF p_new_qty <= 0 THEN
        remove_from_cart(p_cust_id, p_isbn);
        RETURN;
    END IF;

    SELECT cart_id INTO v_cart_id
    FROM   CART
    WHERE  cust_id = p_cust_id AND status = 'ACTIVE'
    AND    ROWNUM = 1;

    UPDATE CART_ITEMS
    SET    quantity = p_new_qty
    WHERE  cart_id = v_cart_id AND isbn = p_isbn;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Updated quantity to ' || p_new_qty || ' for ISBN ' || p_isbn);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20040, 'No active cart found for customer ' || p_cust_id);
END update_cart_qty;
/

-- ════════════════════════════════════════════════════════════
--  SECTION C: ADDITIONAL TRIGGERS
-- ════════════════════════════════════════════════════════════
-- (Core triggers are in schema_setup.sql)

-- T4. Prevent negative inventory update (extra safety layer)
CREATE OR REPLACE TRIGGER trg_prevent_negative_stock
BEFORE UPDATE ON INVENTORY
FOR EACH ROW
BEGIN
    IF :NEW.quantity < 0 THEN
        RAISE_APPLICATION_ERROR(-20050,
            'Stock cannot be negative. Warehouse: ' || :NEW.warehouse_code ||
            ', ISBN: ' || :NEW.isbn || ', Attempted: ' || :NEW.quantity);
    END IF;
END;
/

-- T5. Prevent modification of a checked-out cart
CREATE OR REPLACE TRIGGER trg_lock_checked_out_cart
BEFORE INSERT OR UPDATE OR DELETE ON CART_ITEMS
FOR EACH ROW
DECLARE
    v_status VARCHAR2(20);
BEGIN
    SELECT status INTO v_status
    FROM   CART
    WHERE  cart_id = COALESCE(:NEW.cart_id, :OLD.cart_id);

    IF v_status != 'ACTIVE' THEN
        RAISE_APPLICATION_ERROR(-20060,
            'Cannot modify a ' || v_status || ' cart.');
    END IF;
END;
/

-- ════════════════════════════════════════════════════════════
--  SECTION D: USAGE EXAMPLES
-- ════════════════════════════════════════════════════════════

-- Enable output
SET SERVEROUTPUT ON;

-- Add books to Udit's cart
EXEC add_to_cart(1, '978-0-13-212227-1', 1);
EXEC add_to_cart(1, '978-0-06-231609-7', 2);

-- Update quantity
EXEC update_cart_qty(1, '978-0-06-231609-7', 1);

-- Check stock
SELECT get_total_stock('978-0-07-352332-3') AS dsc_stock FROM DUAL;

-- Check cart total
SELECT get_cart_total(1) AS cart_total FROM DUAL;

-- Checkout
DECLARE
    v_order_id NUMBER;
BEGIN
    checkout(1, 'UPI', v_order_id);
    DBMS_OUTPUT.PUT_LINE('New Order ID: ' || v_order_id);
END;
/

PROMPT Procedures and triggers created successfully.
