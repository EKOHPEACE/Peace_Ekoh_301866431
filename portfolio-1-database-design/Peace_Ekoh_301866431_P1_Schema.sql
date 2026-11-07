-- ============================================================================
-- MIT 8103: Advanced Database Systems - Portfolio 1
-- Student Name: Peace Ekoh | Student ID: 301866431
-- Case Study: NovaMart Retail Logistics & Storefront
-- File: schema.sql (Relational Schema Definition - 3NF Compliant)
-- Engine: MySQL 8.0 (InnoDB Engine with Foreign Key & Check Constraints)
-- ============================================================================

DROP DATABASE IF EXISTS novamart_db;
CREATE DATABASE novamart_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE novamart_db;

-- ----------------------------------------------------------------------------
-- 1. CUSTOMERS TABLE
-- Stores unique customer accounts and authentication credentials.
-- ----------------------------------------------------------------------------
CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20) NOT NULL UNIQUE,
    loyalty_points INT DEFAULT 0 CHECK (loyalty_points >= 0),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_customer_email (email)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 2. CUSTOMER_ADDRESSES TABLE
-- Supports 1-to-Many relationship between customer and multiple delivery addresses.
-- Prevents repeating multi-valued address attributes in the customers table (1NF/3NF).
-- ----------------------------------------------------------------------------
CREATE TABLE customer_addresses (
    address_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    address_line VARCHAR(255) NOT NULL,
    city VARCHAR(50) NOT NULL,
    state VARCHAR(50) NOT NULL,
    country VARCHAR(50) DEFAULT 'Nigeria',
    postal_code VARCHAR(15),
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_address_customer 
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id) 
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 3. CATEGORIES TABLE
-- Supports hierarchical product categorization via self-referencing foreign key.
-- ----------------------------------------------------------------------------
CREATE TABLE categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    parent_category_id INT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    CONSTRAINT fk_category_parent 
        FOREIGN KEY (parent_category_id) REFERENCES categories(category_id) 
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 4. PRODUCTS TABLE
-- Stores master catalog items, base pricing, and real-time stock levels.
-- ----------------------------------------------------------------------------
CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    category_id INT NOT NULL,
    sku VARCHAR(50) NOT NULL UNIQUE,
    product_name VARCHAR(150) NOT NULL,
    description TEXT,
    unit_price DECIMAL(12, 2) NOT NULL CHECK (unit_price > 0),
    cost_price DECIMAL(12, 2) NOT NULL CHECK (cost_price > 0),
    stock_quantity INT NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    reorder_level INT NOT NULL DEFAULT 10 CHECK (reorder_level >= 0),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_product_category 
        FOREIGN KEY (category_id) REFERENCES categories(category_id) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_product_sku (sku),
    INDEX idx_product_category (category_id)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 5. ORDERS TABLE
-- Header table capturing customer purchasing transactions.
-- ----------------------------------------------------------------------------
CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    shipping_address_id INT NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    order_status ENUM('PENDING', 'CONFIRMED', 'PROCESSING', 'SHIPPED', 'DELIVERED', 'CANCELLED') DEFAULT 'PENDING',
    subtotal_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00 CHECK (subtotal_amount >= 0),
    shipping_fee DECIMAL(10, 2) NOT NULL DEFAULT 0.00 CHECK (shipping_fee >= 0),
    total_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00 CHECK (total_amount >= 0),
    CONSTRAINT fk_order_customer 
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_order_shipping_address 
        FOREIGN KEY (shipping_address_id) REFERENCES customer_addresses(address_id) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_order_date (order_date),
    INDEX idx_order_customer (customer_id),
    INDEX idx_order_status (order_status)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 6. ORDER_ITEMS TABLE
