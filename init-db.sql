-- Create schemas
CREATE SCHEMA IF NOT EXISTS sales;
CREATE SCHEMA IF NOT EXISTS analytics;

COMMENT ON SCHEMA sales IS 'Core sales data including customers, products, orders, and order items';
COMMENT ON SCHEMA analytics IS 'Pre-aggregated analytics tables and views for reporting';

-- Create tables for sales schema

CREATE TABLE sales.customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    city VARCHAR(50),
    state VARCHAR(50),
    zip_code VARCHAR(10),
    country VARCHAR(50) DEFAULT 'USA',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE sales.customers IS 'Stores all customer data including contact details and addresses';
COMMENT ON COLUMN sales.customers.customer_id IS 'Unique identifier for each customer';
COMMENT ON COLUMN sales.customers.first_name IS 'Customer''s first name';
COMMENT ON COLUMN sales.customers.last_name IS 'Customer''s last name';
COMMENT ON COLUMN sales.customers.email IS 'Customer''s email address (must be unique)';
COMMENT ON COLUMN sales.customers.phone IS 'Customer''s phone number';
COMMENT ON COLUMN sales.customers.address IS 'Street address';
COMMENT ON COLUMN sales.customers.city IS 'City name';
COMMENT ON COLUMN sales.customers.state IS 'State or province';
COMMENT ON COLUMN sales.customers.zip_code IS 'Postal/ZIP code';
COMMENT ON COLUMN sales.customers.country IS 'Country (defaults to USA)';
COMMENT ON COLUMN sales.customers.created_at IS 'When customer record was created';
COMMENT ON COLUMN sales.customers.updated_at IS 'When customer record was last updated';

CREATE TABLE sales.products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    subcategory VARCHAR(50),
    brand VARCHAR(50),
    price DECIMAL(10,2) NOT NULL,
    cost DECIMAL(10,2) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE sales.products IS 'Product catalog containing all products available for sale';
COMMENT ON COLUMN sales.products.product_id IS 'Unique identifier for each product';
COMMENT ON COLUMN sales.products.product_name IS 'Name of the product';
COMMENT ON COLUMN sales.products.category IS 'Main product category (e.g., Electronics, Furniture)';
COMMENT ON COLUMN sales.products.subcategory IS 'Product subcategory (e.g., Computers, Audio)';
COMMENT ON COLUMN sales.products.brand IS 'Brand or manufacturer name';
COMMENT ON COLUMN sales.products.price IS 'Selling price to customers';
COMMENT ON COLUMN sales.products.cost IS 'Cost of goods sold (for profit calculations)';
COMMENT ON COLUMN sales.products.description IS 'Detailed product description';
COMMENT ON COLUMN sales.products.created_at IS 'When product was added to catalog';

CREATE TABLE sales.orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES sales.customers(customer_id),
    order_date DATE NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    shipping_address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE sales.orders IS 'Tracks all customer orders and their current status';
COMMENT ON COLUMN sales.orders.order_id IS 'Unique identifier for each order';
COMMENT ON COLUMN sales.orders.customer_id IS 'Foreign key referencing the customer who placed the order';
COMMENT ON COLUMN sales.orders.order_date IS 'Date when the order was placed';
COMMENT ON COLUMN sales.orders.total_amount IS 'Total order value including all items';
COMMENT ON COLUMN sales.orders.status IS 'Order status: pending, processing, shipped, completed, cancelled';
COMMENT ON COLUMN sales.orders.shipping_address IS 'Address where order should be shipped';
COMMENT ON COLUMN sales.orders.created_at IS 'Timestamp when order record was created';

CREATE TABLE sales.order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES sales.orders(order_id),
    product_id INTEGER REFERENCES sales.products(product_id),
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL
);

COMMENT ON TABLE sales.order_items IS 'Individual line items within each order';
COMMENT ON COLUMN sales.order_items.order_item_id IS 'Unique identifier for each order line item';
COMMENT ON COLUMN sales.order_items.order_id IS 'Foreign key referencing the parent order';
COMMENT ON COLUMN sales.order_items.product_id IS 'Foreign key referencing the ordered product';
COMMENT ON COLUMN sales.order_items.quantity IS 'Number of units ordered';
COMMENT ON COLUMN sales.order_items.unit_price IS 'Price per unit at time of order';
COMMENT ON COLUMN sales.order_items.total_price IS 'Total price for this line item (quantity * unit_price)';

-- Create analytics tables

CREATE TABLE analytics.daily_sales AS
SELECT 
    order_date,
    COUNT(*) as order_count,
    SUM(total_amount) as total_revenue,
    AVG(total_amount) as avg_order_value
FROM sales.orders
GROUP BY order_date;

COMMENT ON TABLE analytics.daily_sales IS 'Pre-computed daily sales metrics for faster reporting';
COMMENT ON COLUMN analytics.daily_sales.order_date IS 'Date of the orders';
COMMENT ON COLUMN analytics.daily_sales.order_count IS 'Number of orders placed on this date';
COMMENT ON COLUMN analytics.daily_sales.total_revenue IS 'Total revenue generated on this date';
COMMENT ON COLUMN analytics.daily_sales.avg_order_value IS 'Average order value for this date';

