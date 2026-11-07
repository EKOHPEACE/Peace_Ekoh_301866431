-- ============================================================================
-- MIT 8103: Advanced Database Systems - Portfolio 3
-- Student Name: Peace Ekoh | Student ID: 301866431
-- Case Study: NovaMart Retail Logistics & Storefront
-- File: deadlock_simulation.sql (Deadlock Analysis & Prevention Script)
-- Engine: MySQL 8.0 (InnoDB)
-- ============================================================================

USE novamart_db;

-- ----------------------------------------------------------------------------
-- PART A: THE DEADLOCK ANATOMY (Circular Dependency)
-- ----------------------------------------------------------------------------
-- In high-concurrency order processing, multi-item checkout can induce deadlocks
-- if locks are acquired in arbitrary or non-deterministic sequences.
--
-- SCENARIO:
-- Cart A contains Product 1 (iPhone) and Product 2 (Samsung S24).
-- Cart B contains Product 2 (Samsung S24) and Product 1 (iPhone).
--
-- TIMELINE OF CONFLICT:
-- Time T1: Session A locks Product 1
--          SELECT * FROM products WHERE product_id = 1 FOR UPDATE;
--
-- Time T2: Session B locks Product 2
--          SELECT * FROM products WHERE product_id = 2 FOR UPDATE;
--
-- Time T3: Session A attempts to lock Product 2 (BLOCKED, waits for Session B)
--          SELECT * FROM products WHERE product_id = 2 FOR UPDATE;
--
-- Time T4: Session B attempts to lock Product 1 (BLOCKED, waits for Session A)
--          SELECT * FROM products WHERE product_id = 1 FOR UPDATE;
--
-- INNODB RESOLUTION:
-- A cycle is detected in the internal lock wait-for graph.
-- InnoDB terminates the cycle by choosing the transaction with the smallest
-- undo log footprint as the victim and returns:
-- "ERROR 1213 (40001): Deadlock found when trying to get lock; try restarting transaction"

-- ----------------------------------------------------------------------------
-- PART B: DETERMINISTIC RESOURCE ORDERING (DEADLOCK ELIMINATION)
-- ----------------------------------------------------------------------------
-- Mathematical Proof: Deadlock requires a circular wait (Coffman condition).
-- If all concurrent transactions request resources according to a strict global
-- linear order (e.g. sorted by primary key product_id ASC), circular wait is
-- impossible, and deadlocks are 100% prevented by design.

-- IMPLEMENTATION IN NOVAMART:
-- When a cart with items [product_id = 4, product_id = 1] is checked out:
-- The application sorts the IDs into [1, 4] BEFORE executing locks.

SELECT '--- DEMONSTRATING DETERMINISTIC ORDERED LOCKING ---' AS status;

START TRANSACTION;

-- Lock items in deterministic sorted order (product_id ASC)
SELECT product_id, product_name, stock_quantity
FROM products
WHERE product_id IN (1, 4)
ORDER BY product_id ASC
FOR UPDATE;

-- Deduct stock safely with zero risk of circular wait
UPDATE products SET stock_quantity = stock_quantity - 1 WHERE product_id = 1;
UPDATE products SET stock_quantity = stock_quantity - 1 WHERE product_id = 4;

COMMIT;

-- Verify updated stock
SELECT product_id, product_name, stock_quantity
FROM products
WHERE product_id IN (1, 4);

-- ----------------------------------------------------------------------------
-- PART C: RUNTIME TRANSACTION LOCK & CONTENTION MONITORING
-- ----------------------------------------------------------------------------
-- MySQL 8.0 provides performance_schema tables to inspect live lock wait queues
-- and transaction states in real-time.

SELECT '--- INSPECTING ACTIVE INNODB TRANSACTIONS & ROW LOCKS ---' AS status;

-- 1. Active transaction state and lock duration
SELECT 
    trx_id,
    trx_state,
    trx_started,
    trx_isolation_level,
    TIMESTAMPDIFF(SECOND, trx_started, NOW()) AS elapsed_seconds,
    trx_rows_locked,
    trx_rows_modified
FROM information_schema.innodb_trx
ORDER BY trx_started ASC;

-- 2. Inspect active row locks and lock modes (X vs S, RECORD vs GAP)
SELECT 
    ENGINE_TRANSACTION_ID AS trx_id,
    OBJECT_SCHEMA,
    OBJECT_NAME,
    LOCK_TYPE,
    LOCK_MODE,
    LOCK_STATUS,
    LOCK_DATA
FROM performance_schema.data_locks
WHERE OBJECT_SCHEMA = 'novamart_db';

-- 3. Query active lock contention and blocked transaction wait relationships
SELECT 
    r.trx_id AS waiting_trx_id,
    r.trx_mysql_thread_id AS waiting_thread,
    b.trx_id AS blocking_trx_id,
    b.trx_mysql_thread_id AS blocking_thread,
    TIMESTAMPDIFF(SECOND, r.trx_wait_started, NOW()) AS wait_seconds
FROM performance_schema.data_lock_waits w
JOIN information_schema.innodb_trx r ON w.REQUESTING_ENGINE_TRANSACTION_ID = r.trx_id
JOIN information_schema.innodb_trx b ON w.BLOCKING_ENGINE_TRANSACTION_ID = b.trx_id;

-- ----------------------------------------------------------------------------
-- PART D: INSPECTING INNODB ENGINE DEADLOCK LOGS
-- ----------------------------------------------------------------------------
-- To inspect the latest deadlock history, lock graphs, and memory buffers:
-- SHOW ENGINE INNODB STATUS\G;
