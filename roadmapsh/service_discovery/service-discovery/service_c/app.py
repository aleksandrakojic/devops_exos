from flask import Flask, jsonify
import requests
import socket
import time

SERVICE_NAME = "ServiceC"
PORT = 5003
SERVICE_ID = f"{SERVICE_NAME}-{socket.gethostname()}"

app = Flask(__name__)

def register_service():
    registration = {
        "ID": SERVICE_ID,
        "Name": SERVICE_NAME,
        "Address": "host.docker.internal",
        "Port": PORT,
        "Check": {
            "HTTP": f"http://host.docker.internal:{PORT}/health",
            "Interval": "10s"
        }
    }
    requests.put("http://host.docker.internal:8500/v1/agent/service/register", json=registration)

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
    app.run(host='0.0.0.0', port=PORT)