-- ============================================================================
-- MIT 8103: Advanced Database Systems - Portfolio 5
-- Student Name: Peace Ekoh | Student ID: 301866431
-- Case Study: NovaMart Retail Logistics & Storefront
-- File: verify_replication_health.sql (Distributed Cluster Health & Replication Verification)
-- Engine: MySQL 8.0 (GTID Semi-Synchronous Replication)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. PRIMARY WRITER NODE VERIFICATION
-- Run on: novamart-mysql-primary
-- ----------------------------------------------------------------------------
SELECT '--- [PRIMARY] 1. Inspecting GTID Mode & Binary Log Status ---' AS check_name;
SHOW MASTER STATUS\G;

SELECT '--- [PRIMARY] 2. Verifying Semi-Sync Master Plugin Status ---' AS check_name;
SHOW STATUS LIKE 'Rpl_semi_sync_master%';

SELECT '--- [PRIMARY] 3. Connected Replicas Count ---' AS check_name;
SELECT * FROM performance_schema.replication_connection_status;


-- ----------------------------------------------------------------------------
-- 2. REPLICA NODE VERIFICATION
-- Run on: novamart-mysql-replica
-- ----------------------------------------------------------------------------
SELECT '--- [REPLICA] 1. Verifying Read-Only Protection ---' AS check_name;
-- Ensures application cannot accidentally execute write queries on read replica
SELECT 
    @@read_only AS is_read_only,
    @@super_read_only AS is_super_read_only;

SELECT '--- [REPLICA] 2. Checking Semi-Sync Replica Plugin Status ---' AS check_name;
SHOW STATUS LIKE 'Rpl_semi_sync_slave%';

SELECT '--- [REPLICA] 3. Comprehensive Replication Channel Health ---' AS check_name;
-- Key indicators to verify:
-- Replica_IO_Running: Yes
-- Replica_SQL_Running: Yes
-- Seconds_Behind_Source: 0 (Zero replication lag)
-- Auto_Position: 1 (GTID auto-positioning active)
SHOW REPLICA STATUS\G;

SELECT '--- [REPLICA] 4. Replication Applier Lag Metrics ---' AS check_name;
SELECT 
    CHANNEL_NAME, 
    SERVICE_STATE AS IO_THREAD_STATE, 
    LAST_ERROR_NUMBER, 
    LAST_ERROR_MESSAGE
FROM performance_schema.replication_connection_status;
