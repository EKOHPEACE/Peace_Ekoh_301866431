-- ============================================================================
-- MIT 8103: Advanced Database Systems - Portfolio 2
-- Student Name: Peace Ekoh | Student ID: 301866431
-- Case Study: NovaMart Retail Logistics & Storefront
-- File: generate_bulk_orders.sql
-- Purpose: Generates 5,000 realistic orders and items to demonstrate query
--          optimization, execution plan analysis, and indexing impact.
-- ============================================================================

USE novamart_db;
SET time_zone = '+00:00';

DELIMITER $$

DROP PROCEDURE IF EXISTS PopulateBulkOrders$$
CREATE PROCEDURE PopulateBulkOrders(IN num_orders INT)
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE v_cust_id INT;
    DECLARE v_addr_id INT;
    DECLARE v_prod_id INT;
    DECLARE v_price DECIMAL(12, 2);
    DECLARE v_qty INT;
    DECLARE v_order_id INT;
    DECLARE v_date TIMESTAMP;
    DECLARE v_status VARCHAR(20);
    DECLARE v_statuses VARCHAR(100) DEFAULT 'DELIVERED,DELIVERED,DELIVERED,CONFIRMED,PROCESSING,PENDING,CANCELLED';
    
    -- Disable autocommit and keys temporarily for high-speed bulk ingestion
    SET autocommit = 0;
    
    WHILE i < num_orders DO
        SET i = i + 1;
        
        -- Random customer (1 to 10)
        SET v_cust_id = FLOOR(1 + (RAND() * 10));
        
        -- Select an address for this customer
        SELECT address_id INTO v_addr_id 
        FROM customer_addresses 
        WHERE customer_id = v_cust_id 
        LIMIT 1;
        
        IF v_addr_id IS NULL THEN
            SET v_addr_id = 1;
        END IF;
        
        -- Random date over the past 365 days
        SET v_date = TIMESTAMPADD(SECOND, -FLOOR(RAND() * 31536000), NOW());
        
        -- Status distribution
        SET v_status = ELT(FLOOR(1 + (RAND() * 7)), 'DELIVERED', 'DELIVERED', 'DELIVERED', 'CONFIRMED', 'PROCESSING', 'PENDING', 'CANCELLED');
        
        -- Pick random product (1 to 12)
        SET v_prod_id = FLOOR(1 + (RAND() * 12));
        SELECT unit_price INTO v_price FROM products WHERE product_id = v_prod_id;
        SET v_qty = FLOOR(1 + (RAND() * 3));
        
        -- Insert order
        INSERT INTO orders (customer_id, shipping_address_id, order_date, order_status, subtotal_amount, shipping_fee, total_amount)
        VALUES (v_cust_id, v_addr_id, v_date, v_status, (v_price * v_qty), 5000.00, (v_price * v_qty) + 5000.00);
        
        SET v_order_id = LAST_INSERT_ID();
        
        -- Insert order item
        INSERT INTO order_items (order_id, product_id, quantity, unit_price)
        VALUES (v_order_id, v_prod_id, v_qty, v_price);
        
        -- Insert payment
        INSERT INTO payments (order_id, payment_method, payment_reference, amount_paid, payment_status, transaction_date)
        VALUES (
            v_order_id, 
            ELT(FLOOR(1 + (RAND() * 4)), 'CARD', 'BANK_TRANSFER', 'WALLET', 'PAY_ON_DELIVERY'),
            CONCAT('PAY-BULK-', v_order_id, '-', UNIX_TIMESTAMP(v_date)),
            (v_price * v_qty) + 5000.00,
            IF(v_status = 'CANCELLED', 'FAILED', 'SUCCESSFUL'),
            v_date
        );
        
        -- Commit batch every 500 records
        IF MOD(i, 500) = 0 THEN
            COMMIT;
        END IF;
    END WHILE;
    
    COMMIT;
    SET autocommit = 1;
END$$

DELIMITER ;

-- Execute bulk population (5,000 orders)
CALL PopulateBulkOrders(5000);

-- Verify final count
SELECT 'orders' AS table_name, COUNT(*) AS record_count FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'payments', COUNT(*) FROM payments;
