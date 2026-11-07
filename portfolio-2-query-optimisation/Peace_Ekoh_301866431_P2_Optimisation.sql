-- ============================================================================
-- MIT 8103: Advanced Database Systems - Portfolio 2
-- Student Name: Peace Ekoh | Student ID: 301866431
-- Case Study: NovaMart Retail Logistics & Storefront
-- File: benchmark_optimization.sql (Automated Index Tuning & EXPLAIN ANALYZE Benchmark)
-- Engine: MySQL 8.0 (InnoDB)
-- ============================================================================

USE novamart_db;

-- ----------------------------------------------------------------------------
-- STEP 1: Baseline Execution Plan (Before Optimization)
-- Ensure only baseline index exists (idx_order_status)
-- ----------------------------------------------------------------------------
DROP INDEX IF EXISTS idx_orders_covering ON orders;
DROP INDEX IF EXISTS idx_orders_status_date ON orders;

SELECT '====================================================================' AS benchmark_step;
SELECT 'STEP 1: BASELINE EXPLAIN ANALYZE (Single-Column idx_order_status)' AS benchmark_step;
SELECT '====================================================================' AS benchmark_step;

EXPLAIN ANALYZE
SELECT 
    o.order_id,
    o.order_date,
    o.order_status,
    o.total_amount,
    c.first_name,
    c.last_name,
    c.email
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'DELIVERED'
  AND o.order_date BETWEEN '2026-06-01 00:00:00' AND '2026-10-01 23:59:59'
ORDER BY o.order_date DESC;


-- ----------------------------------------------------------------------------
-- STEP 2: Stage 1 Optimization - Composite B-Tree Index
-- Create index on (order_status, order_date DESC)
-- ----------------------------------------------------------------------------
SELECT '====================================================================' AS benchmark_step;
SELECT 'STEP 2: CREATING COMPOSITE B-TREE INDEX (idx_orders_status_date)' AS benchmark_step;
SELECT '====================================================================' AS benchmark_step;

CREATE INDEX idx_orders_status_date ON orders(order_status, order_date DESC);

EXPLAIN ANALYZE
SELECT 
    o.order_id,
    o.order_date,
    o.order_status,
    o.total_amount,
    c.first_name,
    c.last_name,
    c.email
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'DELIVERED'
  AND o.order_date BETWEEN '2026-06-01 00:00:00' AND '2026-10-01 23:59:59'
ORDER BY o.order_date DESC;


-- ----------------------------------------------------------------------------
-- STEP 3: Stage 2 Optimization - Covering Index
-- Include payload columns (customer_id, total_amount) to eliminate table lookups
-- ----------------------------------------------------------------------------
SELECT '====================================================================' AS benchmark_step;
SELECT 'STEP 3: CREATING COVERING INDEX (idx_orders_covering)' AS benchmark_step;
SELECT '====================================================================' AS benchmark_step;

CREATE INDEX idx_orders_covering ON orders(order_status, order_date DESC, customer_id, total_amount);

EXPLAIN ANALYZE
SELECT 
    o.order_id,
    o.order_date,
    o.order_status,
    o.total_amount,
    c.first_name,
    c.last_name,
    c.email
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'DELIVERED'
  AND o.order_date BETWEEN '2026-06-01 00:00:00' AND '2026-10-01 23:59:59'
ORDER BY o.order_date DESC;

-- ----------------------------------------------------------------------------
-- STEP 4: Inspect Created Indexes
-- ----------------------------------------------------------------------------
SELECT '====================================================================' AS benchmark_step;
SELECT 'STEP 4: CURRENT INDEX CONFIGURATION ON ORDERS TABLE' AS benchmark_step;
SELECT '====================================================================' AS benchmark_step;

SHOW INDEXES FROM orders;
