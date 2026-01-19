-- Initial database setup for DevOps test
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    category VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO products (name, price, category) VALUES
('DevOps T-Shirt', 25.99, 'apparel'),
('Kubernetes Mug', 15.50, 'accessories'),
('Docker Stickers', 5.99, 'accessories'),
('Terraform Guide', 39.99, 'books'),
('Azure Certification', 199.99, 'courses')
ON CONFLICT DO NOTHING;

-- Simple cart table (optional)
CREATE TABLE IF NOT EXISTS cart_items (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(255) NOT NULL,
    product_id INTEGER REFERENCES products(id),
    quantity INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
