require('./tracing');
const express = require('express');
const { trace, context, SpanStatusCode } = require('@opentelemetry/api');

const app = express();
const port = process.env.PORT || 3001;
const tracer = trace.getTracer('user-service');

app.use(express.json());

// Simulated user database
const users = [
  { id: 1, name: 'John Doe', email: 'john@example.com' },
  { id: 2, name: 'Jane Smith', email: 'jane@example.com' }
];

app.get('/health', (req, res) => {
  res.json({ status: 'healthy', service: 'user-service' });
});

app.get('/users', async (req, res) => {
  const span = tracer.startSpan('get_all_users');
  try {
    // Simulate database query delay
    await new Promise(resolve => setTimeout(resolve, Math.random() * 100));
    
    span.setAttributes({
      'user.count': users.length,
      'operation.type': 'read'
    });
    
    res.json(users);
    span.setStatus({ code: SpanStatusCode.OK });
  } catch (error) {
    span.recordException(error);
    span.setStatus({ code: SpanStatusCode.ERROR, message: error.message });
    res.status(500).json({ error: 'Internal server error' });
  } finally {
    span.end();
  }
});

app.get('/users/:id', async (req, res) => {
  const span = tracer.startSpan('get_user_by_id');
  const userId = parseInt(req.params.id);
  
  try {
    span.setAttributes({
      'user.id': userId,
      'operation.type': 'read'
    });
    
    // Simulate database query
    await new Promise(resolve => setTimeout(resolve, Math.random() * 50));
    
    const user = users.find(u => u.id === userId);
    if (!user) {
      span.setStatus({ code: SpanStatusCode.ERROR, message: 'User not found' });
      return res.status(404).json({ error: 'User not found' });
    }
    
    res.json(user);
    span.setStatus({ code: SpanStatusCode.OK });
  } catch (error) {
    span.recordException(error);
    span.setStatus({ code: SpanStatusCode.ERROR, message: error.message });
    res.status(500).json({ error: 'Internal server error' });
  } finally {
    span.end();
  }
});

app.listen(port, () => {
  console.log(`User service listening on port ${port}`);
});