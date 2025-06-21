#!/bin/bash

echo "[+] Starting SSH service"
/etc/init.d/ssh start

echo "[+] Launching Flask API"
python3 app.py &

echo "[+] Starting RTSP stream from cctv.mp4"

# ✅ FIXED FFMPEG COMMAND (no audio, pure video, raw RTSP)
echo "[+] Starting RTSP stream from cctv.mp4"
ffmpeg -re -stream_loop -1 -i /app/cctv.mp4 -an -c:v libx264 -f rtsp rtsp://rtsp-server:8554/live > /app/ffmpeg.log 2>&1 &
  
# 🛡 Keep container alive
tail -f /dev/null


