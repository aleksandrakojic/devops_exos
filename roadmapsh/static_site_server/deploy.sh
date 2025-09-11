#!/bin/bash

# Define variables
LOCAL_DIR="path/to/your/site"
REMOTE_USER="your_username"
REMOTE_HOST="your_server_ip"
REMOTE_DIR="/var/www/mywebsite"

# Sync files to server
rsync -avz --delete "$LOCAL_DIR/" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR"