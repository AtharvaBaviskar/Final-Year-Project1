#!/bin/bash

echo "[+] 🚀 Starting Smart Camera Project Cleanup and Launch (with sudo)..."

# Define container names
containers=("smart_camera_api" "mqtt-broker" "rtsp_server_osi")

# Stop and remove conflicting containers
for container in "${containers[@]}"; do
    if sudo docker ps -a --format '{{.Names}}' | grep -q "^$container$"; then
        echo "[*] Removing existing container: $container"
        sudo docker rm -f "$container"
    fi
done

# Navigate to the docker-compose project directory
cd "$HOME/Documents/Final Year Master's Project/smart_camera_osi_final_auto_fix (2)" || {
    echo "[-] ❌ Project directory not found!"
    exit 1
}

# Rebuild and launch the containers
echo "[*] Rebuilding and starting docker-compose..."
sudo docker-compose up -d --build

# Wait a few seconds
sleep 5

echo "[*] Following logs for Smart Camera API..."
sudo docker logs -f smart_camera_api &

# Check if Smart Camera API is running on port 1887
echo "[*] Verifying Smart Camera API status..."
if curl -s http://localhost:1887/status | grep -q "streaming"; then
    echo "[+] ✅ Smart Camera API is up and responding!"
else
    echo "[-] ⚠️ Smart Camera API did not respond on port 1887."
fi

echo "[+] 🎯 All done. You're ready for vulnerability testing!"