-- Insert sample customers
INSERT INTO sales.customers (first_name, last_name, email, phone, address, city, state, zip_code) VALUES
('John', 'Doe', 'john.doe@email.com', '555-0101', '123 Main St', 'New York', 'NY', '10001'),
('Jane', 'Smith', 'jane.smith@email.com', '555-0102', '456 Oak Ave', 'Los Angeles', 'CA', '90210'),
('Bob', 'Johnson', 'bob.johnson@email.com', '555-0103', '789 Pine St', 'Chicago', 'IL', '60601'),
('Alice', 'Brown', 'alice.brown@email.com', '555-0104', '321 Elm St', 'Houston', 'TX', '77001'),
('Charlie', 'Davis', 'charlie.davis@email.com', '555-0105', '654 Maple Ave', 'Phoenix', 'AZ', '85001'),
('Eva', 'Wilson', 'eva.wilson@email.com', '555-0106', '987 Cedar St', 'Philadelphia', 'PA', '19101'),
('Frank', 'Miller', 'frank.miller@email.com', '555-0107', '147 Birch Ave', 'San Antonio', 'TX', '78201'),
('Grace', 'Moore', 'grace.moore@email.com', '555-0108', '258 Walnut St', 'San Diego', 'CA', '92101'),
('Henry', 'Taylor', 'henry.taylor@email.com', '555-0109', '369 Ash Ave', 'Dallas', 'TX', '75201'),
('Ivy', 'Anderson', 'ivy.anderson@email.com', '555-0110', '741 Cherry St', 'San Jose', 'CA', '95101');

-- Insert sample products
INSERT INTO sales.products (product_name, category, subcategory, brand, price, cost, description) VALUES
('Laptop Pro 15"', 'Electronics', 'Computers', 'TechBrand', 1299.99, 899.99, 'High-performance laptop with 15-inch display'),
('Wireless Headphones', 'Electronics', 'Audio', 'SoundCorp', 199.99, 120.00, 'Premium wireless headphones with noise cancellation'),
('Smart Watch', 'Electronics', 'Wearables', 'WearTech', 399.99, 250.00, 'Advanced smartwatch with health tracking'),
('Coffee Maker', 'Home & Garden', 'Kitchen', 'BrewMaster', 89.99, 45.00, 'Automatic drip coffee maker'),
('Office Chair', 'Furniture', 'Office', 'ComfortSeating', 249.99, 150.00, 'Ergonomic office chair with lumbar support'),
('Running Shoes', 'Sports', 'Footwear', 'RunFast', 129.99, 65.00, 'Lightweight running shoes for athletes'),
('Book - Data Science', 'Books', 'Technology', 'TechPublisher', 49.99, 25.00, 'Comprehensive guide to data science'),
('Smartphone', 'Electronics', 'Mobile', 'MobileTech', 799.99, 500.00, 'Latest smartphone with advanced camera'),
('Desk Lamp', 'Home & Garden', 'Lighting', 'BrightLights', 59.99, 30.00, 'LED desk lamp with adjustable brightness'),
('Backpack', 'Fashion', 'Bags', 'TravelGear', 79.99, 40.00, 'Durable backpack for daily use');

-- Insert sample orders
INSERT INTO sales.orders (customer_id, order_date, total_amount, status, shipping_address) VALUES
(1, '2024-01-15', 1299.99, 'completed', '123 Main St, New York, NY 10001'),
(2, '2024-01-16', 289.98, 'completed', '456 Oak Ave, Los Angeles, CA 90210'),
(3, '2024-01-17', 399.99, 'shipped', '789 Pine St, Chicago, IL 60601'),
(4, '2024-01-18', 139.98, 'completed', '321 Elm St, Houston, TX 77001'),
(5, '2024-01-19', 249.99, 'processing', '654 Maple Ave, Phoenix, AZ 85001'),
(6, '2024-01-20', 929.98, 'completed', '987 Cedar St, Philadelphia, PA 19101'),
(7, '2024-01-21', 59.99, 'shipped', '147 Birch Ave, San Antonio, TX 78201'),
(8, '2024-01-22', 879.98, 'completed', '258 Walnut St, San Diego, CA 92101'),
(9, '2024-01-23', 329.98, 'pending', '369 Ash Ave, Dallas, TX 75201'),
(10, '2024-01-24', 179.98, 'completed', '741 Cherry St, San Jose, CA 95101');

