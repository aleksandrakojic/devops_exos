#!/bin/bash

# Generate CPU load

echo "Generating CPU load..."
stress --cpu 4 --timeout 60s &

# Generate disk I/O load
echo "Starting Disk I/O load..."
dd if=/dev/zero of=/tmp/testfile bs=1M count=1024 oflag=direct &

# Wait for stress to complete
wait
echo "Load generation complete."

