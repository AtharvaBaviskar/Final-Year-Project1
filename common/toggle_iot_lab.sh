#!/bin/bash

# List of container names to manage
containers=("smart_lock_api" "smart_light_api" "smart_camera_api" "mqtt-broker" "rtsp_server_osi")

echo "🔍 Checking IoT lab container status..."

# Count how many are running
running_count=0
for container in "${containers[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        running_count=$((running_count+1))
    fi
done

# === CASE 1: All containers are running → STOP ===
if [ "$running_count" -eq "${#containers[@]}" ]; then
    echo "🛑 All containers are up. Stopping IoT lab..."
    docker-compose down
    echo "✅ IoT lab stopped."
    exit 0
fi

# === CASE 2: All containers are stopped → START ===
if [ "$running_count" -eq 0 ]; then
    echo "🚀 All containers are down. Starting IoT lab..."
    docker-compose up -d --build

    echo ""
    echo "✅ IoT lab started!"
    echo ""
    echo "📡 Access your devices at:"
    echo ""
    echo "🔐 Smart Lock:       http://localhost:1882/status"
    echo "💡 Smart Light:      http://localhost:1881/status"
    echo "📷 Smart Camera:     http://localhost:1887/status"
    echo "🎥 RTSP Stream:      rtsp://localhost:8554/live"
    echo "🛰️ MQTT Broker:      mqtt://192.168.250.14:1883"
    echo ""
    exit 0
fi

# === CASE 3: Mixed states ===
echo "Some containers are running and some are stopped."
echo "Manually stop with: docker-compose down"
echo "Manually start with: docker-compose up -d --build"
