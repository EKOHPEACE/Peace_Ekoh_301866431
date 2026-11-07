-- ============================================================================
-- MIT 8103: Advanced Database Systems - Portfolio 2
-- Student Name: Peace Ekoh | Student ID: 301866431
-- Case Study: NovaMart Retail Logistics & Storefront
-- File: queries.sql (Analytical Business Queries & Execution Plan Optimization)
-- Engine: MySQL 8.0 (InnoDB)
-- ============================================================================

USE novamart_db;

-- ============================================================================
-- BUSINESS QUERY 1: Category Sales Performance & Profit Margin Analysis
-- Business Purpose: Executive report showing gross revenue, total units sold,
--                   and estimated gross profit margin per category.
-- ============================================================================

SELECT 
    c.category_name,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.quantity) AS total_units_sold,
    FORMAT(SUM(oi.line_total), 2) AS gross_revenue_ngn,
    FORMAT(SUM(oi.quantity * (p.unit_price - p.cost_price)), 2) AS estimated_gross_profit_ngn,
    ROUND((SUM(oi.quantity * (p.unit_price - p.cost_price)) / SUM(oi.line_total)) * 100, 2) AS profit_margin_pct
FROM categories c
JOIN products p ON c.category_id = p.category_id
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'DELIVERED'
GROUP BY c.category_id, c.category_name
ORDER BY SUM(oi.line_total) DESC;


-- ============================================================================
-- BUSINESS QUERY 2: High-Value Customer Profiling (LTV & Recency)
-- Business Purpose: Identify VIP customers with over 300 loyalty points who
--                   placed delivered orders in the last 180 days with card/transfer.
-- ============================================================================

SELECT 
    cust.customer_id,
    CONCAT(cust.first_name, ' ', cust.last_name) AS customer_name,
    cust.email,
    cust.loyalty_points,
    COUNT(DISTINCT o.order_id) AS completed_orders,
    FORMAT(SUM(p.amount_paid), 2) AS total_spent_ngn,
    MAX(o.order_date) AS most_recent_order,
    DATEDIFF(NOW(), MAX(o.order_date)) AS days_since_last_order
FROM customers cust
JOIN orders o ON cust.customer_id = o.customer_id
JOIN payments p ON o.order_id = p.order_id
WHERE cust.loyalty_points >= 300
  AND o.order_status = 'DELIVERED'
  AND p.payment_status = 'SUCCESSFUL'
  AND o.order_date >= DATE_SUB(NOW(), INTERVAL 180 DAY)
GROUP BY cust.customer_id, cust.first_name, cust.last_name, cust.email, cust.loyalty_points
ORDER BY SUM(p.amount_paid) DESC;


-- ============================================================================
-- BUSINESS QUERY 3: Inventory Velocity & Restock Priority Index
-- Business Purpose: Calculates sales velocity (units sold per month) and
--                   flags products falling below dynamic safety stock thresholds.
-- ============================================================================

SELECT 
    p.product_id,
    p.sku,
    p.product_name,
    c.category_name,
    p.stock_quantity AS current_stock,
    p.reorder_level,
    COALESCE(SUM(oi.quantity), 0) AS total_units_dispatched,
    CASE 
        WHEN p.stock_quantity = 0 THEN 'CRITICAL: OUT OF STOCK'
        WHEN p.stock_quantity <= p.reorder_level THEN 'WARNING: REORDER REQUIRED'
        ELSE 'OPTIMAL STOCK'
    END AS inventory_status,
    DENSE_RANK() OVER (ORDER BY COALESCE(SUM(oi.quantity), 0) DESC) AS sales_volume_rank
FROM products p
JOIN categories c ON p.category_id = c.category_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id AND o.order_status = 'DELIVERED'
GROUP BY p.product_id, p.sku, p.product_name, c.category_name, p.stock_quantity, p.reorder_level
ORDER BY sales_volume_rank ASC;


-- ============================================================================
-- BUSINESS QUERY 4: Monthly Revenue Velocity & MoM Growth Analysis
-- Business Purpose: Evaluates monthly e-commerce sales performance using 
--                   Common Table Expressions (CTEs) and LAG() window functions.
-- ============================================================================

WITH monthly_sales AS (
    SELECT 
        DATE_FORMAT(order_date, '%Y-%m') AS sales_month,
        COUNT(order_id) AS total_orders,
        SUM(total_amount) AS monthly_revenue
    FROM orders
    WHERE order_status = 'DELIVERED'
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
)
SELECT 
    sales_month,
    total_orders,
    FORMAT(monthly_revenue, 2) AS monthly_revenue_ngn,
    FORMAT(LAG(monthly_revenue, 1) OVER (ORDER BY sales_month), 2) AS prior_month_revenue_ngn,
    ROUND(
        ((monthly_revenue - LAG(monthly_revenue, 1) OVER (ORDER BY sales_month)) / 
        LAG(monthly_revenue, 1) OVER (ORDER BY sales_month)) * 100, 
        2
    ) AS mom_growth_rate_pct
FROM monthly_sales
ORDER BY sales_month DESC;



-- ============================================================================
-- OPTIMIZATION EXPERIMENT: Target Query for Index Tuning
-- Target: High-frequency operational query filtering orders by date range and status.
-- ============================================================================

-- Query: Delivered orders in Q3/Q4 within date window with customer summary
SELECT 
    o.order_id,
    o.order_date,
    o.order_status,
    o.total_amount,
    c.first_name,
    c.last_name,
    c.email
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'DELIVERED'
  AND o.order_date BETWEEN '2026-06-01 00:00:00' AND '2026-10-01 23:59:59'
ORDER BY o.order_date DESC;
