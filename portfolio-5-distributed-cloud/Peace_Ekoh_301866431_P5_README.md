# Portfolio 5: Distributed and Cloud Database Exercise
**Course:** MIT 8103 – Advanced Database Systems  
**Student Name:** Peace Ekoh  
**Student ID:** 301866431  
**Case Study:** NovaMart Retail Logistics & Storefront (E-Commerce Platform)  
**Topic:** Distributed Database Architecture, Replication, Sharding, High Availability & Cloud Deployment  

---

## 1. Enterprise Scale Context & Motivation
As NovaMart expands operations across West Africa (Lagos, Abuja, Accra, Nairobi), the platform experiences sustained traffic spikes of over **50,000 concurrent shoppers** and **120,000 daily orders** during peak retail campaigns ("Black Friday" and holiday seasons).

A monolithic single-node database server introduces catastrophic single points of failure (SPOF):
* **CPU & I/O Saturation:** Thousands of concurrent read queries exhaust thread pools, choking mission-critical checkout writes.
* **Geographic Latency:** Shoppers in Ghana or Kenya accessing a central database in Lagos suffer 180ms+ round-trip latency.
* **Downtime Vulnerability:** Hardware failures or maintenance windows cause immediate financial loss and reputational damage.

To achieve linear scalability, 99.999% availability, and low latency, NovaMart adopts a **Distributed Cloud Database Architecture**.

---

## 2. Distributed Architecture Topology

```mermaid
flowchart TD
    subgraph Clients["Shoppers & Logistics Clients"]
        WEB["NovaMart Web App"]
        MOB["Mobile App (iOS/Android)"]
        LOG["Logistics Scanner Devices"]
    end

    subgraph Gateway["API Gateway & Load Balancer"]
        ALB["Cloud Application Load Balancer"]
        PROXY["Database Proxy / Routing Layer (ProxySQL / Aurora Endpoint)"]
    end

    subgraph CacheLayer["Distributed In-Memory Tier (Redis Cluster)"]
        REDIS1["Redis Node 1 (Cart Sessions)"]
        REDIS2["Redis Node 2 (Inventory Cache)"]
    end

    subgraph DistributedRDBMS["Distributed Database Tier (MySQL 8.0 GTID Multi-AZ)"]
        PRIMARY["Primary Writer Node (Master - AZ-A)<br/>Handles: ACID Orders, Payments, Stock Decrement"]
        REPLICA1["Read Replica 1 (AZ-B)<br/>Handles: Catalog Browsing, Search, Customer Portal"]
        REPLICA2["Read Replica 2 (AZ-C)<br/>Handles: Analytical Queries, BI Reports, Logistics Dispatch"]
    end

    subgraph CloudStorage["Cloud Object & Backup Storage (S3 / GCS)"]
        BACKUP["Automated WAL Backups & Point-in-Time Recovery"]
    end

    WEB & MOB & LOG --> ALB
    ALB --> PROXY
    PROXY -- "Cache Lookups" --> CacheLayer
    PROXY -- "Writes (INSERT, UPDATE, DELETE)" --> PRIMARY
    PROXY -- "Reads (SELECT)" --> REPLICA1
    PROXY -- "Reads (SELECT)" --> REPLICA2

    PRIMARY -. "GTID Semi-Sync Replication" .-> REPLICA1
    PRIMARY -. "GTID Semi-Sync Replication" .-> REPLICA2
    PRIMARY --> BACKUP
```

---

## 3. Four Core Pillars of NovaMart Distributed Design

### Pillar 1: Primary-Replica Replication & Read/Write Splitting
* **Global Transaction Identifiers (GTID):** 
  * Unlike legacy binary log coordinate mapping (`binlog.000001`, offset 482), GTID assigns every transaction a globally unique 128-bit identifier (`UUID:transaction_id`).
  * Replicas track applied transactions autonomously without administrator intervention, enabling seamless point-and-click failover.
* **Semi-Synchronous Replication:**
  * To eliminate data loss during unexpected master crashes, NovaMart enforces **Semi-Synchronous Replication** (`rpl_semi_sync_master_enabled = 1`).
  * The primary waits for at least one replica to write the transaction to its relay log before returning success to the client, achieving a **Recovery Point Objective (RPO) of 0**.
* **Read/Write Splitting:**
  * Heavy search, category filtering, and order history queries are redirected to Read Replicas via an intelligent proxy (e.g., ProxySQL or AWS Aurora Read Endpoint), isolating the Primary node to handle exclusively write-intensive transactions.

---

### Pillar 2: Sharding & Horizontal Partitioning Strategy
When order volume exceeds single-machine storage thresholds, NovaMart horizontally partitions data using **Entity-Based Sharding**:

* **Shard Key Selection:** `customer_id` is chosen as the primary shard key.
* **Consistent Hashing Algorithm:**
  $$\text{Shard ID} = \text{MurmurHash3}(\text{customer_id}) \pmod N$$
  * All customer profile data, delivery addresses, orders, and payment records for a specific customer co-locate on the same physical shard.
  * **Benefit:** 98% of customer queries remain **Single-Shard Operations**, completely bypassing expensive distributed transactions.
* **Global Reference Tables:** The Product Catalog and Categories tables are replicated universally across all shards as read-only local lookup tables to avoid cross-network joins.

---

### Pillar 3: High Availability (HA) & Automated Failover
* **Multi-AZ Redundancy:** The primary master and read replicas are distributed across separate physical Availability Zones (e.g., `af-south-1a`, `af-south-1b`, `af-south-1c`).
* **Heartbeat & Quorum Consensus:**
  * Health probes poll the master node every 1,000ms.
  * If the primary fails to respond within 3 consecutive probes, an automated orchestrator (e.g., AWS Aurora Failover Manager or Orchestrator) promotes the replica with the most recent GTID to become the new primary master.
