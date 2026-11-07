-- ============================================================================
-- MIT 8103: Advanced Database Systems - Portfolio 1
-- Student Name: Peace Ekoh | Student ID: 301866431
-- Case Study: NovaMart Retail Logistics & Storefront
-- File: seed_data.sql (Realistic Seed Data for Functional Verification)
-- ============================================================================

USE novamart_db;

-- ----------------------------------------------------------------------------
-- 1. SEED CATEGORIES
-- ----------------------------------------------------------------------------
INSERT INTO categories (category_id, category_name, parent_category_id, description) VALUES
(1, 'Electronics', NULL, 'Consumer tech, gadgets, and personal computing'),
(2, 'Smartphones & Tablets', 1, 'Mobile devices, cellular phones, and tablets'),
(3, 'Laptops & Computers', 1, 'Notebooks, desktop workstations, and accessories'),
(4, 'Home & Kitchen', NULL, 'Appliances, cookware, and home furniture'),
(5, 'Fashion & Apparel', NULL, 'Men and women clothing, footwear, and accessories'),
(6, 'Groceries & Provisions', NULL, 'Daily consumables, beverages, and pantry items');

-- ----------------------------------------------------------------------------
-- 2. SEED CUSTOMERS
-- ----------------------------------------------------------------------------
INSERT INTO customers (customer_id, first_name, last_name, email, phone, loyalty_points) VALUES
(1, 'Chinedu', 'Okafor', 'chinedu.okafor@example.com', '+2348031234001', 450),
(2, 'Amina', 'Bello', 'amina.bello@example.com', '+2348031234002', 120),
(3, 'Olumide', 'Adeyemi', 'olumide.adeyemi@example.com', '+2348031234003', 890),
(4, 'Ngozi', 'Eze', 'ngozi.eze@example.com', '+2348031234004', 30),
(5, 'Tari', 'Briggs', 'tari.briggs@example.com', '+2348031234005', 1200),
(6, 'Fatima', 'Sanusi', 'fatima.sanusi@example.com', '+2348031234006', 0),
(7, 'Emeka', 'Nwosu', 'emeka.nwosu@example.com', '+2348031234007', 310),
(8, 'Zainab', 'Dahiru', 'zainab.dahiru@example.com', '+2348031234008', 75),
(9, 'Kester', 'Osa', 'kester.osa@example.com', '+2348031234009', 540),
(10, 'Blessing', 'Johnson', 'blessing.johnson@example.com', '+2348031234010', 950);

-- ----------------------------------------------------------------------------
-- 3. SEED CUSTOMER ADDRESSES
-- ----------------------------------------------------------------------------
INSERT INTO customer_addresses (address_id, customer_id, address_line, city, state, country, postal_code, is_default) VALUES
(1, 1, '14 Admiralty Way, Lekki Phase 1', 'Lekki', 'Lagos', 'Nigeria', '105102', TRUE),
(2, 1, 'Plot 8, Victoria Island Central', 'VI', 'Lagos', 'Nigeria', '101241', FALSE),
(3, 2, '22 Crescent Boulevard, Maitama', 'Abuja', 'FCT', 'Nigeria', '900271', TRUE),
(4, 3, '5 Commercial Road, Ring Road', 'Ibadan', 'Oyo', 'Nigeria', '200223', TRUE),
(5, 4, '41 New Haven Avenue', 'Enugu', 'Enugu', 'Nigeria', '400102', TRUE),
(6, 5, '18 Trans-Amadi Industrial Layout', 'Port Harcourt', 'Rivers', 'Nigeria', '500101', TRUE),
(7, 6, '10 Zoo Road, Tarauni', 'Kano', 'Kano', 'Nigeria', '700223', TRUE),
(8, 7, '35 Nnebisi Road', 'Asaba', 'Delta', 'Nigeria', '320242', TRUE),
(9, 8, '7 Ahmadu Bello Way', 'Kaduna', 'Kaduna', 'Nigeria', '800283', TRUE),
(10, 9, '12 Stadium Road, GRA', 'Benin City', 'Edo', 'Nigeria', '300251', TRUE),
(11, 10, '88 Allen Avenue, Ikeja', 'Ikeja', 'Lagos', 'Nigeria', '100282', TRUE);

