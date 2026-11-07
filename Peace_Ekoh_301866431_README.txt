================================================================================
MIVA OPEN UNIVERSITY - SCHOOL OF POSTGRADUATE STUDIES
MASTER OF INFORMATION TECHNOLOGY (MIT) | 2026/2027 ACADEMIC SESSION
COURSE: MIT 8103 ADVANCED DATABASE SYSTEMS (CONTINUOUS ASSESSMENT)
================================================================================
Student Name: Peace Ekoh
Student ID: 301866431
Submission Identifier: Ekoh_Peace_301866431
Selected Case Study: NovaMart Retail Logistics & Storefront (E-Commerce Platform)
GitHub Repository URL: https://github.com/EKOHPEACE/advanced-database-portfolio
================================================================================

SUBMISSION CONTENTS:
-------------------
1. Ekoh_Peace_301866431_Portfolio_Report.pdf (.html / .md):
   The official 2-3 page Continuous Assessment summary report covering all five 
   portfolio activities, empirical execution evidence, technical reflection, and 
   the mandatory Academic Integrity / AI-Use declaration.

2. Ekoh_Peace_301866431_STUDY_GUIDE_AND_WALKTHROUGH.md:
   Complete technical study guide, plain-English analogies, line-by-line 
   architectural justifications, and viva defense Q&A.

3. Full Practical Source Code, Verification Scripts & Screenshots:
   - portfolio-1-database-design/
     * schema.sql: 3NF relational schema DDL with InnoDB referential integrity.
     * seed_data.sql: Realistic seed data for customers, products, and categories.
     * verify_constraints.sql: Integrity and operational view verification test suite.
     * screenshots/: Verified execution evidence of table creation and views.
     * README.md: Entity-Relationship diagram and step-by-step normalisation proof.
   
   - portfolio-2-query-optimisation/
     * queries.sql: Analytical business queries and indexing target queries.
     * generate_bulk_orders.sql: Stored procedure generating 9,000+ benchmark orders.
     * benchmark_optimization.sql: Automated EXPLAIN ANALYZE index tuning runner.
     * query_results.txt: Complete query outputs and business performance metrics.
     * screenshots/: Verified before & after EXPLAIN ANALYZE profiling screenshots.
     * README.md: EXPLAIN ANALYZE execution plan analysis and 42.1% speedup benchmarks.

   - portfolio-3-transactions-concurrency/
     * transactions.sql: ACID commit, rollback, and nested savepoint scripts.
     * deadlock_simulation.sql: Deadlock anatomy and deterministic resource ordering.
     * simulate_concurrency.py: Multi-threaded Python script testing row-level locking.
     * transaction_results.txt: Verified execution output of transaction scenarios.
     * concurrency_output.txt: Real-time terminal log proving 2.64s lock wait prevention.
     * screenshots/: Verified ACID rollback and multi-threaded lock wait screenshots.
     * README.md: Isolation levels and lost-update race condition analysis.

   - portfolio-4-nosql/
     * nosql_model.json: Polymorphic JSON document models for catalog and reviews.
     * mongodb_queries.js: MongoDB queries, $push/$inc atomic updates, and pipeline.
     * redis_cache_patterns.redis: In-memory session cart and flash-sale stock guard.
     * run_nosql_demo.py: Python execution harness verifying document store queries.
     * nosql_execution_output.txt: Verified aggregation and polymorphic search outputs.
     * screenshots/: Verified MongoDB aggregation and Redis CLI caching screenshots.
     * README.md: Relational vs. NoSQL suitability and Redis caching architecture.

   - portfolio-5-distributed-cloud/
     * docker-compose-distributed.yml: Multi-container primary-replica cluster topology.
     * replication_setup.sql: GTID semi-synchronous replication setup scripts.
     * verify_replication_health.sql: Automated replication lag and GTID health check.
     * screenshots/: Verified Docker Compose container health and replication status.
     * README.md: Sharding design, multi-AZ high availability, and CAP/PACELC analysis.

HOW TO VERIFY CODE LOCALLY:
---------------------------
- Relational Database: MySQL 8.0.30
  Command: mysql -u root < portfolio-1-database-design/verify_constraints.sql
- Query Optimization: MySQL 8.0.30
  Command: mysql -u root < portfolio-2-query-optimisation/benchmark_optimization.sql
- Concurrency Simulation: Python 3.10
  Command: python portfolio-3-transactions-concurrency/simulate_concurrency.py
- NoSQL Demonstration: Python 3.10 / Node.js 18
  Command: python portfolio-4-nosql/run_nosql_demo.py
- Distributed Cluster: Docker & Docker Compose
  Command: docker-compose -f portfolio-5-distributed-cloud/docker-compose-distributed.yml up -d
================================================================================
