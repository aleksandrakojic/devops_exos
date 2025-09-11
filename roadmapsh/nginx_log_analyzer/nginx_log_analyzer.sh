#!/bin/bash

# Script to analyze nginx access log

LOGFILE="$1"

if [ -z "$LOGFILE" ] || [ ! -f "$LOGFILE" ]; then
    echo "Usage: $0 nginx_access.log"
    exit 1
fi

# Function to format top 5 output
format_top5() {
    sort | uniq -c | sort -rn | head -5 | awk '{ cnt = $1; item = substr($0, index($0, " ") + 1); print item " - " cnt " requests" }'
}

echo "Top 5 IP addresses with the most requests:"
awk '{print $1}' "$LOGFILE" | format_top5

echo "Top 5 most requested paths:"
cut -d'"' -f2 "$LOGFILE" | awk '{print $2}' | format_top5

echo "Top 5 response status codes:"
cut -d'"' -f3 "$LOGFILE" | awk '{print $2}' | format_top5

echo "Top 5 user agents:"
cut -d'"' -f6 "$LOGFILE" | format_top5

# Stretch goal: Alternative solution using sed and grep

# Alternative extraction:
# IPs: sed 's/ .*//' "$LOGFILE" | format_top5
# Paths: sed -n 's/.*"[^ ]\+ \([^ ]\+\) [^"]*".*/\1/p' "$LOGFILE" | format_top5
# Status: sed -n 's/.*" \([0-9]\+\) [0-9]\+ ".*$/\1/p' "$LOGFILE" | format_top5
# User agents: sed -n 's/.*" "\([^"]*\)"$/\1/p' "$LOGFILE" | format_top5

# You can replace the above with these for alternative method.