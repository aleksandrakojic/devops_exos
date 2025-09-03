require('./tracing');
const express = require('express');
const { trace, metrics } = require('@opentelemetry/api');

const app = express();
const port = process.env.PORT || 3003;
const tracer = trace.getTracer('inventory-service');

// Simulated inventory
const inventory = {
  101: { id: 101, name: 'Laptop', stock: 50, price: 999.99 },
  102: { id: 102, name: 'Mouse', stock: 200, price: 49.99 },
  103: { id: 103, name: 'Keyboard', stock: 75, price: 79.99 }
};

app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'healthy', service: 'inventory-service' });
});

app.get('/inventory', async (req, res) => {
  const span = tracer.startSpan('get_all_inventory');
  
  try {
    // Simulate database query
    await new Promise(resolve => setTimeout(resolve, Math.random() * 80));
    
    span.setAttributes({
      'inventory.items_count': Object.keys(inventory).length,
      'operation.type': 'read'
    });
    
    res.json(Object.values(inventory));
  } catch (error) {
    span.recordException(error);
    res.status(500).json({ error: 'Internal server error' });
  } finally {
    span.end();
  }
});

app.get('/inventory/:productId', async (req, res) => {
  const span = tracer.startSpan('get_inventory_by_product');
  const productId = parseInt(req.params.productId);
  
  try {
    span.setAttributes({
      'product.id': productId,
      'operation.type': 'read'
    });
    
    // Simulate database lookup
    await new Promise(resolve => setTimeout(resolve, Math.random() * 40));
    
    const item = inventory[productId];
    if (!item) {
      return res.status(404).json({ error: 'Product not found' });
    }
    
    span.setAttributes({
      'product.stock': item.stock,
      'product.name': item.name
    });
    
    res.json(item);
  } catch (error) {
    span.recordException(error);
    res.status(500).json({ error: 'Internal server error' });
  } finally {
    span.end();
  }
});

app.listen(port, () => {
  console.log(`Inventory service listening on port ${port}`);
});