-- Line-item breakdown linking orders and products (resolving M:N relationship).
-- Stores historical price at purchase time to protect against future price changes.
-- ----------------------------------------------------------------------------
CREATE TABLE order_items (
    order_item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(12, 2) NOT NULL CHECK (unit_price > 0),
    line_total DECIMAL(12, 2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
    CONSTRAINT fk_item_order 
        FOREIGN KEY (order_id) REFERENCES orders(order_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_item_product 
        FOREIGN KEY (product_id) REFERENCES products(product_id) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT uq_order_product UNIQUE (order_id, product_id)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 7. PAYMENTS TABLE
-- Captures payment transactions associated with customer orders.
-- ----------------------------------------------------------------------------
CREATE TABLE payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL UNIQUE,
    payment_method ENUM('CARD', 'BANK_TRANSFER', 'WALLET', 'PAY_ON_DELIVERY') NOT NULL,
    payment_reference VARCHAR(100) NOT NULL UNIQUE,
    amount_paid DECIMAL(12, 2) NOT NULL CHECK (amount_paid >= 0),
    payment_status ENUM('INITIATED', 'SUCCESSFUL', 'FAILED', 'REFUNDED') DEFAULT 'INITIATED',
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_payment_order 
        FOREIGN KEY (order_id) REFERENCES orders(order_id) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_payment_status (payment_status),
    INDEX idx_payment_ref (payment_reference)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 8. INVENTORY_LOGS TABLE
-- Audit trail tracking stock movements (restock, order dispatch, returns).
-- ----------------------------------------------------------------------------
CREATE TABLE inventory_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    change_quantity INT NOT NULL,
    previous_stock INT NOT NULL,
    new_stock INT NOT NULL,
    reason ENUM('ORDER_PURCHASE', 'RESTOCK', 'RETURN_REFUND', 'DAMAGE_WRITE_OFF') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_log_product 
        FOREIGN KEY (product_id) REFERENCES products(product_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_log_product_date (product_id, created_at DESC)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 9. OPERATIONAL VIEWS
-- Simplifies complex queries and abstracts underlying normalized structures.
-- ----------------------------------------------------------------------------

-- View A: Real-time inventory replenishment alerts
CREATE OR REPLACE VIEW v_low_stock_inventory AS
SELECT 
    p.product_id,
    p.sku,
    p.product_name,
    c.category_name,
    p.stock_quantity,
    p.reorder_level,
    (p.reorder_level - p.stock_quantity) AS stock_deficit
FROM products p
JOIN categories c ON p.category_id = c.category_id
WHERE p.stock_quantity <= p.reorder_level 
  AND p.is_active = TRUE;

-- View B: Customer order history and total lifetime spending summary
CREATE OR REPLACE VIEW v_customer_order_summary AS
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    COUNT(o.order_id) AS total_orders,
    COALESCE(SUM(o.total_amount), 0.00) AS total_spend,
    MAX(o.order_date) AS last_order_date
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.email;

-- View C: Enriched inventory alerts with dynamic urgency thresholds
CREATE OR REPLACE VIEW vw_low_stock_alerts AS
SELECT 
    p.product_id,
    p.sku,
    p.product_name,
    c.category_name,
    p.stock_quantity,
    p.reorder_level,
    (p.reorder_level - p.stock_quantity) AS deficit,
    CASE 
        WHEN p.stock_quantity = 0 THEN 'CRITICAL: OUT OF STOCK'
        WHEN p.stock_quantity <= p.reorder_level THEN 'WARNING: REORDER REQUIRED'
        ELSE 'OPTIMAL STOCK'
    END AS stock_urgency
FROM products p
JOIN categories c ON p.category_id = c.category_id
WHERE p.stock_quantity <= p.reorder_level 
  AND p.is_active = TRUE;

-- View D: Customer lifetime spend and VIP loyalty tier classification
CREATE OR REPLACE VIEW vw_customer_order_metrics AS
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.email,
    COUNT(o.order_id) AS total_orders_placed,
    COALESCE(SUM(o.total_amount), 0.00) AS lifetime_spend,
    CASE 
        WHEN COALESCE(SUM(o.total_amount), 0.00) >= 100000000 THEN 'PLATINUM VIP'
        WHEN COALESCE(SUM(o.total_amount), 0.00) >= 50000000 THEN 'GOLD'
        WHEN COALESCE(SUM(o.total_amount), 0.00) >= 10000000 THEN 'SILVER'
        ELSE 'STANDARD'
    END AS customer_tier
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.email;

-- ----------------------------------------------------------------------------
-- 10. DATABASE TRIGGERS
-- Automated audit trailing for stock movements on products table
-- ----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_audit_product_stock_change;

DELIMITER $$
CREATE TRIGGER trg_audit_product_stock_change
AFTER UPDATE ON products
FOR EACH ROW
BEGIN
    IF OLD.stock_quantity <> NEW.stock_quantity THEN
        INSERT INTO inventory_logs (
            product_id,
            change_quantity,
            previous_stock,
            new_stock,
            reason
        ) VALUES (
            NEW.product_id,
            (NEW.stock_quantity - OLD.stock_quantity),
            OLD.stock_quantity,
            NEW.stock_quantity,
            CASE 
                WHEN NEW.stock_quantity < OLD.stock_quantity THEN 'ORDER_PURCHASE'
                ELSE 'RESTOCK'
            END
        );
    END IF;
END$$
DELIMITER ;
