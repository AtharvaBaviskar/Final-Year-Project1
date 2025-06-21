#!/bin/bash

echo "[*] Stopping old containers..."
sudo docker stop rtsp_server_osi smart_camera_api mqtt-broker 2>/dev/null
sudo docker rm rtsp_server_osi smart_camera_api mqtt-broker 2>/dev/null

echo "[*] Starting RTSP Server (MediaMTX)..."
if ! sudo docker ps | grep -q rtsp_server_osi; then
    sudo docker run -d \
        -p 8554:8554 \
        -p 8888:8888 \
        -v "$PWD/mediamtx.yml:/mediamtx.yml" \
        --name rtsp_server_osi \
        bluenviron/mediamtx
    sleep 5
fi

echo "[*] Starting MQTT broker..."
sudo docker run -d --name mqtt-broker -p 1883:1883 eclipse-mosquitto

echo "[*] Starting Flask Smart Camera API..."
sudo docker build -t smart_camera_image .
sudo docker run -d --name smart_camera_api --network host smart_camera_image

# Create log directory
mkdir -p logs

echo "[*] Starting RTSP stream simulation..."
ffmpeg -re -stream_loop -1 -i cctv.mp4 -an -vcodec libx264 -f rtsp -rtsp_transport tcp rtsp://localhost:8554/live &> logs/ffmpeg_stream.log &

sleep 5

echo "[*] Capturing traffic on port 8554..."
sudo tcpdump -i any port 8554 -w logs/rtsp_traffic.pcap &
TCPDUMP_PID=$!

sleep 10

echo "[*] Testing Flask API endpoints..."
curl -X POST http://localhost:1887/login -d 'username=admin&password=admin' -o logs/login_response.txt
curl http://localhost:1887/status -o logs/status_response.txt

echo "[*] Smart Camera Simulation Running."
echo "[✓] Press Ctrl+C to stop streaming and traffic capture."

wait $TCPDUMP_PID

