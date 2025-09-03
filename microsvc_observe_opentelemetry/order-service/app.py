import os
import time
import random
import requests
from flask import Flask, jsonify, request
from opentelemetry import trace, baggage
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.resources import Resource
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor

# Configure OpenTelemetry
resource = Resource.create({
    "service.name": "order-service",
    "service.version": "1.0.0"
})

trace.set_tracer_provider(TracerProvider(resource=resource))
tracer = trace.get_tracer(__name__)

# Configure OTLP exporter
otlp_exporter = OTLPSpanExporter(
    endpoint=os.getenv("OTEL_EXPORTER_OTLP_TRACES_ENDPOINT", 
                      "http://otel-collector.observability.svc.cluster.local:4318/v1/traces")
)
span_processor = BatchSpanProcessor(otlp_exporter)
trace.get_tracer_provider().add_span_processor(span_processor)

app = Flask(__name__)

# Auto-instrument Flask and requests
FlaskInstrumentor().instrument_app(app)
RequestsInstrumentor().instrument()

# Sample orders data
orders = [
    {"id": 1, "user_id": 1, "items": [{"product_id": 101, "quantity": 2}], "total": 99.98, "status": "completed"},
    {"id": 2, "user_id": 2, "items": [{"product_id": 102, "quantity": 1}], "total": 49.99, "status": "pending"}
]

@app.route('/health')
def health():
    return jsonify({"status": "healthy", "service": "order-service"})

@app.route('/orders')
def get_orders():
    with tracer.start_as_current_span("get_all_orders") as span:
        # Simulate database query
        time.sleep(random.uniform(0.01, 0.1))
        
        span.set_attributes({
            "order.count": len(orders),
            "operation.type": "read"
        })
        
        return jsonify(orders)

@app.route('/orders/<int:order_id>')
def get_order(order_id):
    with tracer.start_as_current_span("get_order_by_id") as span:
        span.set_attributes({
            "order.id": order_id,
            "operation.type": "read"
        })
        
        # Simulate database lookup
        time.sleep(random.uniform(0.01, 0.05))
        
        order = next((o for o in orders if o["id"] == order_id), None)
        if not order:
            span.set_status(trace.Status(trace.StatusCode.ERROR, "Order not found"))
            return jsonify({"error": "Order not found"}), 404
        
        return jsonify(order)

@app.route('/orders', methods=['POST'])
def create_order():
    with tracer.start_as_current_span("create_order") as span:
        data = request.get_json()
        user_id = data.get('user_id')
        items = data.get('items', [])
        
        span.set_attributes({
            "order.user_id": user_id,
            "order.items_count": len(items),
            "operation.type": "write"
        })
        
        # Verify user exists (call user service)
        with tracer.start_as_current_span("verify_user") as user_span:
            try:
                user_response = requests.get(
                    f"http://user-service:3001/users/{user_id}",
                    timeout=5
                )
                user_span.set_attributes({
                    "http.status_code": user_response.status_code,
                    "user.id": user_id
                })
                
                if user_response.status_code != 200:
                    return jsonify({"error": "Invalid user"}), 400
            except requests.RequestException as e:
                user_span.record_exception(e)
                return jsonify({"error": "User service unavailable"}), 503
        
        # Check inventory (call inventory service)
        with tracer.start_as_current_span("check_inventory") as inv_span:
            for item in items:
                try:
                    inv_response = requests.get(
                        f"http://inventory-service:3003/inventory/{item['product_id']}",
                        timeout=5
                    )
                    inv_span.set_attributes({
                        "product.id": item['product_id'],
                        "requested.quantity": item['quantity']
                    })
                    
                    if inv_response.status_code != 200:
                        return jsonify({"error": f"Product {item['product_id']} not found"}), 400
                        
                except requests.RequestException as e:
                    inv_span.record_exception(e)
                    return jsonify({"error": "Inventory service unavailable"}), 503
        
        # Create order
        new_order = {
            "id": len(orders) + 1,
            "user_id": user_id,
            "items": items,
            "total": sum(item.get('price', 25.99) * item['quantity'] for item in items),
            "status": "pending"
        }
        
        orders.append(new_order)
        
        span.set_attributes({
            "order.id": new_order["id"],
            "order.total": new_order["total"]
        })
        
        return jsonify(new_order), 201

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=3002, debug=True)