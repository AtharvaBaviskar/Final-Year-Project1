#!/bin/bash

# === Step 1: Identify Smart Camera container ===
CONTAINER_NAME=$(docker ps --format "{{.Names}}" | grep -i smart_camera)

if [[ -z "$CONTAINER_NAME" ]]; then
    echo "❌ ERROR: Smart Camera container not found."
    exit 1
fi

echo "✅ Found Smart Camera container: $CONTAINER_NAME"

# === Step 2: Ensure /app/simulation logs exists ===
echo "📁 Checking/Creating simulation log folder..."
docker exec "$CONTAINER_NAME" bash -c 'mkdir -p "/app/simulation logs"'

# === Step 3: Touch and fix permissions on simulation_log.txt ===
echo "🛠 Touching log file and setting permissions..."
docker exec "$CONTAINER_NAME" bash -c 'touch "/app/simulation logs/simulation_log.txt" && chmod 666 "/app/simulation logs/simulation_log.txt"'

# === Step 4: Restart container using docker-compose ===
echo "🔁 Restarting container using docker-compose..."
docker-compose restart smart-camera

# === Step 5: Confirm log file is writable ===
echo "✅ Verifying log write..."
docker exec "$CONTAINER_NAME" bash -c 'echo "[TEST] $(date) - MQTT test write OK" >> "/app/simulation logs/simulation_log.txt"'

echo "🎯 Done! You can now re-run your MQTT spoofing attack."
echo "📄 Log file path: smart-camera/simulation logs/simulation_log.txt"