-- ----------------------------------------------------------------------------
-- 4. SEED PRODUCTS
-- ----------------------------------------------------------------------------
INSERT INTO products (product_id, category_id, sku, product_name, description, unit_price, cost_price, stock_quantity, reorder_level) VALUES
(1, 2, 'SKU-SMP-001', 'Apple iPhone 15 Pro 256GB', 'Titanium design, A17 Pro chip, Super Retina XDR display', 1450000.00, 1250000.00, 25, 5),
(2, 2, 'SKU-SMP-002', 'Samsung Galaxy S24 Ultra 512GB', 'AI-assisted camera, Snapdragon 8 Gen 3, S-Pen included', 1520000.00, 1300000.00, 18, 5),
(3, 2, 'SKU-SMP-003', 'Google Pixel 8 128GB', 'Tensor G3 chip, advanced computational photography', 820000.00, 710000.00, 12, 3),
(4, 3, 'SKU-LAP-001', 'Apple MacBook Pro 14 M3 Max', '36GB Unified Memory, 1TB SSD, Liquid Retina XDR', 2850000.00, 2500000.00, 10, 2),
(5, 3, 'SKU-LAP-002', 'Dell XPS 15 9530 Intel Core i9', '32GB DDR5, 1TB NVMe, NVIDIA RTX 4070 GPU', 2600000.00, 2250000.00, 8, 2),
(6, 3, 'SKU-LAP-003', 'Lenovo ThinkPad X1 Carbon Gen 11', '16GB RAM, 512GB SSD, Ultra-lightweight corporate laptop', 1650000.00, 1420000.00, 15, 3),
(7, 4, 'SKU-HOM-001', 'LG Inverter Smart Air Conditioner 1.5HP', 'Dual Inverter compressor, Wi-Fi smart control, energy saving', 580000.00, 490000.00, 30, 8),
(8, 4, 'SKU-HOM-002', 'Samsung Side-by-Side Refrigerator 647L', 'SpaceMax technology, all-around cooling, digital inverter', 1250000.00, 1080000.00, 6, 2),
(9, 5, 'SKU-FAS-001', 'Men Italian Tailored Wool Suit', 'Premium 100% Italian virgin wool, slim modern fit', 185000.00, 130000.00, 40, 10),
(10, 5, 'SKU-FAS-002', 'Women Designer Genuine Leather Handbag', 'Full-grain calfskin leather with polished gold hardware', 210000.00, 150000.00, 22, 5),
(11, 6, 'SKU-GRO-001', 'Premium Basmati Rice 25kg Bag', 'Long grain royal aromatic aged basmati rice', 45000.00, 38000.00, 100, 20),
(12, 6, 'SKU-GRO-002', 'Extra Virgin Cold Pressed Olive Oil 5L', 'First cold press Mediterranean extra virgin olive oil', 62000.00, 51000.00, 85, 15);

-- ----------------------------------------------------------------------------
-- 5. SEED ORDERS
-- ----------------------------------------------------------------------------
INSERT INTO orders (order_id, customer_id, shipping_address_id, order_date, order_status, subtotal_amount, shipping_fee, total_amount) VALUES
(101, 1, 1, '2026-08-01 10:15:00', 'DELIVERED', 1495000.00, 5000.00, 1500000.00),
(102, 3, 4, '2026-08-05 14:30:00', 'DELIVERED', 2850000.00, 8000.00, 2858000.00),
(103, 5, 6, '2026-08-10 09:20:00', 'DELIVERED', 1830000.00, 12000.00, 1842000.00),
(104, 2, 3, '2026-08-15 16:45:00', 'DELIVERED', 185000.00, 4000.00, 189000.00),
(105, 7, 8, '2026-08-20 11:10:00', 'DELIVERED', 642000.00, 7500.00, 649500.00),
(106, 9, 10, '2026-09-02 13:00:00', 'DELIVERED', 1650000.00, 8000.00, 1658000.00),
(107, 1, 2, '2026-09-12 17:35:00', 'DELIVERED', 420000.00, 5000.00, 425000.00),
(108, 10, 11, '2026-09-22 10:40:00', 'CONFIRMED', 1520000.00, 6000.00, 1526000.00),
(109, 4, 5, '2026-10-01 15:25:00', 'PROCESSING', 820000.00, 6500.00, 826500.00),
(110, 8, 9, '2026-10-10 18:05:00', 'PENDING', 107000.00, 3500.00, 110500.00);