-- Insert sample order items
INSERT INTO sales.order_items (order_id, product_id, quantity, unit_price, total_price) VALUES
-- Order 1: Laptop Pro
(1, 1, 1, 1299.99, 1299.99),
-- Order 2: Headphones + Coffee Maker
(2, 2, 1, 199.99, 199.99),
(2, 4, 1, 89.99, 89.99),
-- Order 3: Smart Watch
(3, 3, 1, 399.99, 399.99),
-- Order 4: Running Shoes + Book
(4, 6, 1, 129.99, 129.99),
(4, 7, 1, 49.99, 49.99),
-- Order 5: Office Chair
(5, 5, 1, 249.99, 249.99),
-- Order 6: Smartphone + Desk Lamp
(6, 8, 1, 799.99, 799.99),
(6, 9, 1, 59.99, 59.99),
(6, 10, 1, 79.99, 79.99),
-- Order 7: Desk Lamp
(7, 9, 1, 59.99, 59.99),
-- Order 8: Smartphone + Backpack
(8, 8, 1, 799.99, 799.99),
(8, 10, 1, 79.99, 79.99),
-- Order 9: Office Chair + Running Shoes
(9, 5, 1, 249.99, 249.99),
(9, 6, 1, 129.99, 129.99),
-- Order 10: Headphones + Book
(10, 2, 1, 199.99, 199.99),
(10, 7, 1, 49.99, 49.99);

-- Add more historical data for better analytics
INSERT INTO sales.orders (customer_id, order_date, total_amount, status, shipping_address) VALUES
-- February 2024 orders
(1, '2024-02-01', 249.98, 'completed', '123 Main St, New York, NY 10001'),
(2, '2024-02-05', 459.98, 'completed', '456 Oak Ave, Los Angeles, CA 90210'),
(3, '2024-02-10', 89.99, 'completed', '789 Pine St, Chicago, IL 60601'),
(4, '2024-02-15', 799.99, 'completed', '321 Elm St, Houston, TX 77001'),
(5, '2024-02-20', 329.98, 'completed', '654 Maple Ave, Phoenix, AZ 85001'),
-- March 2024 orders
(6, '2024-03-01', 199.99, 'completed', '987 Cedar St, Philadelphia, PA 19101'),
(7, '2024-03-05', 1549.98, 'completed', '147 Birch Ave, San Antonio, TX 78201'),
(8, '2024-03-10', 139.98, 'completed', '258 Walnut St, San Diego, CA 92101'),
(9, '2024-03-15', 649.98, 'completed', '369 Ash Ave, Dallas, TX 75201'),
(10, '2024-03-20', 79.99, 'completed', '741 Cherry St, San Jose, CA 95101');

-- Insert corresponding order items for the new orders
INSERT INTO sales.order_items (order_id, product_id, quantity, unit_price, total_price) VALUES
-- February orders
(11, 5, 1, 249.99, 249.99), -- Office Chair
(12, 3, 1, 399.99, 399.99), -- Smart Watch
(12, 9, 1, 59.99, 59.99),   -- Desk Lamp
(13, 4, 1, 89.99, 89.99),   -- Coffee Maker
(14, 8, 1, 799.99, 799.99), -- Smartphone
(15, 6, 1, 129.99, 129.99), -- Running Shoes
(15, 2, 1, 199.99, 199.99), -- Headphones
-- March orders
(16, 2, 1, 199.99, 199.99), -- Headphones
(17, 1, 1, 1299.99, 1299.99), -- Laptop Pro
(17, 5, 1, 249.99, 249.99),   -- Office Chair
(18, 6, 1, 129.99, 129.99),   -- Running Shoes
(18, 7, 1, 49.99, 49.99),     -- Book
(19, 8, 1, 799.99, 799.99),   -- Smartphone
(20, 10, 1, 79.99, 79.99);    -- Backpack

-- Refresh analytics table
TRUNCATE analytics.daily_sales;
INSERT INTO analytics.daily_sales 
SELECT 
    order_date,
    COUNT(*) as order_count,
    SUM(total_amount) as total_revenue,
    AVG(total_amount) as avg_order_value
FROM sales.orders
GROUP BY order_date
ORDER BY order_date;

-- Create additional analytics views
CREATE VIEW analytics.monthly_sales AS
SELECT 
    DATE_TRUNC('month', order_date) as month,
    COUNT(*) as order_count,
    SUM(total_amount) as total_revenue,
    AVG(total_amount) as avg_order_value
FROM sales.orders
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month;

CREATE VIEW analytics.product_performance AS
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    p.brand,
    COUNT(oi.order_item_id) as times_sold,
    SUM(oi.quantity) as total_quantity_sold,
    SUM(oi.total_price) as total_revenue,
    AVG(oi.unit_price) as avg_selling_price,
    (AVG(oi.unit_price) - p.cost) as avg_profit_per_unit
FROM sales.products p
LEFT JOIN sales.order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, p.category, p.brand, p.cost
ORDER BY total_revenue DESC NULLS LAST;

CREATE VIEW analytics.customer_analytics AS
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    c.city,
    c.state,
    COUNT(o.order_id) as total_orders,
    SUM(o.total_amount) as total_spent,
    AVG(o.total_amount) as avg_order_value,
    MAX(o.order_date) as last_order_date,
    MIN(o.order_date) as first_order_date
FROM sales.customers c
LEFT JOIN sales.orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.email, c.city, c.state
ORDER BY total_spent DESC NULLS LAST;