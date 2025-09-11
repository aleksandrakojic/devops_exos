#!/bin/bash

while true; do
    echo "$(date): Dummy service is running..." >> /var/log/dummy-service.log
    sleep 10
done