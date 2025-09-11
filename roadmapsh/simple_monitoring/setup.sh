#!/bin/bash

# Install dependencies (if needed)
sudo apt update
sudo apt install -y curl

# Download and run Netdata installer

bash <(curl -Ss https://get.netdata.cloud/kickstart.sh > /tmp/netdata-kickstart.sh && sh /tmp/netdata-kickstart.sh --stable-channel --disable-telemetry) --dont-wait

# Optional: Check status
sudo systemctl status netdata

