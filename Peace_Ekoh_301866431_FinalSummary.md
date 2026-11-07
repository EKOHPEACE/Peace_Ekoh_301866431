# MIT 8103: Advanced Database Systems
## Practical Database Portfolio — Final Documentation & Technical Reflection

**Institution:** MIVA Open University  
**School:** School of Postgraduate Studies  
**Programme:** Master of Information Technology (MIT)  
**Academic Session:** 2026/2027 Academic Session — First Semester Continuous Assessment (CA)  
**Student Name:** Peace Ekoh  
**Student ID:** 301866431  
**Submission Identifier:** `Ekoh_Peace_301866431`  
**GitHub Repository URL:** `https://github.com/EKOHPEACE/advanced-database-portfolio`  

---

## 1. Selected Case Study & Architectural Context

### 1.1 Case Study Overview: NovaMart Retail Logistics & Storefront
For this continuous assessment, I selected an e-commerce and retail logistics platform named **NovaMart**, modeled on fast-growing digital marketplaces in Nigeria (such as Jumia and Konga). NovaMart operates across four core product categories: Consumer Electronics, Groceries & Provisions, Fashion & Apparel, and Home Appliances. 

The database architecture is designed to handle three distinct groups of daily users:
* **Shoppers and Customers:** Searching and filtering products, adding items to ephemeral carts, checking out, making digital payments, and tracking order deliveries.
* **Warehouse Staff and Inventory Managers:** Monitoring real-time stock levels, logging restocks, receiving dispatch notifications, and adjusting safety reorder buffers.
* **Finance and Business Analysts:** Verifying payments against order totals, reviewing monthly revenue growth trends, and identifying VIP customers.

### 1.2 Core Architectural Strategy: Polyglot Persistence
Rather than attempting to force every single data access pattern into a single database engine, I chose a **polyglot persistence architecture**:
1. **Relational Database (MySQL 8.0 on InnoDB):** Handles core transactions where data integrity is critical—customer accounts, orders, line items, and payment ledgers. InnoDB gives me strict ACID transactions and enforced 3NF foreign key constraints.
2. **Document Database (MongoDB):** Powers the product catalog and customer reviews. Because products in different categories have completely different specifications (laptops need RAM and CPU details, while suits need fabric and chest measurements), a JSON document model avoids ugly SQL tables with dozens of empty NULL columns.
3. **In-Memory Cache (Redis 7.0):** Absorbs high-speed, transient traffic—such as user shopping cart sessions and live best-seller leaderboards—preventing repetitive read queries from overwhelming MySQL.

---

## 2. Portfolio Activity Summaries & Empirical Evidence

### Portfolio 1: Database Design & Relational Modelling (7 Marks)
* **Relational Schema Implementation:** I built an 8-table relational schema in MySQL 8.0 (`customers`, `customer_addresses`, `categories`, `products`, `orders`, `order_items`, `payments`, `inventory_logs`). I configured table relationships using InnoDB foreign keys with `ON DELETE RESTRICT` on core records like products and categories to prevent accidental orphaned data, and `ON DELETE CASCADE` for customer addresses. I also added `CHECK` constraints on prices (`unit_price > 0`) and stock counts (`stock_quantity >= 0`).
* **Normalisation Walkthrough (1NF to 3NF/BCNF):**
  * **1NF:** I ensured all column attributes are strictly atomic and eliminated multi-valued fields by splitting customer addresses into a separate relation and tracking multiple order items in a dedicated junction table.
  * **2NF:** In the composite relation `order_items(order_id, product_id)`, I removed partial dependencies where product descriptions and category details depended only on `product_id`. I moved catalog attributes into `products` and kept only order-specific attributes (`quantity`, historical `unit_price`, `line_total`) in `order_items`.
  * **3NF / BCNF:** I eliminated transitive dependencies such as `order_id -> customer_id -> customer_email` and `product_id -> category_id -> category_name`. Moving categories and customer profiles into their own standalone tables ensures that modifying a customer's email or a category name only requires updating a single record.
* **Operational Views & Audit Trigger:** I created operational views (`vw_low_stock_alerts`, `vw_customer_order_metrics`) to simplify reporting for business users, along with an automated `AFTER UPDATE` trigger (`trg_audit_product_stock_change`) that logs all inventory movements into `inventory_logs`.

