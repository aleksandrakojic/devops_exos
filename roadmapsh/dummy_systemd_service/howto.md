
# Systemd Service: Creating and Managing a Custom Dummy Service

## 1. Create the Dummy Script

First, create the script `dummy.sh` that runs indefinitely and logs a message every 10 seconds.

```bash
#!/bin/bash
# Save this as dummy.sh

while true; do
  echo "$(date): Dummy service is running..." >> /var/log/dummy-service.log
  sleep 10
done
```

### Make the script executable:

```bash
sudo chmod +x /path/to/dummy.sh
```

*(Replace `/path/to/dummy.sh` with your desired script location, e.g., `/usr/local/bin/dummy.sh`)*

---

## 2. Create the systemd Service File

Create a service file named `dummy.service` in `/etc/systemd/system/`:

```ini
# Save as /etc/systemd/system/dummy.service

[Unit]
Description=Dummy Service that logs every 10 seconds
After=network.target

[Service]
ExecStart=/path/to/dummy.sh
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

**Notes:**

- Replace `/path/to/dummy.sh` with the actual path of your script.
- `Restart=always` ensures the service restarts if it crashes.
- `RestartSec=5` waits 5 seconds before restarting.
- `StandardOutput` and `StandardError` direct logs to journal.

---

## 3. Reload systemd, Enable and Start the Service

```bash
# Reload systemd to recognize the new service
sudo systemctl daemon-reload

# Enable the service to start on boot
sudo systemctl enable dummy

# Start the service immediately
sudo systemctl start dummy
```

---

## 4. Manage the Service

You can now interact with your `dummy` service:

```bash
# Check the status
sudo systemctl status dummy

# Stop the service
sudo systemctl stop dummy

# Start the service
sudo systemctl start dummy

# Disable the service from starting on boot
sudo systemctl disable dummy

# Check logs in real-time
sudo journalctl -u dummy -f
```

---

## 5. Validate the Setup

- **Logs:** Confirm output appears in `/var/log/dummy-service.log` or via `journalctl`.
- **Service restart:** If you kill the process, systemd should automatically restart it.

---

## Summary

- You created a script `dummy.sh` that logs every 10 seconds.
- You created a `dummy.service` systemd unit to manage the script.
- You used `systemctl` commands to control and monitor the service.
- You viewed logs with `journalctl`.

---

Would you like me to prepare a full directory structure example or give you tips on debugging if something doesn't work?
