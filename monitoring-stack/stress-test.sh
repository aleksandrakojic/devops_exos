# stress-test.sh
#!/bin/bash
echo "Starting system stress test..."

# CPU stress test
echo "Generating CPU load..."
for i in $(seq $(nproc)); do
  yes > /dev/null &
done

# Memory stress test  
echo "Generating memory pressure..."
stress-ng --vm 2 --vm-bytes 75% --timeout 300s &

# Monitor alerts
echo "Monitoring for alerts..."
for i in {1..20}; do
  echo "Checking alerts (attempt $i)..."
  curl -s http://localhost:9090/api/v1/alerts | jq '.data.alerts[] | select(.state=="firing") | {alertname: .labels.alertname, state: .state}'
  sleep 30
done

# Cleanup
echo "Cleaning up stress test..."
killall yes 2>/dev/null
killall stress-ng 2>/dev/null
echo "Stress test complete!"