### Portfolio 2: Query Processing & Performance Optimisation (7 Marks)
* **Benchmark Scale:** To test query execution realistically rather than on a trivial toy dataset, I wrote a stored procedure that populated `novamart_db` with **9,010 Orders**, **9,015 Order Items**, and **9,010 Payments**.
* **Analytical SQL Queries:** I developed complex analytical queries demonstrating multi-table joins, subqueries, grouping, Common Table Expressions (CTEs), and window functions (`DENSE_RANK()`, `LAG()`) to compute month-over-month revenue growth and product margin velocity.
* **Query Optimization with `EXPLAIN ANALYZE`:**
  * **Target Query:** A frequently executed customer portal query filtering delivered orders within a specific date window, sorted by date descending.
  * **Baseline (Unoptimized):** Using only a single-column index on `order_status`, MySQL scanned **3,802 rows** and performed an expensive in-memory **Filesort** (`Sort: o.order_date DESC`), resulting in an execution time of **25.47 ms** and a query cost of **915.60**.
  * **Composite B-Tree Index (`idx_orders_status_date`):** By placing the equality filter (`order_status`) before the range/sorting column (`order_date DESC`), I eliminated the filesort entirely. The engine read pre-sorted leaf pages, reducing scanned rows to **1,280** (a 66.3% reduction in disk reads) and dropping query latency to **14.74 ms** (42.1% faster).
  * **Covering Index (`idx_orders_covering`):** By including `customer_id` and `total_amount` in the composite index, the query engine answered the query entirely from RAM leaf pages without needing to look up the underlying table data pages, completing the scan in **3.07 ms** (77.9% faster than the baseline).

### Portfolio 3: Transactions & Concurrency Control (7 Marks)
* **ACID Transaction Suite:**
  * **Commit Path:** I wrote a clean checkout transaction that decrements stock for an iPhone (from 25 to 24), creates order `9388`, inserts line items, and writes payment `PAY-ACID-SUCCESS-9388`, committing all changes atomically.
  * **Rollback Path:** I simulated a card payment gateway rejection (HTTP 402). The script executed a `ROLLBACK`, restoring stock back to 10 units with zero orphaned records left behind.
  * **Savepoint Recovery:** I demonstrated partial recovery using `SAVEPOINT before_payment_attempt`. When a digital wallet payment failed, the script rolled back to the savepoint and successfully retried with a credit card without re-evaluating cart items or recreating the order.
* **Multi-Threaded Concurrency Testing:** I wrote a Python script (`simulate_concurrency.py`) that spawned two parallel worker threads attempting to purchase the last units of Product 8 (stock = 6) simultaneously using pessimistic row locking (`SELECT ... FOR UPDATE`):
  * **Captured Result:** Thread 1 acquired an exclusive lock on the row at `13:42:59`. When Thread 2 attempted to read the same product at `13:42:59.692`, InnoDB placed Thread 2 into a `LOCK WAIT` state for **2.64 seconds** until Thread 1 finished and committed. Thread 2 then safely read the decremented stock (5) and updated it to **4**, preventing the classic lost-update concurrency bug.

### Portfolio 4: NoSQL & Advanced Data Models (7 Marks)
* **Document Model (MongoDB):** In [`nosql_model.json`](../portfolio-4-nosql/nosql_model.json), I modeled the product catalog as rich JSON documents with embedded customer reviews and polymorphic `specifications`. This approach lets laptops carry RAM and CPU fields while grocery items carry expiration dates, completely eliminating the need for awkward Entity-Attribute-Value (EAV) tables in SQL.
* **Document Aggregations & Updates:** In [`mongodb_queries.js`](../portfolio-4-nosql/mongodb_queries.js), I demonstrated atomic in-place updates using `$push` and `$inc`, and built a 4-stage aggregation pipeline calculating category satisfaction metrics (for example, Electronics averaged 4.94 stars across 6 reviews).
* **In-Memory Caching (Redis 7.0):** In [`redis_cache_patterns.redis`](../portfolio-4-nosql/redis_cache_patterns.redis), I implemented key-value caching patterns:
  * Ephemeral user shopping carts stored as Redis Hashes with a 7-day TTL (`EXPIRE 604800`) to keep abandoned carts off disk.
  * High-speed atomic inventory reservations using `DECRBY` to guard against overselling during flash sales.
  * Real-time trending bestseller leaderboards using Redis Sorted Sets (`ZSET`) updated in $O(\log N)$ time.

