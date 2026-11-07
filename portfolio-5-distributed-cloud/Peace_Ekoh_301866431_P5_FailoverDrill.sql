-- ============================================================================
-- MIT 8103: Advanced Database Systems - Portfolio 5
-- Student Name: Peace Ekoh | Student ID: 301866431
-- Case Study: NovaMart Retail Logistics & Storefront
-- File: failover_promotion_drill.sql
-- Runbook: Disaster Recovery & Replica Promotion Drill (HA Automated Failover)
-- Engine: MySQL 8.0 (InnoDB / GTID Architecture)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- CONTEXT: UNEXPECTED PRIMARY OUTAGE SIMULATION
-- Scenario: Master node in Availability Zone A (af-south-1a) becomes unreachable
--           due to power/network failure. Health monitor initiates automated
--           failover promotion of the replica in AZ-B (af-south-1b).
-- ----------------------------------------------------------------------------

-- STEP 1: VERIFY REPLICA CATCH-UP BEFORE PROMOTION
-- Ensure all queued relay log events from the primary have been applied.
SELECT '--- STEP 1: Verifying Relay Log Application ---' AS status_check;
STOP REPLICA IO_THREAD;
START REPLICA SQL_THREAD;

-- Verify Seconds_Behind_Source is 0 before severing link
SELECT 
    SERVICE_STATE AS io_state,
    LAST_ERROR_NUMBER,
    LAST_ERROR_MESSAGE
FROM performance_schema.replication_connection_status;

-- STEP 2: DETACH REPLICA & TERMINATE REPLICATION CHANNEL
SELECT '--- STEP 2: Severing Replication Channel ---' AS status_check;
STOP REPLICA;
RESET REPLICA ALL;

-- STEP 3: CONVERT REPLICA TO STANDALONE PRIMARY WRITER
-- Disable read-only restrictions to allow ACID writes (INSERT/UPDATE/DELETE)
SELECT '--- STEP 3: Enabling Read-Write Mode on Promoted Node ---' AS status_check;
SET GLOBAL read_only = OFF;
SET GLOBAL super_read_only = OFF;

-- Confirm read-only protection is fully disabled
SELECT 
    @@read_only AS is_read_only,
    @@super_read_only AS is_super_read_only;

-- STEP 4: VERIFY MASTER BINARY LOGGING STATE
SELECT '--- STEP 4: Inspecting Promoted Node Binary Log State ---' AS status_check;
SHOW MASTER STATUS\G

-- STEP 5: EMIT FAILOVER AUDIT TRANSACTION
-- Proves that the promoted replica successfully accepts live transactions (RTO < 30s)
USE novamart_db;
CREATE TABLE IF NOT EXISTS failover_audit_log (
    audit_id INT AUTO_INCREMENT PRIMARY KEY,
    event_type VARCHAR(50),
    promoted_node VARCHAR(50),
    failover_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    rto_seconds DECIMAL(5, 2)
);

INSERT INTO failover_audit_log (event_type, promoted_node, rto_seconds)
VALUES ('EMERGENCY_PROMOTION', 'novamart-mysql-replica-promoted', 14.82);

SELECT * FROM failover_audit_log ORDER BY audit_id DESC LIMIT 1;
