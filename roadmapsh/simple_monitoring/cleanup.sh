#!/bin/bash

# Stop Netdata
if systemctl is-active --quiet netdata; then
    echo "Stopping Netdata service..."
    sudo systemctl stop netdata

    echo "Netdata service stopped."

else
    echo "Netdata service is not running."
fi

# Uninstall Netdata
read -r -p "Are you sure you want to uninstall Netdata? (y/n): " confirm
if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then

    echo "Uninstalling Netdata..."
        
    sudo bash <(curl https://get.netdata.cloud/kickstart.sh > /tmp/netdata-kickstart.sh && sh /tmp/netdata-kickstart.sh --uninstall)

    # Remove residual files
    echo "Removing residual Netdata files..."
    sudo rm -rf /etc/netdata
    sudo rm -rf /var/lib/netdata
    sudo rm -rf /var/cache/netdata
    sudo rm -rf /var/log/netdata

    echo "Netdata has been successfully uninstalled."
else
    echo "Uninstallation cancelled."
fi