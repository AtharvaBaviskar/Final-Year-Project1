echo "=== ✅ VERIFYING RTSP STREAM SETUP ==="

# Configuration
CONTAINER_NAME="rtsp_server_osi"
VIDEO_PATH_ON_HOST="./smart-camera/cctv.mp4"
VIDEO_PATH_IN_CONTAINER="/app/cctv.mp4"
MEDIAMTX_CONFIG_PATH="./common/mediamtx.yml"
RTSP_PORT=8554

# 1. Check if file exists on host
echo -n "[1] Checking if video file exists on host... "
[[ -f "$VIDEO_PATH_ON_HOST" ]] && echo "✅ Found" || { echo "❌ Missing: $VIDEO_PATH_ON_HOST"; exit 1; }

# 2. Check if container is running
echo -n "[2] Checking if container '$CONTAINER_NAME' is running... "
docker ps --format '{{.Names}}' | grep -q "$CONTAINER_NAME" && echo "✅ Running" || { echo "❌ Not running"; exit 1; }

# 3. Check if file exists in container
echo "[3] Checking if file is present inside container..."
docker exec "$CONTAINER_NAME" ls "$VIDEO_PATH_IN_CONTAINER" &>/dev/null \
  && echo "✅ File is accessible inside container" \
  || { echo "❌ File NOT found at $VIDEO_PATH_IN_CONTAINER inside $CONTAINER_NAME"; exit 1; }

# 4. Check if mediamtx.yml points to this file
echo -n "[4] Verifying mediamtx.yml source path... "
grep -q "file://$VIDEO_PATH_IN_CONTAINER" "$MEDIAMTX_CONFIG_PATH" \
  && echo "✅ Path correctly configured" \
  || { echo "❌ Wrong or missing source path in mediamtx.yml"; exit 1; }

# 5. Check RTSP port is exposed
echo -n "[5] Checking if RTSP port $RTSP_PORT is listening... "
ss -tuln | grep -q ":$RTSP_PORT" && echo "✅ Listening" || echo "⚠️ Not visible on host (but might still work inside Docker)"

# 6. Print last 10 logs
echo -e "\n[6] 📜 Last 10 log lines from $CONTAINER_NAME:"
docker logs "$CONTAINER_NAME" --tail 10

echo -e "\n=== 🧪 BASIC VERIFICATION DONE ==="
echo "If all ✅ passed, now try:\n  ffmpeg -i rtsp://192.168.250.15:8554/live -f null -"

