#!/bin/bash

# Script to analyze basic server performance stats on Linux

echo "===== Server Performance Stats ====="

# OS Version (Stretch goal)
echo -e "\nOS Version:"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "$PRETTY_NAME"
elif command -v lsb_release &> /dev/null; then
    lsb_release -a 2>/dev/null | grep Description | cut -f2-
else
    echo "Unable to determine OS version."
fi

# Uptime (Stretch goal)
echo -e "\nUptime:"
uptime -p

# Load Average (Stretch goal)
echo -e "\nLoad Average:"
uptime | awk -F'load average:' '{print $2}' | sed 's/^ *//'

# Logged in Users (Stretch goal)
echo -e "\nLogged in Users:"
who

# Total CPU Usage
echo -e "\nTotal CPU Usage:"
cpu_idle=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/")
cpu_usage=$(awk "BEGIN {print 100 - $cpu_idle}")
echo "${cpu_usage}%"

# Total Memory Usage
echo -e "\nTotal Memory Usage:"
mem_total=$(free -m | awk '/Mem:/ {print $2}')
mem_used=$(free -m | awk '/Mem:/ {print $3}')
mem_free=$(free -m | awk '/Mem:/ {print $4}')
mem_perc=$(awk "BEGIN {printf \"%.2f\", ($mem_used / $mem_total) * 100}")
echo "Free: ${mem_free}MB | Used: ${mem_used}MB / Total: ${mem_total}MB (${mem_perc}%)"

# Total Disk Usage (for root filesystem)
echo -e "\nTotal Disk Usage (Root Filesystem):"
disk_total=$(df -h / | tail -1 | awk '{print $2}')
disk_used=$(df -h / | tail -1 | awk '{print $3}')
disk_free=$(df -h / | tail -1 | awk '{print $4}')
disk_perc=$(df -h / | tail -1 | awk '{print $5}')
echo "Free: ${disk_free} | Used: ${disk_used} / Total: ${disk_total} (${disk_perc})"

# Top 5 Processes by CPU Usage
echo -e "\nTop 5 Processes by CPU Usage:"
ps aux --sort=-%cpu | head -n 6

# Top 5 Processes by Memory Usage
echo -e "\nTop 5 Processes by Memory Usage:"
ps aux --sort=-%mem | head -n 6

# Failed Login Attempts (Stretch goal, may require sudo or specific log access)
echo -e "\nFailed Login Attempts (from auth.log, if available):"
if [ -r /var/log/auth.log ]; then
    grep "Failed password" /var/log/auth.log | wc -l
else
    echo "Unable to access /var/log/auth.log (may require sudo)."
fi

echo "===== End of Stats ====="