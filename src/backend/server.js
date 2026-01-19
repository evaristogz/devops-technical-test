const express = require('express');
const cors = require('cors');
const helmet = require('helmet');

const app = express();
const PORT = process.env.PORT || 8080;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Mock data for when database is not available
const mockProducts = [
  { id: 1, name: 'DevOps T-Shirt', price: 25.99, category: 'apparel' },
  { id: 2, name: 'Kubernetes Mug', price: 15.50, category: 'accessories' },
  { id: 3, name: 'Docker Stickers', price: 5.99, category: 'accessories' },
  { id: 4, name: 'Terraform Guide', price: 39.99, category: 'books' },
  { id: 5, name: 'Azure Certification', price: 199.99, category: 'courses' },
];

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    version: '1.0.0',
    environment: process.env.NODE_ENV || 'development'
  });
});

// Readiness check endpoint
app.get('/ready', (req, res) => {
  const checks = {
    database: true,  // Simulated - in real app would check DB connection
    redis: true,     // Simulated - in real app would check Redis connection
    overall: true
  };
  
  res.status(200).json(checks);
});

// Get all products
app.get('/api/products', (req, res) => {
  console.log(`[${new Date().toISOString()}] GET /api/products`);
  
  // Simulate database delay
  setTimeout(() => {
    res.json(mockProducts);
  }, Math.random() * 100); // 0-100ms delay
});

// Add to cart (simplified)
app.post('/api/cart', (req, res) => {
  const { productId, quantity = 1 } = req.body;
  console.log(`[${new Date().toISOString()}] POST /api/cart - Product: ${productId}, Quantity: ${quantity}`);
  
  const product = mockProducts.find(p => p.id === parseInt(productId));
  if (!product) {
    return res.status(404).json({ error: 'Product not found' });
  }
  
  res.json({ 
    message: 'Product added to cart',
    product: product,
    quantity: quantity
  });
});

// Get cart (simplified)
app.get('/api/cart', (req, res) => {
  console.log(`[${new Date().toISOString()}] GET /api/cart`);
  
  // Simulated cart response
  res.json({
    items: [],
    total: 0,
    message: 'Cart functionality simulated'
  });
});

// Metrics endpoint (for monitoring)
app.get('/metrics', (req, res) => {
  const metrics = {
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    pid: process.pid,
    timestamp: new Date().toISOString()
  };
  
  res.json(metrics);
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err.stack);
  res.status(500).json({ 
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong'
  });
});

// 404 handler
app.use((req, res) => {
  console.log(`[${new Date().toISOString()}] 404 - ${req.method} ${req.path}`);
  res.status(404).json({ error: 'Endpoint not found' });
});

// Graceful shutdown
const gracefulShutdown = (signal) => {
  console.log(`\n${signal} received, shutting down gracefully...`);
  process.exit(0);
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

// Start server
app.listen(PORT, () => {
  console.log(`🚀 E-commerce Backend running on port ${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/health`);
  console.log(`🛒 Products API: http://localhost:${PORT}/api/products`);
  console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
});

module.exports = app;
