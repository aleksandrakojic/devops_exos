Great! Here's a comprehensive guide to help you set up a basic monitoring dashboard using **Netdata**, including the creation of automation scripts (`setup.sh`, `test_dashboard.sh`, and `cleanup.sh`). This will give you hands-on experience with system monitoring, automation, and DevOps practices.

---

# Monitoring with Netdata – Step-by-Step Guide

## 1. Installing Netdata

### Manual Installation

On your Linux system (Ubuntu/Debian):

```bash
bash <(curl -Ss https://my-netdata.io/kickstart.sh)
```

This script automatically downloads and installs Netdata.

### Using a Script (`setup.sh`)

Create a script `setup.sh` to automate installation:

```bash
#!/bin/bash

# Install dependencies (if needed)
sudo apt update
sudo apt install -y curl

# Download and run Netdata installer
bash <(curl -Ss https://my-netdata.io/kickstart.sh)

# Optional: Check status
sudo systemctl status netdata
```

Make it executable:

```bash
chmod +x setup.sh
```

Run:

```bash
./setup.sh
```

---

## 2. Accessing the Dashboard

- After installation, Netdata runs on port **19999**.
- Open your browser and navigate to:

```
http://<your_server_ip>:19999
```

- You should see a real-time dashboard displaying system metrics.

---

## 3. Customizing the Dashboard

### Example: Add a new chart or modify existing ones

- Netdata's dashboard is highly customizable via configuration files.
- To add a custom chart or modify existing ones, you can create custom plugins or modify `/etc/netdata/` configurations.

**Simple example:** To add a custom alarm or threshold, edit `/etc/netdata/health.d/` configs.

---

## 4. Set Up Alerts

Netdata supports alerts based on thresholds.

### Example: Alert if CPU usage > 80%

Create or edit `/etc/netdata/health.d/cpu.conf`:

```ini
template: high_cpu
      on: system.cpu
      os: linux
      every: 10s
      warn: $this > 80
      crit: $this > 90
      info: CPU usage is high
      to: sysadmin
```

Ensure email notifications are configured if desired.

---

## 5. Automation Scripts

### `setup.sh` – Install Netdata

*(Already covered above)*

---

### `test_dashboard.sh` – Generate Load for Testing

Create a script to generate system load:

```bash
#!/bin/bash

# Generate CPU load
echo "Starting CPU load..."
stress --cpu 4 --timeout 60 &

# Generate disk I/O load
echo "Starting Disk I/O load..."
dd if=/dev/zero of=/tmp/testfile bs=1M count=1024 oflag=dsync &

# Wait for stress to complete
wait
echo "Load test completed."
```

Make sure `stress` is installed:

```bash
sudo apt install -y stress
```

Run:

```bash
chmod +x test_dashboard.sh
./test_dashboard.sh
```

Open the Netdata dashboard to observe metrics.

---

### `cleanup.sh` – Remove Netdata

```bash
#!/bin/bash

# Stop Netdata
sudo systemctl stop netdata

# Remove Netdata files
sudo bash -c '$(curl -Ss https://my-netdata.io/kickstart.sh) --uninstall'

# Remove residual files
sudo rm -rf /etc/netdata
sudo rm -rf /var/lib/netdata

echo "Netdata has been removed."
```

Make executable:

```bash
chmod +x cleanup.sh
```

Run:

```bash
./cleanup.sh
```

---

## 6. Learning Outcomes

- Installing and configuring real-time system monitoring
- Customizing dashboards and creating alerts
- Automating setup, testing, and cleanup with scripts
- Gaining DevOps automation experience

---

## 7. Next Steps

- Explore more advanced Netdata features like plugins and custom alarms.
- Integrate Netdata with notification systems (email, Slack).
- Automate deployment using CI/CD pipelines.

---

Would you like me to prepare a sample project directory structure or provide sample configuration files?
