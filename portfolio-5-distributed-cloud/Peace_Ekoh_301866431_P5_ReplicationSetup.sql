-- ============================================================================
-- MIT 8103: Advanced Database Systems - Portfolio 5
-- Student Name: Peace Ekoh | Student ID: 301866431
-- Case Study: NovaMart Retail Logistics & Storefront
-- File: replication_setup.sql
-- Topology: GTID-Based Semi-Synchronous Primary-Replica Replication
-- ============================================================================

-- ============================================================================
-- STEP 1: EXECUTE ON PRIMARY NODE (mysql-primary)
-- ============================================================================

-- Create dedicated replication account with least-privilege security
CREATE USER IF NOT EXISTS 'repl_user'@'%' IDENTIFIED BY 'ReplSecretPassword2026!';
GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'repl_user'@'%';
FLUSH PRIVILEGES;

-- Verify Binary Logging and GTID Status
SHOW MASTER STATUS;
SHOW VARIABLES LIKE '%gtid%';


-- ============================================================================
-- STEP 2: EXECUTE ON READ REPLICA NODE (mysql-replica)
-- ============================================================================

-- Stop current replica process if active
STOP REPLICA;

-- Configure replica to source from primary using Global Transaction Identifiers (GTID)
-- Auto-positioning eliminates manual log file and position tracking
CHANGE REPLICATION SOURCE TO
    SOURCE_HOST='mysql-primary',
    SOURCE_PORT=3306,
    SOURCE_USER='repl_user',
    SOURCE_PASSWORD='ReplSecretPassword2026!',
    SOURCE_AUTO_POSITION=1,
    SOURCE_SSL=0;

-- Start replication threads (I/O thread and SQL coordinator thread)
START REPLICA;

-- Verify replication health and lag
SHOW REPLICA STATUS\G

-- Expected Health Verification Metrics:
-- 1. Replica_IO_Running: Yes  (Connected to master binlog dump thread)
-- 2. Replica_SQL_Running: Yes (Applying received transactions into relay log)
-- 3. Seconds_Behind_Source: 0 (Zero replication lag)
-- 4. Last_IO_Error / Last_SQL_Error: None


-- ============================================================================
-- STEP 3: HIGH AVAILABILITY & HEALTH HEARTBEAT VERIFICATION
-- ============================================================================

-- Test write on Primary
USE novamart_db;
CREATE TABLE IF NOT EXISTS replication_heartbeat (
    heartbeat_id INT AUTO_INCREMENT PRIMARY KEY,
    source_node VARCHAR(50),
    emitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO replication_heartbeat (source_node) VALUES ('mysql-primary');

-- Read on Replica (Should instantly display the row emitted by primary):
-- SELECT * FROM novamart_db.replication_heartbeat ORDER BY heartbeat_id DESC LIMIT 1;
