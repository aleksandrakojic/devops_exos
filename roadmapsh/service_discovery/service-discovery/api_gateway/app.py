from flask import Flask, jsonify, request
import requests
import random

app = Flask(__name__)

def discover_service(service_name):
    # Query Consul catalog for services
    url = f"http://host.docker.internal:8500/v1/catalog/service/{service_name}"
    try:
        resp = requests.get(url)
        services = resp.json()
        if services:
            service = random.choice(services)
            address = service['ServiceAddress']
            port = service['ServicePort']
            return f"http://{address}:{port}"
    except Exception as e:
        print(f"Error discovering {service_name}: {e}")
    return None

@app.route('/proxy/<service_name>/info')
def proxy_service(service_name):
    service_url = discover_service(service_name)
    if not service_url:
        return jsonify({"error": "Service not found"}), 404
    try:
        resp = requests.get(f"{service_url}/info")
        return jsonify(resp.json())
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)