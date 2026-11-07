-- ============================================================================
-- MIT 8103: Advanced Database Systems - Portfolio 1
-- Student Name: Peace Ekoh | Student ID: 301866431
-- Case Study: NovaMart Retail Logistics & Storefront
-- File: verify_constraints.sql (Integrity & Constraint Verification Script)
-- Engine: MySQL 8.0 (InnoDB Engine)
-- ============================================================================

USE novamart_db;

-- ----------------------------------------------------------------------------
-- TEST 1: Unique Email Constraint Verification
-- Expectation: Duplicate email insertion MUST fail (Error 1062).
-- ----------------------------------------------------------------------------
SELECT '--- TEST 1: Duplicate Email Constraint ---' AS test_name;
-- Attempting duplicate insert with existing email 'amina.bello@example.com'
-- INSERT INTO customers (first_name, last_name, email, phone) 
-- VALUES ('Duplicate', 'User', 'amina.bello@example.com', '+2348099999999');
-- Expected: Error Code 1062 (Duplicate entry 'amina.bello@example.com' for key 'customers.email')

-- ----------------------------------------------------------------------------
-- TEST 2: CHECK Constraint on Product Unit Price & Stock
-- Expectation: Inserting negative price or stock MUST fail (Error 3819).
-- ----------------------------------------------------------------------------
SELECT '--- TEST 2: Check Constraint Verification (Negative Stock / Price) ---' AS test_name;
-- INSERT INTO products (category_id, sku, product_name, unit_price, cost_price, stock_quantity)
-- VALUES (1, 'ERR-NEG-PRICE', 'Invalid Product', -500.00, 200.00, 10);
-- Expected: Error Code 3819 (Check constraint 'products_chk_1' is violated)

-- ----------------------------------------------------------------------------
-- TEST 3: Foreign Key RESTRICT on Category Deletion
-- Expectation: Deleting a category that has active child products MUST fail.
-- ----------------------------------------------------------------------------
SELECT '--- TEST 3: FK RESTRICT Verification on Categories ---' AS test_name;
-- DELETE FROM categories WHERE category_id = 1;
-- Expected: Error Code 1451 (Cannot delete or update a parent row: a foreign key constraint fails)

-- ----------------------------------------------------------------------------
-- TEST 4: Operational View Execution - Low Stock Alerts
-- Querying vw_low_stock_alerts to identify products at or below reorder level.
-- ----------------------------------------------------------------------------
SELECT '--- TEST 4: Querying vw_low_stock_alerts ---' AS test_name;
SELECT 
    product_id, 
    sku, 
    product_name, 
    category_name, 
    stock_quantity, 
    reorder_level, 
    deficit, 
    stock_urgency
FROM vw_low_stock_alerts;

-- ----------------------------------------------------------------------------
-- TEST 5: Operational View Execution - Customer Order Metrics
-- Querying vw_customer_order_metrics to verify financial rollups.
-- ----------------------------------------------------------------------------
SELECT '--- TEST 5: Querying vw_customer_order_metrics ---' AS test_name;
SELECT 
    customer_id, 
    customer_name, 
    email, 
    total_orders_placed, 
    lifetime_spend, 
    customer_tier
FROM vw_customer_order_metrics;

-- ----------------------------------------------------------------------------
-- TEST 6: Table Record Count & Schema Health Summary
-- ----------------------------------------------------------------------------
SELECT '--- TEST 6: Schema Health & Table Counts ---' AS test_name;
SELECT 'customers' AS table_name, COUNT(*) AS total_records FROM customers
UNION ALL
SELECT 'customer_addresses', COUNT(*) FROM customer_addresses
UNION ALL
SELECT 'categories', COUNT(*) FROM categories
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'payments', COUNT(*) FROM payments
UNION ALL
SELECT 'inventory_logs', COUNT(*) FROM inventory_logs;

-- ----------------------------------------------------------------------------
-- TEST 7: Automated Inventory Audit Trigger Verification
-- Expectation: Modifying stock_quantity automatically writes a delta row to inventory_logs
-- ----------------------------------------------------------------------------
SELECT '--- TEST 7: Testing trg_audit_product_stock_change Trigger ---' AS test_name;
-- Demonstration workflow:
-- 1. Inspect current stock and latest audit log:
--    SELECT product_id, stock_quantity FROM products WHERE product_id = 1;
-- 2. Simulate restocking action:
--    UPDATE products SET stock_quantity = stock_quantity + 20 WHERE product_id = 1;
-- 3. Confirm audit trail insertion:
--    SELECT log_id, product_id, change_quantity, previous_stock, new_stock, reason, created_at
--    FROM inventory_logs WHERE product_id = 1 ORDER BY log_id DESC LIMIT 1;
