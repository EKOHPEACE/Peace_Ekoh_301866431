# Portfolio 3: Transactions and Concurrency
**Course:** MIT 8103 – Advanced Database Systems  
**Student Name:** Peace Ekoh  
**Student ID:** 301866431  
**Case Study:** NovaMart Retail Logistics & Storefront (E-Commerce Platform)  
**Database Engine:** MySQL 8.0.30 (InnoDB Storage Engine)  

---

## 1. Overview & Objective
In an enterprise e-commerce platform like NovaMart, thousands of customers browse products, initiate digital payments, and modify shared inventory levels simultaneously. Without rigorous transactional safeguards and concurrency controls, the system would suffer from data anomalies such as overselling inventory, lost updates, inconsistent financial ledger balances, and race conditions.

This portfolio activity provides empirical proof of:
1. Strict adherence to **ACID** properties in payment and checkout workflows.
2. Practical demonstrations of atomic `COMMIT`, error-handling `ROLLBACK`, and nested `SAVEPOINT` recoveries.
3. Comparative analysis of ANSI SQL **Transaction Isolation Levels**.
4. Real-world concurrency simulation: **Race Condition Prevention & Row-Level Locking (`SELECT ... FOR UPDATE`)** executed across simultaneous database sessions.

---

## 2. ACID Properties in NovaMart

| ACID Property | Theoretical Definition | Practical Implementation in NovaMart |
| :--- | :--- | :--- |
| **Atomicity** | All operations in a transaction succeed completely, or the database is left unchanged ("all or nothing"). | During checkout, decrementing stock, creating the order header, inserting order items, and creating the payment must succeed together. If the payment gateway fails, the entire transaction issues a `ROLLBACK`, restoring reserved stock with zero orphaned records. |
| **Consistency** | The database transitions from one valid state to another, satisfying all schema rules, keys, and check constraints. | Check constraints (`stock_quantity >= 0`, `unit_price > 0`) and foreign keys ensure stock cannot become negative and an order cannot reference a non-existent customer or product. |
| **Isolation** | Concurrently executing transactions do not interfere with one another; intermediate uncommitted states remain invisible. | InnoDB uses Multi-Version Concurrency Control (MVCC) and Row-Level Locks (`FOR UPDATE`) to ensure two concurrent buyers competing for the last item execute serially without reading dirty data. |
| **Durability** | Once a transaction is committed, changes persist even in the event of power outages or server crashes. | InnoDB writes transactions to the write-ahead transaction log (WAL / `ib_logfile`) and flushes to disk upon `COMMIT` (`innodb_flush_log_at_trx_commit = 1`). |

---

## 3. Practical Demonstrations: Commit, Rollback & Savepoints

### 3.1 Scenario 1: Successful Atomic Checkout (`COMMIT`)
Amina Bello (Customer 2) purchases 1 unit of the Apple iPhone 15 Pro (1,450,000 NGN).

```sql
START TRANSACTION;

-- Step 1: Decrement stock
UPDATE products 
SET stock_quantity = stock_quantity - 1 
WHERE product_id = 1 AND stock_quantity >= 1;

-- Step 2: Create Order
INSERT INTO orders (customer_id, shipping_address_id, order_status, subtotal_amount, shipping_fee, total_amount)
VALUES (2, 3, 'CONFIRMED', 1450000.00, 5000.00, 1455000.00);
SET @new_order_id = LAST_INSERT_ID();

-- Step 3: Insert Line Item
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
VALUES (@new_order_id, 1, 1, 1450000.00);

-- Step 4: Record Payment
INSERT INTO payments (order_id, payment_method, payment_reference, amount_paid, payment_status)
VALUES (@new_order_id, 'CARD', CONCAT('PAY-ACID-SUCCESS-', @new_order_id), 1455000.00, 'SUCCESSFUL');

COMMIT;
```
* **Verified Output:**
  * Initial stock: **25 units** $\rightarrow$ Final stock: **24 units**.
  * Order `9388` status: `CONFIRMED`, Payment status: `SUCCESSFUL`.

---

### 3.2 Scenario 2: Payment Decline & Full Abort (`ROLLBACK`)
Ngozi Eze (Customer 4) initiates checkout for a MacBook Pro (2,850,000 NGN). The payment gateway declines the transaction due to insufficient funds.

```sql
START TRANSACTION;

-- Stock temporarily decremented
UPDATE products 
SET stock_quantity = stock_quantity - 1 
WHERE product_id = 4 AND stock_quantity >= 1;

INSERT INTO orders (customer_id, shipping_address_id, order_status, subtotal_amount, shipping_fee, total_amount)
VALUES (4, 5, 'PENDING', 2850000.00, 5000.00, 2855000.00);
SET @aborted_order_id = LAST_INSERT_ID();

INSERT INTO order_items (order_id, product_id, quantity, unit_price)
VALUES (@aborted_order_id, 4, 1, 2850000.00);

-- Payment gateway returns failure:
ROLLBACK;
```
* **Verified Output:**
  * Stock before checkout: **10 units** $\rightarrow$ Stock after rollback: **10 units**.
  * Orphaned orders count in `orders` table: **0**.
  * **Proof:** Complete atomicity preserved; no phantom reservations or dangling rows.

