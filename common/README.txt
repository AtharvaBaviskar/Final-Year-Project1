# Smart Camera OSI Simulation (Full - with MQTT and REST)

## Simulated Layers:
- Layer 2–3: Docker networks for MAC/IP routing
- Layer 4: UDP via ffmpeg
- Layer 5: RTSP sessions
- Layer 6: H.264 encoding
- Layer 7: Flask REST API + MQTT integration

## Endpoints:
- POST /login (admin/admin)
- GET /snapshot
- GET /status
- MQTT Topic: camera/stream → send "on" or "off"

## Usage:
1. Place your real `cctv.mp4` in the folder.
2. Run:
   ```bash
   ./simulate_smart_camera.sh
   ```

3. Use `tcpdump` or Wireshark to observe:
   ```bash
   sudo tcpdump -i any udp port 8554
   ```
