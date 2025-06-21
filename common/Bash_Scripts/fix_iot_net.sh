#!/bin/bash

# Define network name and settings
NETWORK_NAME="iot_net"
SUBNET="192.168.251.0/24"
GATEWAY="192.168.251.1"

# Check if the network already exists
if docker network inspect "$NETWORK_NAME" >/dev/null 2>&1; then
    echo "[✓] Docker network '$NETWORK_NAME' already exists."
else
    echo "[!] Docker network '$NETWORK_NAME' not found. Creating it now..."
    docker network create \
        --driver bridge \
        --subnet $SUBNET \
        --gateway $GATEWAY \
        $NETWORK_NAME

    if [ $? -eq 0 ]; then
        echo "[+] Network '$NETWORK_NAME' created successfully."
    else
        echo "[✗] Failed to create network '$NETWORK_NAME'."
        exit 1
    fi
fi