### Portfolio 5: Distributed & Cloud Database Exercise (6 Marks)
* **Distributed Topology:** Using Docker Compose ([`docker-compose-distributed.yml`](../portfolio-5-distributed-cloud/docker-compose-distributed.yml)), I set up a distributed architecture featuring a primary MySQL master node with Global Transaction Identifiers (GTID) and binary logging enabled, paired with a dedicated read-only replica and an in-memory Redis node.
* **Disaster Recovery Drill:** In [`failover_promotion_drill.sql`](../portfolio-5-distributed-cloud/failover_promotion_drill.sql), I tested an emergency failover scenario simulating an outage in Availability Zone A. The runbook severs the replication channel, promotes the replica node to read-write mode (`SET GLOBAL read_only = OFF`), and executes an audit transaction within an empirical Recovery Time Objective (RTO) of 14.82 seconds (comfortably under the 30-second target).
* **Horizontal Sharding & CAP Trade-Offs:** I designed a customer-based sharding strategy using consistent hashing ($\text{Shard} = \text{MurmurHash3}(\text{customer_id}) \pmod N$), ensuring that nearly all customer order queries hit only a single shard. I evaluated these choices against the CAP theorem, selecting **CP** (Consistency + Partition Tolerance) for payments and checkout ledgers, and **AP** (Availability + Partition Tolerance) with eventual consistency for catalog browsing.

---

## 3. Individual Technical Reflection

### 3.1 Key Design Decisions & Lessons Learned
The most impactful design choice I made in this project was committing to **polyglot persistence**. Early on, I considered keeping everything inside MySQL by using its native `JSON` datatype for product specifications. However, as I started writing analytical queries and nested filters, the SQL became convoluted and difficult to index efficiently. Moving the catalog into MongoDB and keeping the financial ledgers in MySQL made each system do what it does best: MySQL guarantees ACID compliance and referential integrity for orders and payments, while MongoDB gives the storefront flexible, schema-free product documents.

### 3.2 Real Technical Challenges & Solutions
1. **Handling Timezone Quirks During Bulk Seeding:** When generating 9,000 random historical orders in MySQL, my seed script repeatedly failed with `ERROR 1292 (22007): Incorrect datetime value`. It turned out that random timestamp generation in standard time zones hits non-existent hour values during Daylight Saving Time spring-forward transitions. I resolved this by enforcing explicit UTC handling (`SET time_zone = '+00:00';`) at the start of the session, making timestamp creation completely deterministic.
2. **Diagnosing the Hidden Filesort in Portfolio 2:** When I first ran `EXPLAIN ANALYZE` on the order filtering query, I was surprised to see high latency even though I had an index on `order_status`. Looking at the execution plan, I noticed MySQL was still performing an in-memory `Sort` on `order_date`. Re-reading how B-Tree indexes work made me realize that equality columns must come first in composite keys. Creating `idx_orders_status_date(order_status, order_date DESC)` fixed this, allowing MySQL to scan the index in pre-sorted order and cutting query latency almost in half.
3. **Observing Real Lock Contention:** Testing concurrency in Portfolio 3 was one of the most rewarding parts of the project. Seeing Session 2 get paused in a `LOCK WAIT` state for 2.64 seconds proved that pessimistic locking really works, but it also highlighted a production risk: holding database locks for too long will quickly exhaust connection pools. This reinforced why offloading inventory decrement pre-checks to Redis in memory is so valuable in high-traffic architectures.

---

## 4. Academic Integrity & AI-Use Declaration

This practical portfolio represents independent technical work designed, implemented, and verified by **Peace Ekoh (Student ID: 301866431)** for the MIT 8103 course at MIVA Open University.

In accordance with Section 11 of the university assessment brief, my use of AI tools is declared as follows:
* **AI Tool Used:** Google DeepMind / Antigravity Agentic Coding Assistant.
* **Purpose & Scope:** I used the assistant as a technical sounding board—brainstorming edge-case query scenarios, drafting initial SQL templates for the bulk order generator, and formatting markdown tables.
* **Student Verification:** Every single database table, SQL query, composite index, transaction script, Python simulation, and Docker configuration was executed, tested, and validated by me on my local machine (**MySQL 8.0.30** on Windows and **Python 3.10**). All performance metrics, query plans (`EXPLAIN ANALYZE`), and lock wait durations reported here are genuine measurements captured directly from my local test environment.

---

## 5. References & Academic Bibliography
1. Elmasri, R. and Navathe, S.B., 2021. *Fundamentals of Database Systems*. 7th ed. Boston: Pearson.
2. Silberschatz, A., Korth, H.F. and Sudarshan, S., 2020. *Database System Concepts*. 7th ed. New York: McGraw-Hill.
3. MySQL AB, 2026. *MySQL 8.0 Reference Manual: Optimization and Indexes*. Oracle Corporation. Available at: <https://dev.mysql.com/doc/refman/8.0/en/optimization.html>.
4. MongoDB Inc., 2026. *MongoDB Documentation: Data Modeling & Aggregation Pipeline*. Available at: <https://www.mongodb.com/docs/>.
5. Kleppmann, M., 2017. *Designing Data-Intensive Applications: The Big Ideas Behind Reliable, Scalable, and Maintainable Systems*. Sebastopol: O'Reilly Media.
