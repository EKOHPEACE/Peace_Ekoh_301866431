-- ============================================================================
-- MIT 8103: Advanced Database Systems - Portfolio 3
-- Student Name: Peace Ekoh | Student ID: 301866431
-- Case Study: NovaMart Retail Logistics & Storefront
-- File: transactions.sql (ACID Properties, Commit, Rollback, and Savepoints)
-- Engine: MySQL 8.0 (InnoDB)
-- ============================================================================

USE novamart_db;

-- ============================================================================
-- DEMONSTRATION 1: SUCCESSFUL ATOMIC CHECKOUT (COMMIT)
-- Business Scenario: Customer 2 (Amina Bello) purchases 1 unit of product 1
--                   (Apple iPhone 15 Pro, Price: 1,450,000 NGN).
-- ============================================================================

-- Step 1: Check initial state
SELECT product_id, product_name, stock_quantity 
FROM products 
WHERE product_id = 1;

START TRANSACTION;

-- Step 2: Verify and reserve stock with Row Lock
UPDATE products 
SET stock_quantity = stock_quantity - 1 
WHERE product_id = 1 AND stock_quantity >= 1;

-- Step 3: Insert Order Record
INSERT INTO orders (customer_id, shipping_address_id, order_status, subtotal_amount, shipping_fee, total_amount)
VALUES (2, 3, 'CONFIRMED', 1450000.00, 5000.00, 1455000.00);

SET @new_order_id = LAST_INSERT_ID();

-- Step 4: Insert Order Line Item
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
VALUES (@new_order_id, 1, 1, 1450000.00);

-- Step 5: Log Inventory Audit
INSERT INTO inventory_logs (product_id, change_quantity, previous_stock, new_stock, reason)
VALUES (1, -1, 25, 24, 'ORDER_PURCHASE');

-- Step 6: Record Successful Payment
INSERT INTO payments (order_id, payment_method, payment_reference, amount_paid, payment_status)
VALUES (@new_order_id, 'CARD', CONCAT('PAY-ACID-SUCCESS-', @new_order_id), 1455000.00, 'SUCCESSFUL');

-- Step 7: Commit all operations atomically
COMMIT;

-- Verify final committed state
SELECT o.order_id, o.order_status, o.total_amount, p.payment_status, p.payment_reference
FROM orders o
JOIN payments p ON o.order_id = p.order_id
WHERE o.order_id = @new_order_id;

SELECT product_id, product_name, stock_quantity 
FROM products 
WHERE product_id = 1;


-- ============================================================================
-- DEMONSTRATION 2: FAILED PAYMENT WITH FULL ROLLBACK (Atomicity Guarantee)
-- Business Scenario: Customer 4 (Ngozi Eze) attempts to purchase product 4 
--                   (MacBook Pro, 2,850,000 NGN), but payment gateway declines.
--                   Database MUST rollback stock and leave zero orphaned orders.
-- ============================================================================

SELECT stock_quantity INTO @initial_stock FROM products WHERE product_id = 4;
SELECT CONCAT('Stock before failed checkout: ', @initial_stock) AS audit_check;

START TRANSACTION;

-- Step 1: Reserve stock
UPDATE products 
SET stock_quantity = stock_quantity - 1 
WHERE product_id = 4 AND stock_quantity >= 1;

-- Step 2: Create pending order
INSERT INTO orders (customer_id, shipping_address_id, order_status, subtotal_amount, shipping_fee, total_amount)
VALUES (4, 5, 'PENDING', 2850000.00, 5000.00, 2855000.00);

SET @aborted_order_id = LAST_INSERT_ID();

INSERT INTO order_items (order_id, product_id, quantity, unit_price)
VALUES (@aborted_order_id, 4, 1, 2850000.00);

-- Simulated Payment Gateway Failure Event
-- Payment gateway returns HTTP 402: "INSUFFICIENT FUNDS / CARD DECLINED"
-- To preserve database integrity, the application initiates an immediate ROLLBACK:

