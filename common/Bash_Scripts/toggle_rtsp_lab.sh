#!/bin/bash

# === Container Names ===
RTSP_CONTAINER=rtsp_server_osi
MQTT_CONTAINER=mqtt-broker
API_CONTAINER=smart_camera_api

# === RTSP Project Directory ===
RTSP_DIR="$HOME/Documents/Final Year Master's Project/smart_camera_osi_final_auto_fix (2)"

# === Function to Start Simulation After Containers Are Ready ===
start_simulation() {
    echo "[*] Starting RTSP Video Stream using FFmpeg..."
    ffmpeg -re -stream_loop -1 -i cctv.mp4 -rtsp_transport tcp -c copy -f rtsp rtsp://192.168.56.8:8554/live & 
    FFMPEG_PID=$!

    sleep 5

    echo "[*] Subscribing to MQTT topics..."
    mosquitto_sub -h 192.168.250.14 -p 1883 -t "#" -v &
    MQTT_PID=$!

    sleep 3

    echo "[*] Performing Smart Camera API Check..."
    curl -s http://192.168.251.15:8888/status

    echo "[*] Launching Wireshark..."
    wireshark -k -i br-5b305e700f84 -f 'tcp port 8554 or tcp port 1883 or tcp port 8888' &
    WIRESHARK_PID=$!

    echo "[*] Running for 60 seconds to simulate interaction..."
    sleep 60

    echo "[*] Cleaning up..."
    kill $FFMPEG_PID $MQTT_PID $WIRESHARK_PID 2>/dev/null

    echo "[✔] Simulation Completed. Traffic was captured by Wireshark."
}

# === Main Execution ===
is_running=$(docker ps --filter "name=$RTSP_CONTAINER" --filter "status=running" -q)

if [ -n "$is_running" ]; then
    echo "[⛔] Containers are already running. Stopping and removing..."
    docker stop $RTSP_CONTAINER $MQTT_CONTAINER $API_CONTAINER 2>/dev/null
    docker rm $RTSP_CONTAINER $MQTT_CONTAINER $API_CONTAINER 2>/dev/null
    echo "[✅] All RTSP lab containers stopped and removed."

    echo "[🔄] Restarting full RTSP lab..."
    cd "$RTSP_DIR" || { echo "[❌] Could not access directory: $RTSP_DIR"; exit 1; }
    docker-compose up -d
    echo "[✅] Containers started. Beginning simulation..."
    start_simulation
else
    echo "[🔄] Containers are not running. Starting full RTSP lab..."
    cd "$RTSP_DIR" || { echo "[❌] Could not access directory: $RTSP_DIR"; exit 1; }
    docker-compose up -d
    echo "[✅] Containers started. Beginning simulation..."
    start_simulation
fi

