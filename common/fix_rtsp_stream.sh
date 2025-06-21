#!/bin/bash
set -e

echo -e "\n==== ✅ RTSP STREAM FINAL DEBUGGER ====\n"

echo "[1] Ensuring video exists on host..."
HOST_FILE="/home/user/Documents/Final Year Project/iot_devices/smart-camera/cctv.mp4"
if [ ! -f "$HOST_FILE" ]; then
  echo "❌ File not found on host: $HOST_FILE"
  exit 1
fi
echo "✔️ Found: $HOST_FILE"

echo "[2] Validating mediamtx.yml config..."
grep -q 'source: /app/cctv.mp4' ../common/mediamtx.yml || {
  echo "❌ Wrong path in mediamtx.yml!"
  exit 1
}

echo "[3] Rebuilding rtsp_server_osi container..."
docker-compose stop rtsp-server || true
docker-compose rm -f rtsp-server || true
docker-compose up -d rtsp-server

echo "[4] Waiting for container to become healthy..."
sleep 4
RETRY=5
until docker exec rtsp_server_osi ls /app/cctv.mp4 &>/dev/null || [ $RETRY -eq 0 ]; do
  echo "⏳ Waiting for container to stabilize... ($RETRY left)"
  sleep 3
  RETRY=$((RETRY - 1))
done

if [ $RETRY -eq 0 ]; then
  echo "❌ Container is still crashing. Check logs:"
  docker logs rtsp_server_osi | tail -n 50
  exit 1
fi

echo "✔️ Container stable and /app/cctv.mp4 found!"
docker logs rtsp_server_osi | tail -n 10

