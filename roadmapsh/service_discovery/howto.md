
## Step-by-Step Guide

### 1. Set Up Consul

- **Install Consul:** Download and run Consul in dev mode for simplicity.

```bash
consul agent -dev
```

- **Verify:** Access the Consul UI at `http://localhost:8500`.

---

### 2. Create Dummy Services

**Language Choice:** Use a simple language like Python, Node.js, or Go.

**Example (Python + Flask):**

```python
from flask import Flask, jsonify
import requests
import time
import socket

app = Flask(__name__)

SERVICE_NAME = "ServiceA"  # Change for each service (A, B, C)
SERVICE_ID = f"{SERVICE_NAME}-{socket.gethostname()}"

def register_service():
    registration = {
        "ID": SERVICE_ID,
        "Name": SERVICE_NAME,
        "Address": "localhost",
        "Port": 5000,  # change per service
        "Check": {
            "HTTP": f"http://localhost:5000/health",
            "Interval": "10s"
        }
    }
    requests.put("http://localhost:8500/v1/agent/service/register", json=registration)

@app.route('/info')
def info():
    return jsonify({
        "service": SERVICE_NAME,
        "timestamp": time.time()
    })

@app.route('/health')
def health():
    return "OK"

if __name__ == '__main__':
    register_service()
    app.run(port=5000)
```

- **Repeat for each service (A, B, C)** with different ports and `SERVICE_NAME`.
- **Automatic registration:** Run this script on startup, or use a script to start multiple services.

---

### 3. Service Registration with Consul

- **Self-registration:** As shown above, each service registers itself with Consul on startup.
- **Check registration:** Verify via Consul UI or API:

```bash
curl http://localhost:8500/v1/agent/services
```

---

### 4. Implement API Gateway

Your API Gateway will discover services via Consul and route requests.

**Approach:**

- Use Consul DNS interface (`service-name.service.consul`) or API.

**Simple example (Python + Flask):**

```python
import requests
from flask import Flask, request, jsonify

app = Flask(__name__)

def discover_service(service_name):
    # Using DNS
    # hostname = f"{service_name}.service.consul"
    # response = requests.get(f"http://{hostname}:80/info")
    # return response

    # Using Consul API
    response = requests.get(f"http://localhost:8500/v1/catalog/service/{service_name}")
    services = response.json()
    if services:
        # pick a random service instance
        service = services[0]
        address = service['ServiceAddress']
        port = service['ServicePort']
        return f"http://{address}:{port}"
    return None

@app.route('/proxy/<service_name>/info')
def proxy_service(service_name):
    service_url = discover_service(service_name)
    if not service_url:
        return jsonify({"error": "Service not found"}), 404
    resp = requests.get(f"{service_url}/info")
    return jsonify(resp.json())

if __name__ == '__main__':
    app.run(port=8000)
```

- **Usage:** Access via `http://localhost:8000/proxy/ServiceA/info`.

---

### 5. Test Your Setup

- Start Consul.
- Launch your dummy services; ensure they register successfully.
- Run your API Gateway.
- Make requests to the API Gateway, e.g.:

```bash
curl http://localhost:8000/proxy/ServiceA/info
```

- Verify responses contain the timestamp and service name.

---

## Additional Tips

- **Health Checks:** Properly implement health checks so Consul can automatically deregister unhealthy services.
- **Service Discovery:** You can also explore Consul DNS for service discovery, which simplifies routing.
- **Scaling:** Add more services or instances to test load balancing.
- **Security:** For production, implement ACLs, TLS, and secure registration.

---
