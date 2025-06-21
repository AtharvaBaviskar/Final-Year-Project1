from flask import Flask, request, jsonify, send_file
import paho.mqtt.client as mqtt
import threading
import time
import sqlite3
import os

app = Flask(__name__)
status = {"streaming": False}

# === PATH SETUP ===
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PCAP_DIR = os.path.join(BASE_DIR, "pcap_logs")
SIM_LOG_DIR = os.path.join(BASE_DIR, "simulation logs")

# MQTT setup
broker = "mqtt-broker"
port = 1883
topic = "camera/stream"
topics = ["camera/stream", "smart/camera/motion"]
client = mqtt.Client()

def on_connect(client, userdata, flags, rc):
    print(f"[MQTT] on_connect called with rc={rc}")
    if rc == 0:
        print("[MQTT] Connected successfully")
        for t in topics:
            print(f"[MQTT] Subscribing to topic: {t}")
            client.subscribe(t)
    else:
        print(f"[MQTT] Failed to connect, return code {rc}")

def on_message(client, userdata, msg):
    payload = msg.payload.decode()
    print(f"[MQTT] Received on {msg.topic}: {payload}")
    
    # Motion alert spoof test
    if msg.topic == "smart/camera/motion":
        motion_log_path = os.path.join(SIM_LOG_DIR, "simulation_log.txt")
        print(f"[DEBUG] Attempting to write to: {motion_log_path}")
        with open(motion_log_path, "a") as f:
            f.write(f"[ALERT] Fake motion received: {payload}\n")
        print(f"[LOGGED] Motion event saved to simulation_log.txt")

    # Stream control logic
    if msg.topic == "camera/stream":
        if payload == "on":
            status["streaming"] = True
        elif payload == "off":
            status["streaming"] = False

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
            client.loop_start()  # ✅ non-blocking loop
            break               # 🔧 exit loop after successful connection
        except Exception as e:
            print(f"[MQTT] Waiting for broker... {e}")
            time.sleep(2)

# Setup in-memory SQLite DB
def init_db():
    conn = sqlite3.connect(':memory:', check_same_thread=False)
    c = conn.cursor()
    c.execute('CREATE TABLE users (username TEXT, password TEXT)')
    c.execute("INSERT INTO users VALUES ('admin', 'admin')")
    c.execute("INSERT INTO users VALUES ('user', '1234')")
    conn.commit()
    return conn

conn = init_db()

@app.route("/login", methods=["POST"])
def login():
    data = request.get_json()
    username = data.get("username")
    password = data.get("password")
    # Intentionally vulnerable SQL query
    query = f"SELECT * FROM users WHERE username = '{username}' AND password = '{password}'"
    print("[DEBUG] SQL Query:", query)
    cursor = conn.cursor()
    cursor.execute(query)
    result = cursor.fetchone()
    if result:
        return jsonify({"message": "Login successful"}), 200
    return jsonify({"message": "Invalid credentials"}), 401

@app.route("/snapshot")
def snapshot():
    return jsonify({"snapshot": "http://camera.local/fake.jpg"})

@app.route("/status")
def get_status():
    return jsonify(status)

# 🔥 Vulnerable Directory Traversal Endpoint
@app.route("/download", methods=["GET"])
def download_file():
    filename = request.args.get("file")
    if not filename:
        return "Missing 'file' parameter", 400
    try:
        # ⚠️ No sanitization — intentionally vulnerable
        full_path = os.path.join(BASE_DIR, filename)
        return send_file(full_path)
    except Exception as e:
        return f"Error reading file: {str(e)}", 404
        
@app.route("/stream/start", methods=["POST"])
def start_stream():
    try:
        result = client.publish("camera/control", "start")
        if result.rc != mqtt.MQTT_ERR_SUCCESS:
            return jsonify({"error": "Failed to publish MQTT message"}), 500
        return jsonify({"message": "Stream start command sent"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500  

@app.route("/stream/stop", methods=["POST"])
def stop_stream():
    try:
        client.publish("camera/control", "stop")
        return jsonify({"message": "Stream stop command sent"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# --- Start MQTT regardless of environment ---
threading.Thread(target=mqtt_thread, daemon=True).start()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=1887)