-- ----------------------------------------------------------------------------
-- 6. SEED ORDER ITEMS
-- ----------------------------------------------------------------------------
INSERT INTO order_items (order_item_id, order_id, product_id, quantity, unit_price) VALUES
(1, 101, 1, 1, 1450000.00),
(2, 101, 11, 1, 45000.00),
(3, 102, 4, 1, 2850000.00),
(4, 103, 2, 1, 1520000.00),
(5, 103, 10, 1, 210000.00),
(6, 103, 12, 1, 62000.00),
(7, 104, 9, 1, 185000.00),
(8, 105, 7, 1, 580000.00),
(9, 105, 12, 1, 62000.00),
(10, 106, 6, 1, 1650000.00),
(11, 107, 10, 2, 210000.00),
(12, 108, 2, 1, 1520000.00),
(13, 109, 3, 1, 820000.00),
(14, 110, 11, 1, 45000.00),
(15, 110, 12, 1, 62000.00);

-- ----------------------------------------------------------------------------
-- 7. SEED PAYMENTS
-- ----------------------------------------------------------------------------
INSERT INTO payments (payment_id, order_id, payment_method, payment_reference, amount_paid, payment_status, transaction_date) VALUES
(1, 101, 'CARD', 'PAY-REF-20260801-001', 1500000.00, 'SUCCESSFUL', '2026-08-01 10:17:30'),
(2, 102, 'BANK_TRANSFER', 'PAY-REF-20260805-002', 2858000.00, 'SUCCESSFUL', '2026-08-05 14:35:10'),
(3, 103, 'CARD', 'PAY-REF-20260810-003', 1842000.00, 'SUCCESSFUL', '2026-08-10 09:22:45'),
(4, 104, 'WALLET', 'PAY-REF-20260815-004', 189000.00, 'SUCCESSFUL', '2026-08-15 16:46:12'),
(5, 105, 'CARD', 'PAY-REF-20260820-005', 649500.00, 'SUCCESSFUL', '2026-08-20 11:12:05'),
(6, 106, 'BANK_TRANSFER', 'PAY-REF-20260902-006', 1658000.00, 'SUCCESSFUL', '2026-09-02 13:05:40'),
(7, 107, 'WALLET', 'PAY-REF-20260912-007', 425000.00, 'SUCCESSFUL', '2026-09-12 17:36:20'),
(8, 108, 'CARD', 'PAY-REF-20260922-008', 1526000.00, 'SUCCESSFUL', '2026-09-22 10:42:15'),
(9, 109, 'BANK_TRANSFER', 'PAY-REF-20261001-009', 826500.00, 'SUCCESSFUL', '2026-10-01 15:30:00'),
(10, 110, 'PAY_ON_DELIVERY', 'PAY-REF-20261010-010', 110500.00, 'INITIATED', '2026-10-10 18:05:00');

-- ----------------------------------------------------------------------------
-- 8. SEED INVENTORY LOGS
-- ----------------------------------------------------------------------------
INSERT INTO inventory_logs (log_id, product_id, change_quantity, previous_stock, new_stock, reason) VALUES
(1, 1, 26, 0, 26, 'RESTOCK'),
(2, 1, -1, 26, 25, 'ORDER_PURCHASE'),
(3, 2, 20, 0, 20, 'RESTOCK'),
(4, 2, -1, 20, 19, 'ORDER_PURCHASE'),
(5, 2, -1, 19, 18, 'ORDER_PURCHASE'),
(6, 4, 11, 0, 11, 'RESTOCK'),
(7, 4, -1, 11, 10, 'ORDER_PURCHASE');
