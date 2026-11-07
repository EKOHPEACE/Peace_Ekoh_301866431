# ============================================================================
# MIT 8103: Advanced Database Systems - Portfolio 3
# Student Name: Peace Ekoh | Student ID: 301866431
# Case Study: NovaMart Retail Logistics & Storefront
# Script: simulate_concurrency.py
# Purpose: Simulates two concurrent customer checkout sessions competing for the
#          same scarce inventory item (Row-Level Locking with SELECT ... FOR UPDATE)
# ============================================================================

import subprocess
import threading
import time
from datetime import datetime

MYSQL_PATH = r"C:\laragon\bin\mysql\mysql-8.0.30-winx64\bin\mysql.exe"

def log_event(session_name, message):
    timestamp = datetime.now().strftime("%H:%M:%S.%f")[:-3]
    print(f"[{timestamp}] [{session_name}] {message}")

def run_session_1():
    # Session 1: Acquires exclusive lock on product_id = 8 (Stock = 6), sleeps 3 seconds to hold lock, then updates and commits
    sql_script = """
    USE novamart_db;
    SELECT 'SESSION 1: Starting Transaction and acquiring EXCLUSIVE ROW LOCK...' AS status;
    START TRANSACTION;
    SELECT product_id, product_name, stock_quantity 
    FROM products 
    WHERE product_id = 8 
    FOR UPDATE;
    SELECT SLEEP(3) AS simulating_payment_processing;
    UPDATE products 
    SET stock_quantity = stock_quantity - 1 
    WHERE product_id = 8;
    COMMIT;
    SELECT 'SESSION 1: Transaction COMMITTED successfully. Lock released.' AS status;
    """
    log_event("SESSION 1", "Connecting to database and requesting lock...")
    proc = subprocess.run([MYSQL_PATH, "-u", "root", "-e", sql_script], capture_output=True, text=True)
    log_event("SESSION 1", "Finished Execution:\n" + proc.stdout)

def run_session_2():
    # Sleep 0.5s to guarantee Session 1 acquires the lock first
    time.sleep(0.5)
    # Session 2: Competes for the same product_id = 8. It must wait until Session 1 releases the lock!
    sql_script = """
    USE novamart_db;
    SELECT 'SESSION 2: Attempting to acquire lock on product_id = 8...' AS status;
    START TRANSACTION;
    SELECT product_id, product_name, stock_quantity 
    FROM products 
    WHERE product_id = 8 
    FOR UPDATE;
    UPDATE products 
    SET stock_quantity = stock_quantity - 1 
    WHERE product_id = 8;
    COMMIT;
    SELECT 'SESSION 2: Acquired lock, updated stock, and COMMITTED!' AS status;
    """
    log_event("SESSION 2", "Attempting concurrent access on product_id = 8 (Expect Lock Wait)...")
    start_time = time.time()
    proc = subprocess.run([MYSQL_PATH, "-u", "root", "-e", sql_script], capture_output=True, text=True)
    duration = round(time.time() - start_time, 2)
    log_event("SESSION 2", f"Finished Execution after {duration}s wait (Proves Lock Blocked Session 2):\n" + proc.stdout)

if __name__ == "__main__":
    print("=" * 75)
    print("NOVAMART CONCURRENCY & ROW-LEVEL LOCKING VERIFICATION")
    print("Simulating simultaneous checkouts for Product 8 with SELECT ... FOR UPDATE")
    print("=" * 75)
    
    t1 = threading.Thread(target=run_session_1)
    t2 = threading.Thread(target=run_session_2)
    
    t1.start()
    t2.start()
    
    t1.join()
    t2.join()
    
    # Query final stock
    verify_script = "USE novamart_db; SELECT product_id, product_name, stock_quantity FROM products WHERE product_id = 8;"
    proc = subprocess.run([MYSQL_PATH, "-u", "root", "-e", verify_script], capture_output=True, text=True)
    print("=" * 75)
    print("FINAL INVENTORY STATE (Verified Serial Consistency):")
    print(proc.stdout)
    print("=" * 75)