---

### 3.3 Scenario 3: Partial Rollback with Nested `SAVEPOINT`
Customer attempts to pay using digital wallet balance. The wallet has insufficient funds; rather than canceling the entire cart, the transaction rolls back to a savepoint and succeeds with credit card payment:

```sql
START TRANSACTION;

INSERT INTO orders (customer_id, shipping_address_id, order_status, subtotal_amount, shipping_fee, total_amount)
VALUES (1, 1, 'PENDING', 185000.00, 4000.00, 189000.00);
SET @sp_order_id = LAST_INSERT_ID();

INSERT INTO order_items (order_id, product_id, quantity, unit_price)
VALUES (@sp_order_id, 9, 1, 185000.00);

-- Establish recovery point
SAVEPOINT before_payment_attempt;

-- Attempt Wallet Payment (Fails)
INSERT INTO payments (order_id, payment_method, payment_reference, amount_paid, payment_status)
VALUES (@sp_order_id, 'WALLET', CONCAT('PAY-FAIL-', @sp_order_id), 189000.00, 'FAILED');

-- Rollback ONLY the failed payment step
ROLLBACK TO SAVEPOINT before_payment_attempt;

-- Fallback payment method (Card)
INSERT INTO payments (order_id, payment_method, payment_reference, amount_paid, payment_status)
VALUES (@sp_order_id, 'CARD', CONCAT('PAY-FALLBACK-CARD-', @sp_order_id), 189000.00, 'SUCCESSFUL');

UPDATE orders SET order_status = 'CONFIRMED' WHERE order_id = @sp_order_id;
COMMIT;
```
* **Verified Output:**
  * Order `9390` successfully confirmed with `payment_method = 'CARD'` and reference `PAY-FALLBACK-CARD-9390`.

---

### 3.4 Scenario 4: Consistent Snapshot Read (`START TRANSACTION WITH CONSISTENT SNAPSHOT`)
To execute financial reconciliation without locking tables or encountering non-repeatable reads, NovaMart leverages InnoDB's **Multi-Version Concurrency Control (MVCC)** under `REPEATABLE READ`:

```sql
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
START TRANSACTION WITH CONSISTENT SNAPSHOT;

-- Baseline financial audit read
SELECT COUNT(order_id) AS snapshot_delivered_orders, SUM(total_amount) AS snapshot_revenue
FROM orders WHERE order_status = 'DELIVERED';

-- Under MVCC, concurrent inserts/updates do NOT alter this read view
COMMIT;
```
* **Verified Guarantee:** Deterministic read consistency across complex multi-query financial audits with zero locking overhead.

---


## 4. Transaction Isolation Levels & Concurrency Phenomena

MySQL InnoDB supports four ANSI SQL isolation levels:

| Isolation Level | Dirty Read | Non-Repeatable Read | Phantom Read | Mechanism in InnoDB |
| :--- | :---: | :---: | :---: | :--- |
| **READ UNCOMMITTED** | Permitted | Permitted | Permitted | Direct read of uncommitted buffer pool dirty pages. |
| **READ COMMITTED** | Prevented | Permitted | Permitted | Consistent read view created on *each statement*. |
| **REPEATABLE READ** (Default) | Prevented | Prevented | Prevented | Consistent read snapshot created on *first query*; Next-Key Locks. |
| **SERIALIZABLE** | Prevented | Prevented | Prevented | All plain `SELECT` queries implicitly converted to `LOCK IN SHARE MODE`. |

### Concurrency Anomalies Explained:
* **Dirty Read:** Transaction A reads modified data written by Transaction B that has *not* yet been committed. If B rolls back, A acted on invalid hallucinated data.
* **Non-Repeatable Read:** Transaction A reads a row twice in the same transaction, but Transaction B commits an update between the two reads, returning different attribute values.
* **Phantom Read:** Transaction A queries a range of rows (e.g. `WHERE stock_quantity < 5`). Transaction B inserts a new row matching the condition and commits. When A queries again, a new "phantom" row appears.
* **Lost Update (Race Condition):** Two concurrent transactions read the same stock value (e.g. 6), both subtract 1, and both write 5 back, overwriting each other and undercounting sales.

---

## 5. Concurrency Simulation: Row-Level Locking (`SELECT ... FOR UPDATE`)

To provide empirical proof of concurrency resolution, we created an automated multi-threaded simulation script (`simulate_concurrency.py`).

### 5.1 Test Setup:
* **Target:** Product 8 (Samsung Refrigerator, initial stock = **6 units**).
* Two concurrent threads (Session 1 and Session 2) connect to MySQL simultaneously.
* **Session 1:** Starts a transaction, issues an exclusive lock (`SELECT ... FOR UPDATE`), simulates a 3-second payment processing delay, decrements stock by 1, and commits.
* **Session 2:** Initiated 0.5 seconds later, attempts to acquire an exclusive lock on the *exact same product row*.

