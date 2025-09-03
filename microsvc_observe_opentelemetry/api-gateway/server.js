require('./tracing');
const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const { trace } = require('@opentelemetry/api');
const axios = require('axios');

const app = express();
const port = process.env.PORT || 3000;
const tracer = trace.getTracer('api-gateway');

app.use(express.json());

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', service: 'api-gateway' });
});

// Aggregate endpoint - demonstrates distributed tracing
app.get('/api/user/:userId/orders', async (req, res) => {
  const span = tracer.startSpan('get_user_orders_aggregate');
  const userId = req.params.userId;
  
  try {
    span.setAttributes({
      'user.id': userId,
      'operation.type': 'aggregate'
    });
    
    // Fetch user details
    const userResponse = await axios.get(`http://user-service:3001/users/${userId}`);
    const user = userResponse.data;
    
    // Fetch user's orders
    const ordersResponse = await axios.get('http://order-service:3002/orders');
    const allOrders = ordersResponse.data;
    const userOrders = allOrders.filter(order => order.user_id == userId);
    
    // Enrich orders with inventory details
    for (let order of userOrders) {
      for (let item of order.items) {
        try {
          const inventoryResponse = await axios.get(`http://inventory-service:3003/inventory/${item.product_id}`);
          item.product_details = inventoryResponse.data;
        } catch (error) {
          console.error(`Failed to fetch inventory for product ${item.product_id}:`, error.message);
          item.product_details = null;
        }
      }
    }
    
    const result = {
      user: user,
      orders: userOrders,
      total_orders: userOrders.length
    };
    
    span.setAttributes({
      'user.orders_count': userOrders.length,
      'response.size': JSON.stringify(result).length
    });
    
    res.json(result);
  } catch (error) {
    span.recordException(error);
    console.error('Error in aggregate endpoint:', error.message);
    res.status(500).json({ error: 'Failed to aggregate user orders' });
  } finally {
    span.end();
  }
});

// Proxy requests to microservices
app.use('/api/users', createProxyMiddleware({
  target: 'http://user-service:3001',
  changeOrigin: true,
  pathRewrite: { '^/api/users': '/users' }
}));

app.use('/api/orders', createProxyMiddleware({
  target: 'http://order-service:3002',
  changeOrigin: true,
  pathRewrite: { '^/api/orders': '/orders' }
}));

app.use('/api/inventory', createProxyMiddleware({
  target: 'http://inventory-service:3003',
  changeOrigin: true,
  pathRewrite: { '^/api/inventory': '/inventory' }
}));

app.listen(port, () => {
  console.log(`API Gateway listening on port ${port}`);
});