ROLLBACK;

-- Verify rollback: stock must remain identical, and order record must not exist
SELECT CONCAT('Stock after rollback: ', stock_quantity) AS stock_integrity_verification
FROM products 
WHERE product_id = 4;

SELECT COUNT(*) AS orphaned_orders_count 
FROM orders 
WHERE order_id = @aborted_order_id;


-- ============================================================================
-- DEMONSTRATION 3: PARTIAL ROLLBACK USING SAVEPOINTS
-- Business Scenario: Customer attempts to pay with Wallet. If wallet balance
--                   fails, rollback to savepoint and switch to Card payment.
-- ============================================================================

START TRANSACTION;

-- Step 1: Create Order
INSERT INTO orders (customer_id, shipping_address_id, order_status, subtotal_amount, shipping_fee, total_amount)
VALUES (1, 1, 'PENDING', 185000.00, 4000.00, 189000.00);

SET @sp_order_id = LAST_INSERT_ID();

INSERT INTO order_items (order_id, product_id, quantity, unit_price)
VALUES (@sp_order_id, 9, 1, 185000.00);

-- Establish Savepoint before attempting digital wallet deduction
SAVEPOINT before_payment_attempt;

-- Step 2: Attempt Wallet Payment (Simulating failure)
INSERT INTO payments (order_id, payment_method, payment_reference, amount_paid, payment_status)
VALUES (@sp_order_id, 'WALLET', CONCAT('PAY-FAIL-', @sp_order_id), 189000.00, 'FAILED');

-- Wallet payment failed; rollback only payment step to preserve order header
ROLLBACK TO SAVEPOINT before_payment_attempt;

-- Step 3: Fallback payment method (Credit Card)
INSERT INTO payments (order_id, payment_method, payment_reference, amount_paid, payment_status)
VALUES (@sp_order_id, 'CARD', CONCAT('PAY-FALLBACK-CARD-', @sp_order_id), 189000.00, 'SUCCESSFUL');

UPDATE orders SET order_status = 'CONFIRMED' WHERE order_id = @sp_order_id;

-- Commit final transaction with fallback payment
COMMIT;

-- Verify savepoint success
SELECT o.order_id, o.order_status, p.payment_method, p.payment_status, p.payment_reference
FROM orders o
JOIN payments p ON o.order_id = p.order_id
WHERE o.order_id = @sp_order_id;


-- ============================================================================
-- DEMONSTRATION 4: TRANSACTION ISOLATION & MVCC SNAPSHOT CONSISTENCY
-- Business Scenario: Demonstrating REPEATABLE READ snapshot isolation to prevent
--                   non-repeatable reads and phantom reads during financial audits.
-- ============================================================================

-- Step 1: Inspect global and session isolation settings
SELECT 
    @@global.transaction_isolation AS global_isolation_level,
    @@session.transaction_isolation AS session_isolation_level;

-- Step 2: Begin consistent snapshot read transaction
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
START TRANSACTION WITH CONSISTENT SNAPSHOT;

-- Step 3: First audit read of completed transactions
SELECT 
    COUNT(order_id) AS snapshot_delivered_orders,
    COALESCE(SUM(total_amount), 0.00) AS snapshot_total_revenue
FROM orders 
WHERE order_status = 'DELIVERED';

-- Step 4: Under MVCC (Multi-Version Concurrency Control), InnoDB establishes 
-- a read view at the start of this transaction. Even if concurrent transactions 
-- insert new rows or update statuses, subsequent reads in this transaction 
-- will produce identical, deterministic results without acquiring table locks.
SELECT 
    COUNT(order_id) AS consistent_read_check,
    COALESCE(SUM(total_amount), 0.00) AS consistent_revenue_check
FROM orders 
WHERE order_status = 'DELIVERED';

COMMIT;

