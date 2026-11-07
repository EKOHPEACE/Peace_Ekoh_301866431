# MIT 8103: Advanced Database Systems
## Practical Database Portfolio (Continuous Assessment)

**Institution:** MIVA Open University  
**School:** School of Postgraduate Studies  
**Programme:** Master of Information Technology (MIT)  
**Academic Session:** 2026/2027 Academic Session — First Semester  
**Course Code & Title:** MIT 8103 – Advanced Database Systems  
**Student Name:** Peace Ekoh  
**Student ID:** 301866431  
**Assessment Type:** Individual Practical Database Portfolio (40 Marks)  
**Submission Identifier:** `Ekoh_Peace_301866431`  

---

## 1. Selected Case Study: NovaMart Retail Logistics & Storefront

### 1.1 Business Context & Overview
For this practical portfolio, I selected **NovaMart**, a simulated e-commerce retail and logistics platform modeled after modern digital marketplaces operating in Nigeria (such as Jumia and Konga). The platform connects consumers with everyday retail goods across four primary categories: Consumer Electronics, Groceries & Provisions, Fashion & Apparel, and Home Appliances. The database is designed to handle realistic challenges such as high-concurrency order placement, fluctuating inventory levels, and multi-hub fulfillment.

### 1.2 Database Users
* **Shoppers/Customers:** Search for products, view dynamic pricing, place orders, make digital payments, and track order fulfillment.
* **Merchants/Suppliers:** Manage catalog inventory, update stock counts, and view sales metrics.
* **Warehouse & Logistics Operators:** Pick, pack, dispatch orders, and update delivery status timestamps.
* **Customer Support & Finance:** Process refunds, verify payments, audit ledger balances, and resolve disputes.
* **Database Administrator (DBA):** Monitor system performance, optimize query plans, manage replication, and ensure data integrity under high traffic.

### 1.3 Major Data Stored
1. **User & Identity Data:** Customer profiles, hashed credentials, billing/shipping addresses, contact details.
2. **Product Catalog:** Categories, brands, products, SKUs, inventory counts, pricing tiers, and dynamic product attributes.
3. **Transactional Orders:** Order headers, line items (`order_items`), unit prices, discount tokens, order statuses.
4. **Financial Payments:** Payment gateways, transaction reference tokens, payment methods, transaction amounts, status timestamps.
5. **NoSQL / Semi-Structured Data:** Product reviews, clickstream session telemetry, and flexible polymorphic product specifications.

### 1.4 Key Database Operations Supported
* High-speed catalog browsing and faceted filtering across categories and price ranges.
* Atomic order placement and stock deduction with ACID guarantees.
* Safe concurrent checkout handling (preventing overselling when inventory is scarce).
* Analytical reporting: top-selling products, category revenue, customer lifetime value.
* Hybrid storage: Relational RDBMS for financial/inventory integrity, NoSQL Document Store for dynamic catalog attributes.

---

## 2. Portfolio Structure & Navigation

This repository is organized into five progressive technical activities as prescribed by the university guidelines:

| Directory | Portfolio Activity | Focus & Technical Deliverables | Marks |
| :--- | :--- | :--- | :---: |
| [`/portfolio-1-database-design`](./portfolio-1-database-design) | **Portfolio 1: Database Design & Modelling** | ER Diagram, 3NF Relational Schema (DDL), PK/FK constraints, and complete Normalisation proof. | 7 |
| [`/portfolio-2-query-optimisation`](./portfolio-2-query-optimisation) | **Portfolio 2: Query Processing & Optimisation** | Complex analytical queries, `EXPLAIN ANALYZE` execution plans, B-Tree indexing, and Before vs. After performance benchmarking. | 7 |
| [`/portfolio-3-transactions-concurrency`](./portfolio-3-transactions-concurrency) | **Portfolio 3: Transactions & Concurrency** | ACID demonstrations, `COMMIT` / `ROLLBACK` scripts, transaction isolation levels, row-level locking (`FOR UPDATE`), and deadlock prevention. | 7 |
| [`/portfolio-4-nosql`](./portfolio-4-nosql) | **Portfolio 4: NoSQL & Advanced Data Models** | MongoDB / Document store implementation for polymorphic product specifications and customer reviews, query scripts, and suitability analysis. | 7 |
| [`/portfolio-5-distributed-cloud`](./portfolio-5-distributed-cloud) | **Portfolio 5: Distributed & Cloud Databases** | Architecture design for read-replicas, horizontal sharding strategy, CAP theorem trade-offs, and cloud deployment setup on AWS/GCP. | 6 |
| [`/docs`](./docs) | **Final Documentation & Technical Reflection** | 2–3 page summary report for LMS submission, technical reflection, and AI-use declaration. | 6 |
| **TOTAL** | | | **40** |

---

## 3. Quick Start & Test Verification Cheat Sheet

### 3.1 One-Command Master Test Suite
To automatically verify all 5 portfolio modules and artifacts at once:
```powershell
# In PowerShell:
.\verify_all_portfolios.ps1

# Or in Windows CMD / Double-Click:
verify_all_portfolios.bat
```

### 3.2 Individual Activity Test Scripts
Each portfolio activity includes standalone verification scripts that can be directly executed against MySQL, MongoDB, or Docker:

| Portfolio | Primary Deliverable | One-Command Verification Script |
| :--- | :--- | :--- |
| **Portfolio 1** | Relational DDL & Integrity Views | `mysql -u root < portfolio-1-database-design/verify_constraints.sql` |
| **Portfolio 2** | Query Optimization & Indexing | `mysql -u root < portfolio-2-query-optimisation/benchmark_optimization.sql` |
| **Portfolio 3** | ACID Transactions & Concurrency | `mysql -u root < portfolio-3-transactions-concurrency/deadlock_simulation.sql` |
| **Portfolio 4** | Document NoSQL & In-Memory Redis | `python portfolio-4-nosql/run_nosql_demo.py` |
| **Portfolio 5** | Distributed GTID Cluster & Replicas | `docker exec -i novamart-mysql-replica mysql -u root -pRootPassword2026! < portfolio-5-distributed-cloud/verify_replication_health.sql` |

---

## 4. Technology Stack
* **Relational RDBMS Engine:** MySQL 8.0.30 (InnoDB Storage Engine with full ACID support)
* **NoSQL Engine:** MongoDB / JSON Document Model
* **Execution & Profiling Tools:** MySQL CLI, `EXPLAIN ANALYZE`, HeidiSQL / DBeaver
* **Version Control:** Progressive Git Commits on GitHub

---

## 5. Academic Integrity & AI Use Declaration
This practical portfolio represents independent work designed and verified by **Peace Ekoh (ID: 301866431)**. 
Where artificial intelligence tools were used as learning aids:
1. **Tool Used:** Google DeepMind / Antigravity AI Assistant.
2. **Usage Scope:** Brainstorming edge-case queries, schema formatting, and reviewing query execution plan syntax.
3. **Student Verification:** Every SQL schema, index, query, transaction, and NoSQL script was executed and validated locally on MySQL 8.0.30, with execution outputs and logs personally captured and confirmed.
