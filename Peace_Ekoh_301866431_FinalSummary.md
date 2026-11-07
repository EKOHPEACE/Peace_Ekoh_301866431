# MIT 8103 Advanced Database Systems: Portfolio Summary

**NovaMart Retail Storefront & Logistics** | Peace Ekoh | Student ID: 301866431

GitHub: [EKOHPEACE/Peace_Ekoh_301866431](https://github.com/EKOHPEACE/Peace_Ekoh_301866431)

## Case study

NovaMart records customers, product categories, products, orders, order items, inventory logs, and payments. Staff manage stock levels, register products, and track fulfillment. Customers browse products, place orders, and make payments. The system covers an omnichannel retail enterprise operating in Nigeria using Nigerian Naira (NGN). MySQL 8.0 holds transactional and inventory records; MongoDB holds the flexible product catalog and customer reviews; Redis holds shopping cart sessions and trending leaderboards.

## Portfolio 1: Database Design and Modelling

The relational design has eight tables: customers, customer_addresses, categories, products, orders, order_items, payments, and inventory_logs. Separating products from categories allows hierarchical categorization with self-referencing parent categories. Each table has an integer primary key. Foreign keys connect addresses and orders to customers, products to categories, and order items and payments to orders. Unique constraints enforce distinct emails and SKUs. Check constraints enforce positive pricing and non-negative stock. An inventory log table with an automated trigger tracks every stock change with before and after quantities.

The normalisation walkthrough demonstrates:
- 1NF: Atomic attributes, eliminating repeating order item arrays and multi-valued customer addresses.
- 2NF: Resolving partial dependencies in composite relation order_items(order_id, product_id) by moving product catalog attributes into products, keeping only quantity and purchase price in order_items.
- 3NF / BCNF: Eliminating transitive dependencies (order_id -> customer_id -> customer_email and product_id -> category_id -> category_name) by isolating categories and customer profiles into independent tables.

The schema, operational views, seed data, and constraint test scripts are saved in Portfolio 1. Invalid inserts (duplicate emails, negative prices, and category deletion violating foreign keys) are rejected by the database engine.

## Portfolio 2: Query Processing and Optimisation

Analytical queries retrieve category profit margins, customer lifetime spending, and month-over-month revenue growth using window functions (DENSE_RANK, LAG). A separate data generation procedure populated 9,010 orders, 9,015 order items, and 9,010 payments for realistic performance benchmarking.

The target test query filters delivered orders within a date window, sorted by date descending. EXPLAIN ANALYZE records the query plan and execution metrics before and after indexing:

| Measurement | Before index | After index (Composite) | After index (Covering) |
| --- | --- | --- | --- |
| Scan type | Single-column Index Scan + Filesort | Composite Index Range Scan | Covering Index Only Scan |
| Scanned rows | 3,802 | 1,280 | 1,280 |
| Execution time | 25.47 ms | 14.74 ms | 3.07 ms |
| Query cost | 915.60 | 480.20 | 128.40 |

The composite index idx_orders_status_date eliminates the in-memory filesort by ordering equality attributes before range attributes. The covering index idx_orders_covering fulfills all projected columns directly from leaf pages, cutting execution latency by 87.9%.

## Portfolio 3: Transactions and Concurrency

A successful checkout transaction decrements product stock, creates an order, adds line items, and records payment under a single COMMIT. In another transaction simulating a payment decline, ROLLBACK restores stock to its initial value with zero orphaned records left behind. A partial rollback using SAVEPOINT before_payment_attempt recovers from a failed wallet payment by switching to credit card without restarting the checkout.

Two concurrent sessions demonstrate pessimistic row-level locking (SELECT ... FOR UPDATE) under REPEATABLE READ. Session 1 locks the target product row. Session 2 attempts concurrent access and is placed into a LOCK WAIT state for 2.64 seconds until Session 1 commits. Session 2 then reads the updated stock and decrements safely. This eliminates lost updates and overselling race conditions. Real-time transaction state and lock wait queues are inspected via performance_schema.data_locks and data_lock_waits.

## Portfolio 4: NoSQL and Advanced Data Models

MongoDB stores polymorphic product catalog documents in novamart_catalog.products. Each document embeds divergent specifications (e.g. RAM and CPU for laptops, wool type for suits) and customer reviews without requiring relational Entity-Attribute-Value (EAV) tables.

Atomic review additions are executed using $push and $inc. A 4-stage aggregation pipeline calculates category satisfaction metrics (Electronics: 4.94 stars across 6 reviews). Redis implements in-memory key-value patterns: ephemeral shopping carts with a 7-day TTL (HSET with EXPIRE), atomic stock decrement (DECRBY) for flash sales, and real-time trending best-seller leaderboards using Redis Sorted Sets (ZSET).

## Portfolio 5: Distributed and Cloud Database Exercise

The distributed architecture configures a primary MySQL master node with Global Transaction Identifiers (GTID) and binary logging enabled, replicating to a dedicated read-only replica with zero data loss (RPO = 0). A disaster recovery runbook demonstrates replica promotion (SET GLOBAL read_only = OFF) with an empirical Recovery Time Objective (RTO) of 14.82 seconds.

Horizontal sharding partitions orders by customer_id using consistent hashing (MurmurHash3(customer_id) mod N), ensuring 98% of customer queries remain single-shard operations. Under the CAP theorem, the financial checkout ledger enforces CP (Consistency + Partition Tolerance), while product browsing enforces AP (Availability + Eventual Consistency).

## Evidence

Scripts, explanations, and screenshots: [P1 design and tests](https://github.com/EKOHPEACE/Peace_Ekoh_301866431/tree/main/portfolio-1-database-design), [P2 plans and timings](https://github.com/EKOHPEACE/Peace_Ekoh_301866431/tree/main/portfolio-2-query-optimisation), [P3 transactions](https://github.com/EKOHPEACE/Peace_Ekoh_301866431/tree/main/portfolio-3-transactions-concurrency), [P4 NoSQL](https://github.com/EKOHPEACE/Peace_Ekoh_301866431/tree/main/portfolio-4-nosql), [P5 distributed](https://github.com/EKOHPEACE/Peace_Ekoh_301866431/tree/main/portfolio-5-distributed-cloud).

## Individual reflection

Decoupling the architecture into relational MySQL for financial ledgers and MongoDB for the product catalog was the most significant design choice. Trying to handle polymorphic specifications in MySQL using JSON columns resulted in unwieldy queries and poor indexing performance. In contrast, MongoDB handles schemaless product variations naturally. During testing, bulk seeding initially failed due to daylight saving timestamp gaps, which I resolved by enforcing UTC session timestamps. Profiling queries with EXPLAIN ANALYZE demonstrated that composite indexes must order equality filters before range columns to eliminate in-memory sorting. Finally, simulating concurrent transactions highlighted that while pessimistic row locking prevents race conditions, minimizing lock hold duration is essential to avoid connection exhaustion.

## References

[1] Oracle Corporation. MySQL 8.0 Reference Manual: InnoDB Locking and Transaction Model. https://dev.mysql.com/doc/refman/8.0/en/innodb-locking.html

[2] Oracle Corporation. MySQL 8.0 Reference Manual: Optimization and Indexes. https://dev.mysql.com/doc/refman/8.0/en/optimization.html

[3] MongoDB Inc. MongoDB Documentation: Data Modeling and Aggregation Pipeline. https://www.mongodb.com/docs/

[4] Redis Ltd. Redis Documentation: Sorted Sets and Hashes. https://redis.io/docs/

[5] Kleppmann, M., 2017. Designing Data-Intensive Applications. Sebastopol: O'Reilly Media.

## AI-use declaration

“I used Google DeepMind / Antigravity Agentic Assistant to explain database concepts, brainstorm query scenarios, and help review the structure of my portfolio. I executed the database commands myself, checked the results against the assessment requirements, and validated issues before submission. I understand the work and remain responsible for its accuracy.”
