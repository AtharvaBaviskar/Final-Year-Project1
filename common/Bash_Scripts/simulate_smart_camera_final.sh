#!/bin/bash

echo "[+] Stopping and removing old containers..."
sudo docker compose down
sudo docker system prune -f

echo "[+] Starting MQTT broker, RTSP server, and Flask API..."
sudo docker compose up -d --build

echo "[+] Waiting for containers to initialize..."
sleep 10

# Test Flask API endpoints
echo "[+] Testing Flask REST API endpoints..."
echo ">>> POST /login"
curl -s -X POST http://localhost:1887/login -d "username=admin&password=admin"
echo -e "\n\n>>> GET /status"
curl -s http://localhost:1887/status
echo -e "\n\n>>> GET /snapshot"
curl -s http://localhost:1887/snapshot
echo ""

# RTSP server validation
echo "[*] Checking for port 8554 conflicts and RTSP container issues..."
RTSP_CONTAINER=$(sudo docker ps -a --filter "name=rtsp_server_osi" --format "{{.ID}}")
if [[ -z "$RTSP_CONTAINER" ]]; then
  echo "[!] RTSP container not found. Starting manually..."
  sudo docker compose up -d rtsp-server
else
  RUNNING=$(sudo docker inspect -f '{{.State.Running}}' "$RTSP_CONTAINER")
  if [[ "$RUNNING" != "true" ]]; then
    echo "[!] RTSP container is not running. Attempting to restart..."
    sudo docker start "$RTSP_CONTAINER"
  fi
fi

# Free port 8554 if it's blocked
PORT_8554_PID=$(sudo lsof -t -i:8554)
if [[ ! -z "$PORT_8554_PID" ]]; then
  echo "[!] Port 8554 is in use. Attempting to free it..."
  sudo kill -9 $PORT_8554_PID
  echo "[✓] Freed port 8554."
fi

# Confirm port is open
echo "[*] Rechecking Docker container bindings..."
sudo docker ps | grep 8554 && echo "[✓] RTSP validation check complete."

# Capture UDP traffic on port 8554
echo "[+] Capturing network stats (UDP port 8554)..."
sudo timeout 15 tcpdump -i any port 8554 -w rtsp_traffic.pcap &

# Start RTSP stream via FFmpeg
echo "[+] Simulating RTSP stream via ffmpeg (TCP)..."
until ffmpeg -re -stream_loop -1 -i cctv.mp4 -an -vcodec libx264 -f rtsp -rtsp_transport tcp rtsp://localhost:8554/live; do
  echo "[!] FFmpeg stream failed (broken pipe or transport error). Retrying in 5s..."
  sleep 5
done