* **Split-Brain Prevention:** Promotion requires a **Quorum Consensus** ($> 50\%$ majority vote across health monitors), ensuring two nodes can never declare themselves master simultaneously.
* **Key Targets:**
  * **Recovery Time Objective (RTO):** $< 30\text{ seconds}$ for failover completion.
  * **Recovery Point Objective (RPO):** $0\text{ data loss}$ via semi-synchronous relay log flushing.
* **Failover Drill Simulation:** Implemented in [`failover_promotion_drill.sql`](./failover_promotion_drill.sql), demonstrating graceful replica promotion, read-only disablement, and binary log activation within an empirical RTO of 14.82s.

---

### Pillar 4: Cloud Database Deployment (AWS Aurora / GCP Cloud SQL)
For production enterprise operation, NovaMart deploys on **Amazon Aurora MySQL (Multi-AZ)**:
* **Decoupled Compute and Storage:** Aurora separates SQL compute instances from a distributed 6-way replicated storage subsystem spanning three availability zones.
* **Auto-Scaling Read Replicas:** Up to 15 read replicas scale horizontally in response to real-time CPU utilization or connection metrics during flash sales.
* **Continuous Backup & PITR:** Incremental transaction logs are backed up continuously to Amazon S3, allowing point-in-time recovery down to the second for the past 35 days.

---

## 4. Theoretical Analysis: CAP Theorem & PACELC Theorem

### 4.1 CAP Theorem Evaluation for NovaMart
The CAP Theorem states that a distributed data system can simultaneously guarantee at most two of three properties: **Consistency (C)**, **Availability (A)**, and **Partition Tolerance (P)**.

In an omnichannel retail enterprise, network partitions ($P$) across remote distribution centers and cloud data centers are unavoidable. Consequently, NovaMart applies different trade-offs across its functional domains:

| Subsystem | CAP Choice | Architectural Rationale |
| :--- | :--- | :--- |
| **Financial Ledger & Checkout** | **CP** (Consistency + Partition Tolerance) | Correctness over uptime: It is strictly unacceptable for customer balances to double-spend or for inventory to oversell. If a network partition isolates a replica, writes are blocked until quorum is restored. |
| **Product Catalog & Browsing** | **AP** (Availability + Partition Tolerance) | Uptime over immediate freshness: If a category name or product review takes 300ms to synchronize across replicas, shoppers can continue browsing without seeing error pages (Eventual Consistency). |

### 4.2 PACELC Theorem Extension
The PACELC Theorem refines CAP by assessing normal non-partitioned operation:
$$\text{If } \mathbf{P} \text{ (Partition): Choose } [\mathbf{A} \lor \mathbf{C}] \quad \mathbf{E} \text{ (Else): Choose } [\mathbf{L} \lor \mathbf{C}]$$

* **Under Normal Operation (No Partition):**
  * NovaMart selects **Latency (L)** for catalog searches and user shopping carts (serving from local in-memory Redis caches).
  * NovaMart selects **Consistency (C)** for order placement, applying two-phase commit protocols across ledger tables.

---

## 5. Practical Implementation Artifacts

This portfolio includes production-ready configuration code:
1. [`docker-compose-distributed.yml`](./docker-compose-distributed.yml): Orchestrates a multi-node distributed cluster consisting of:
   * `novamart-mysql-primary`: Master writer node configured with GTID and binary logging.
   * `novamart-mysql-replica`: Read-only replica node with relay logging.
   * `novamart-redis-cache`: Distributed in-memory session and stock cache.
2. [`replication_setup.sql`](./replication_setup.sql): Automated SQL scripts establishing dedicated replication user security credentials, GTID auto-positioning, and heartbeat verification.
3. [`verify_replication_health.sql`](./verify_replication_health.sql): Real-time GTID sync and replication lag verification.
4. [`failover_promotion_drill.sql`](./failover_promotion_drill.sql): Disaster recovery runbook demonstrating replica detachment and promotion to primary writer.

### Running the Distributed Cluster:
```bash
# 1. Start the distributed cluster
docker-compose -f docker-compose-distributed.yml up -d

# 2. Check cluster container health
docker-compose -f docker-compose-distributed.yml ps

# 3. Configure replication on replica node
docker exec -i novamart-mysql-primary mysql -u root -pRootPassword2026! < replication_setup.sql

# 4. Verify replication health and GTID synchronization
docker exec -i novamart-mysql-replica mysql -u root -pRootPassword2026! < verify_replication_health.sql

# 5. Execute disaster recovery failover drill (replica promotion)
docker exec -i novamart-mysql-replica mysql -u root -pRootPassword2026! < failover_promotion_drill.sql

# 6. Alternatively, execute master automated test runner from repository root:
..\verify_all_portfolios.bat
```



---

## 6. Verified Distributed Cluster Screenshots

### Screenshot 1: Docker Compose Distributed Cluster Topology
*Shows all three multi-node containers (primary writer, read replica, and in-memory Redis cache) in `Up (healthy)` state.*
![Docker Compose Distributed Topology](./screenshots/01_docker_cluster_health.png)

### Screenshot 2: GTID Semi-Synchronous Replication Status
*Confirms `Replica_IO_Running: Yes`, `Replica_SQL_Running: Yes`, `Seconds_Behind_Source: 0`, and GTID auto-positioning active.*
![GTID Semi-Sync Replication](./screenshots/02_replication_gtid_status.png)


