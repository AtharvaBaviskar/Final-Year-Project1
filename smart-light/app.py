from flask import Flask, request, jsonify, send_file
import paho.mqtt.client as mqtt
import threading
import time
import sqlite3
import os
import jwt
import datetime
import logging  # 🔧 Added for logging

app = Flask(__name__)

# === SMART LIGHT: PHYSICAL LAYER STATE ===
smart_light = {
    "power": False,
    "brightness": 0,
    "color_rgb": (255, 255, 255)
}

# === PATH SETUP ===
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PCAP_DIR = os.path.join(BASE_DIR, "pcap_logs")
SIM_LOG_DIR = os.path.join(BASE_DIR, "simulation logs")
LOG_DIR = os.path.join(BASE_DIR, "logs")  # 🔧
os.makedirs(LOG_DIR, exist_ok=True)       # 🔧
LOG_FILE = os.path.join(LOG_DIR, "app.log")

#  Logging setup
logging.basicConfig(
    filename=LOG_FILE,
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)

# === MQTT CONFIG ===
broker = "mqtt-broker"
port = 1883
topic = "light/control"
client = mqtt.Client()

def on_connect(client, userdata, flags, rc):
    client.subscribe(topic)

def on_message(client, userdata, msg):
    payload = msg.payload.decode()
    print(f"[MQTT] Received: {payload}")
    try:
        parts = payload.split(":")
        cmd = parts[0]
        if cmd == "power":
            smart_light["power"] = parts[1].lower() == "on"
        elif cmd == "brightness":
            smart_light["brightness"] = int(parts[1])
        elif cmd == "color":
            r, g, b = map(int, parts[1].split(","))
            smart_light["color_rgb"] = (r, g, b)
    except Exception as e:
        print(f"[MQTT] Error parsing command: {e}")

def mqtt_thread():
    client.on_connect = on_connect
    client.on_message = on_message
    connected = False
    while not connected:
        try:
            print(f"[MQTT] Connecting to broker at {broker}:{port} ...")
            client.connect(broker, port, 60)
            connected = True
            print("[MQTT] Connected!")
            client.loop_start()
        except Exception as e:
            print(f"[MQTT] Waiting for broker... {e}")
            time.sleep(2)

# === DATABASE SETUP ===
def init_db():
    conn = sqlite3.connect(':memory:', check_same_thread=False)
    c = conn.cursor()
    c.execute('CREATE TABLE users (username TEXT, password TEXT)')
    c.execute("INSERT INTO users VALUES ('admin', 'admin')")
    c.execute("INSERT INTO users VALUES ('user', '1234')")
    conn.commit()
    return conn

conn = init_db()

# === JWT CONFIG ===
SECRET_KEY = "light123"  # weak key for brute-force test
ALGORITHM = "HS256"

# === FLASK ROUTES ===

@app.route("/login", methods=["POST"])
def login():
    data = request.get_json()
    username = data.get("username")
    password = data.get("password")

    # Intentionally vulnerable SQL (for injection testing)
    query = f"SELECT * FROM users WHERE username = '{username}' AND password = '{password}'"
    print("[DEBUG] SQL Query:", query)
    cursor = conn.cursor()
    cursor.execute(query)
    result = cursor.fetchone()

    if result:
        role = "admin" if username == "admin" else "user"
        payload = {
            "username": username,
            "role": role,
            "exp": datetime.datetime.utcnow() + datetime.timedelta(minutes=10)
        }
        token = jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)
        logging.info(f"User {username} logged in")  # 🔧
        return jsonify({"token": token}), 200
    return jsonify({"message": "Invalid credentials"}), 401

@app.route("/admin", methods=["GET"])
def admin_panel():
    auth_header = request.headers.get("Authorization", "")
    if not auth_header.startswith("Bearer "):
        return jsonify({"error": "Token missing"}), 401

    token = auth_header.split(" ")[1]
    try:
        decoded = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        if decoded.get("role") == "admin":
            return jsonify({"message": "Welcome, admin! Light control granted."})
        else:
            return jsonify({"message": "Access denied. Admins only."}), 403
    except jwt.ExpiredSignatureError:
        return jsonify({"error": "Token expired"}), 403
    except jwt.InvalidTokenError:
        return jsonify({"error": "Invalid token"}), 403

@app.route("/status")
def status():
    return jsonify(smart_light)

@app.route("/control", methods=["POST"])
def control_light():
    data = request.get_json()
    if 'power' in data:
        smart_light["power"] = data["power"]
        logging.info(f"Smart light turned {'ON' if data['power'] else 'OFF'}")  # 🔧
    if 'brightness' in data:
        smart_light["brightness"] = data["brightness"]
        logging.info(f"Brightness set to {data['brightness']}%")  # 🔧
    if 'color_rgb' in data:
        smart_light["color_rgb"] = tuple(data["color_rgb"])
        logging.info(f"Color set to RGB{smart_light['color_rgb']}")  # 🔧
    return jsonify({"message": "Light updated", "new_state": smart_light})

@app.route("/download", methods=["GET"])
def download_file():
    filename = request.args.get("file")
    if not filename:
        return "Missing 'file' parameter", 400
    try:
        full_path = os.path.join(BASE_DIR, filename)
        return send_file(full_path)
    except Exception as e:
        return f"Error reading file: {str(e)}", 404

# === START MQTT THREAD ===
threading.Thread(target=mqtt_thread, daemon=True).start()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=1881)

