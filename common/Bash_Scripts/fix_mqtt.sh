#!/bin/bash

CONFIG_DIR="$HOME/mqtt-clean/config"
CONFIG_FILE="$CONFIG_DIR/mosquitto.conf"
COMPOSE_FILE="docker-compose.yml"
INTERFACE="docker0"

echo "[*] Creating config directory: $CONFIG_DIR"
mkdir -p "$CONFIG_DIR"

echo "[*] Writing mosquitto.conf..."
cat > "$CONFIG_FILE" <<EOF
listener 1883 0.0.0.0
allow_anonymous true
persistence false
EOF

# Step 1: Ensure volume path is in docker-compose.yml
echo "[*] Ensuring docker-compose mounts correct config path..."
if ! grep -q "$CONFIG_DIR" "$COMPOSE_FILE"; then
    cp "$COMPOSE_FILE" "${COMPOSE_FILE}.bak"
    sed -i "/volumes:/a\      - $CONFIG_DIR:/mosquitto/config" "$COMPOSE_FILE"
    echo "[✓] docker-compose.yml updated (backup created)"
else
    echo "[✓] docker-compose.yml already has correct mount"
fi

# Step 2: Kill stale containers
echo "[*] Removing any stale containers..."
docker rm -f mqtt-broker rtsp_server_osi smart_camera_api flask-api 2>/dev/null

# Step 3: Restart stack
echo "[*] Restarting Docker stack..."
docker-compose down --volumes
docker-compose up -d --build

# Step 4: Verify MQTT port
echo "[*] Verifying MQTT broker port..."
docker exec -it mqtt-broker netstat -tuln | grep 1883 && echo "[✓] MQTT is listening on 0.0.0.0:1883"

# Step 5: Start Wireshark (if installed)
echo "[*] Launching Wireshark to monitor MQTT traffic..."
if command -v wireshark >/dev/null 2>&1; then
    sudo wireshark -k -i "$INTERFACE" -f "tcp port 1883" &
    echo "[✓] Wireshark launched on $INTERFACE (filter: tcp port 1883)"
else
    echo "[!] Wireshark not found. Falling back to tcpdump."
    sudo tcpdump -i "$INTERFACE" port 1883 -nn -vvv
fi

echo "[✅] Setup complete. Run MQTT test to see traffic captured live."




