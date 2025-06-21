#!/bin/bash

echo "[*] Stopping existing containers..."
docker-compose down

echo "[*] Cleaning up exited or dangling containers..."
docker rm -f $(docker ps -aq --filter "status=exited") 2>/dev/null

echo "[*] Rewriting entrypoint.sh to fix RTSP streaming..."
cat <<EOF > ../smart-camera/entrypoint.sh
#!/bin/bash
echo "[+] Starting SSH service"
/etc/init.d/ssh start

echo "[+] Launching Flask API"
python3 app.py &

echo "[+] Starting RTSP stream from cctv.mp4"
ffmpeg -re -stream_loop -1 -i /app/cctv.mp4 -an -c:v libx264 -f rtsp rtsp://rtsp-server:8554/live > /app/ffmpeg.log 2>&1
EOF

chmod +x ../smart-camera/entrypoint.sh

echo "[*] Fixing mediamtx.yml to accept published streams on /live..."
cat <<EOF > ../common/mediamtx.yml
rtspAddress: :8554
rtspTransports: [udp, tcp]

paths:
  live:
    source: publisher
    sourceOnDemand: no
EOF

echo "[*] Rebuilding smart_camera image..."
docker-compose build smart-camera

echo "[*] Restarting all containers..."
docker-compose up -d --remove-orphans

echo "[*] Showing container status..."
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo "[*] Waiting 10 seconds for RTSP stream to initialize..."
sleep 10

echo "[*] Last 40 lines of ffmpeg.log from smart_camera_api:"
docker exec -it smart_camera_api tail -n 40 /app/ffmpeg.log