### 5.2 Real Captured Execution Log:
```text
===========================================================================
NOVAMART CONCURRENCY & ROW-LEVEL LOCKING VERIFICATION
Simulating simultaneous checkouts for Product 8 with SELECT ... FOR UPDATE
===========================================================================
[13:42:59.191] [SESSION 1] Connecting to database and requesting lock...
[13:42:59.692] [SESSION 2] Attempting concurrent access on product_id = 8 (Expect Lock Wait)...
[13:43:02.323] [SESSION 1] Finished Execution:
status
SESSION 1: Starting Transaction and acquiring EXCLUSIVE ROW LOCK...
product_id    product_name                              stock_quantity
8             Samsung Side-by-Side Refrigerator 647L    6
simulating_payment_processing
0
status
SESSION 1: Transaction COMMITTED successfully. Lock released.

[13:43:02.327] [SESSION 2] Finished Execution after 2.64s wait (Proves Lock Blocked Session 2):
status
SESSION 2: Attempting to acquire lock on product_id = 8...
product_id    product_name                              stock_quantity
8             Samsung Side-by-Side Refrigerator 647L    5
status
SESSION 2: Acquired lock, updated stock, and COMMITTED!

===========================================================================
FINAL INVENTORY STATE (Verified Serial Consistency):
product_id    product_name                              stock_quantity
8             Samsung Side-by-Side Refrigerator 647L    4
===========================================================================
```

### 5.3 Technical Analysis of the Execution Log:
1. **Pessimistic Row Lock Acquisition:** At `13:42:59.191`, Session 1 acquired an exclusive `X-Lock` on the index record for `product_id = 8`.
2. **Deterministic Lock Blocking:** When Session 2 attempted to read the same record at `13:42:59.692`, InnoDB placed Session 2 into a `LOCK WAIT` queue.
3. **Execution Delay Proof:** Session 2 waited **2.64 seconds** until Session 1 committed at `13:43:02.323`.
4. **Data Integrity Guarantee:** Session 2 accurately read the updated stock of **5** (rather than the stale value of 6), and decremented it to **4**.
5. **Conclusion:** Row-level locking completely eliminated the lost-update race condition, guaranteeing serializable consistency without locking the entire products table.

---

## 6. Deadlock Detection & Resolution
When two transactions create a circular dependency (Transaction A holds Lock 1 and requests Lock 2; Transaction B holds Lock 2 and requests Lock 1):
* MySQL InnoDB's background **Deadlock Detector** automatically identifies the cycle via a wait-for graph.
* The engine selects the transaction with the fewest modified rows as the victim, issues an `ERROR 1213 (40001): Deadlock found when trying to get lock; try restarting transaction`, and rolls it back immediately.
* This allows the other transaction to proceed without system-wide hanging. In application code, deadlocked transactions are handled with exponential backoff retry algorithms.

### 6.1 Runtime Transaction & Lock Wait Inspection (`performance_schema`)
To diagnose concurrency bottlenecks and active lock wait queues in production:
* **Active Transactions:** Query `information_schema.innodb_trx` to identify transaction start timestamps, elapsed seconds, isolation levels, and locked row counts.
* **Granular Lock Modes:** Inspect `performance_schema.data_locks` to differentiate record locks, gap locks, and next-key locks (`LOCK_TYPE`, `LOCK_MODE`, `LOCK_STATUS`).
* **Blocking Chains:** Join `performance_schema.data_lock_waits` with `innodb_trx` to instantly identify which session thread is blocking incoming transactions.

---

## 7. Execution & Reproduction Instructions

To execute and verify the transaction models and concurrency proofs:

1. **ACID Demonstrations (Commit, Rollback, Savepoints):**
   ```bash
   mysql -u root < transactions.sql
   ```
2. **Deterministic Locking & Deadlock Prevention:**
   ```bash
   mysql -u root < deadlock_simulation.sql
   ```
3. **Multi-Threaded Row-Lock Simulation:**
   ```bash
   python simulate_concurrency.py
   ```
4. Check `concurrency_output.txt` and `transaction_results.txt` for real execution logs and verification evidence.
5. Alternatively, execute the master automated test runner from the repository root:
   ```bash
   ..\verify_all_portfolios.bat
   ```


---

## 8. Verified Execution Evidence & Simulation Screenshots

### Screenshot 1: ACID Rollback Verification
*Demonstrates transaction rollback after simulated payment failure, proving stock restored and zero orphaned records.*
![ACID Rollback Verification](./screenshots/01_acid_rollback_verification.png)

### Screenshot 2: Multi-Threaded Row-Lock Simulation Log
*Proves Session 2 is deterministically blocked in a 2.64s lock wait until Session 1 commits, ensuring serializable consistency and preventing lost updates.*
![Row-Lock Concurrency Simulation](./screenshots/02_concurrency_lock_wait.png)


