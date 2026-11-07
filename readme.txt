================================================================================
MIVA OPEN UNIVERSITY - SCHOOL OF POSTGRADUATE STUDIES
MASTER OF INFORMATION TECHNOLOGY (MIT) | 2026/2027 ACADEMIC SESSION
COURSE: MIT 8103 ADVANCED DATABASE SYSTEMS (CONTINUOUS ASSESSMENT PORTFOLIO)
================================================================================
Student Name:           Peace Ekoh
Student ID:             301866431
Submission Identifier:  Peace_Ekoh_301866431
Selected Case Study:    NovaMart Retail Logistics & Storefront (E-Commerce Platform)
GitHub Repository URL:  https://github.com/EKOHPEACE/Peace_Ekoh_301866431
================================================================================

SUBMISSION CONTENTS & DELIVERABLES:
----------------------------------
1. Final Summary Report (PDF / HTML / Markdown):
   - Peace_Ekoh_301866431_FinalSummary.pdf
     Official 3-page continuous assessment report covering all five portfolios,
     empirical performance benchmarks, architectural reflection, academic
     references, and AI-use declaration.
   - Peace_Ekoh_301866431_FinalSummary.html: Formatted A4 printable version.
   - Peace_Ekoh_301866431_FinalSummary.md: Markdown source.

2. GitHub Repository Evidence & Commit Screenshots:
   - github_repo_evidence.png: Full screenshot showing root repository structure,
     branches, directory layout, and recent commits on GitHub.
   - github_commits_evidence.png: Screenshot proving progressive, regular Git
     commits documenting incremental development across all 5 portfolio modules.

3. Automated Portfolio Verification Scripts:
   - verify_all_portfolios.ps1: Automated PowerShell test runner validating all 5/5
     portfolio activities in sequence with status reporting.
   - verify_all_portfolios.bat: Windows batch execution wrapper.

4. Practical Source Code & Verification Artifacts:
   - portfolio-1-database-design/
     * schema.sql: 3NF relational schema DDL with strict foreign key constraints.
     * seed_data.sql: Realistic enterprise seed data (customers, products, orders).
     * verify_constraints.sql: Constraint validation suite & operational views.
     * screenshots/: Verified execution evidence of table creation and views.
     * README.md: ER diagram and Third Normal Form (3NF) mathematical proofs.

   - portfolio-2-query-optimisation/
     * queries.sql: Business analytics targets and complex reporting queries.
     * generate_bulk_orders.sql: Stored procedure generating 9,000+ benchmark orders.
     * benchmark_optimization.sql: Automated EXPLAIN ANALYZE index tuning runner.
     * query_results.txt: Complete query outputs and execution timings.
     * screenshots/: Verified before & after EXPLAIN ANALYZE execution plans.
     * README.md: EXPLAIN ANALYZE profiling showing 42.1% execution speedup.

   - portfolio-3-transactions-concurrency/
     * transactions.sql: ACID commit, rollback, and nested savepoint scripts.
     * deadlock_simulation.sql: Deadlock reproduction & deterministic ordering fix.
     * simulate_concurrency.py: Multi-threaded Python row-level locking simulation.
     * transaction_results.txt: Verified execution output of transaction scenarios.
     * concurrency_output.txt: Real-time terminal log proving 2.64s lock wait prevention.
     * screenshots/: Verified ACID rollback and concurrency lock wait evidence.
     * README.md: Isolation level trade-offs and race condition prevention.

   - portfolio-4-nosql/
     * nosql_model.json: Polymorphic document schemas for catalog & customer reviews.
     * mongodb_queries.js: Aggregation pipeline, atomic $push/$inc operations.
     * redis_cache_patterns.redis: In-memory session cart & stock reservation patterns.
     * run_nosql_demo.py: Python execution harness verifying document queries.
     * nosql_execution_output.txt: Verified aggregation and polymorphic search outputs.
     * screenshots/: Verified MongoDB aggregation and Redis CLI caching evidence.
     * README.md: Relational vs. NoSQL suitability and Redis caching architecture.

   - portfolio-5-distributed-cloud/
     * docker-compose-distributed.yml: Multi-container primary-replica cluster topology.
     * replication_setup.sql: GTID semi-synchronous replication setup scripts.
     * verify_replication_health.sql: Automated replication lag & GTID health check.
     * failover_promotion_drill.sql: Standby promotion and failover recovery drill.
     * screenshots/: Verified Docker container health and replication status.
     * README.md: Sharding design, multi-AZ high availability, and CAP/PACELC analysis.

HOW TO VERIFY CODE LOCALLY:
---------------------------
Run the unified test runner from the root directory:
  PowerShell:  .\verify_all_portfolios.ps1
  Batch:       .\verify_all_portfolios.bat

Individual module verification commands:
- Portfolio 1: mysql -u root < portfolio-1-database-design/verify_constraints.sql
- Portfolio 2: mysql -u root < portfolio-2-query-optimisation/benchmark_optimization.sql
- Portfolio 3: python portfolio-3-transactions-concurrency/simulate_concurrency.py
- Portfolio 4: python portfolio-4-nosql/run_nosql_demo.py
- Portfolio 5: docker-compose -f portfolio-5-distributed-cloud/docker-compose-distributed.yml up -d
================================================================================
