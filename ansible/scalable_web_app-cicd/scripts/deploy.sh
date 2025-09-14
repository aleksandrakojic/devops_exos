#!/bin/bash

# Define variables
DOCKER_IMAGE="yourdockerhub/yourapp:latest"
CONTAINER_NAME="webapp"

# Pull the latest image
echo "Pulling latest Docker image..."
docker pull $DOCKER_IMAGE

# Stop and remove existing container if it exists
if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
    echo "Stopping existing container..."
    docker stop $CONTAINER_NAME
fi

if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
    echo "Removing existing container..."
    docker rm $CONTAINER_NAME
fi

# Run the new container
echo "Starting new container..."
docker run -d --name $CONTAINER_NAME -p 80:80 $DOCKER_IMAGE

echo "Deployment completed!"