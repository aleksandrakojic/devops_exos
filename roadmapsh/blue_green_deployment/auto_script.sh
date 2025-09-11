#!/bin/bash

# Build new app image (if needed)
docker build -t myapp:latest .

# Deploy green environment
docker-compose up -d app_green

# Wait for validation...

# Switch traffic to green
sed -i 's/server localhost:8081;/server localhost:8082;/g' nginx.conf
docker-compose restart nginx_proxy

# Cleanup blue if desired
docker stop app_blue
docker rm app_blue