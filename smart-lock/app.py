from flask import Flask, request, jsonify
import paho.mqtt.client as mqtt
import threading
import time
import os

app = Flask(__name__)

# === SMART LOCK: PHYSICAL LAYER STATE ===
smart_lock = {
    "locked": True,            # True = Locked, False = Unlocked
    "pin_input": "1234",       # Hardcoded PIN
    "battery_level": 87        # Simulated battery percentage
}

# === PATH SETUP (OPTIONAL FOR PCAP/SIM LOGS) ===
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PCAP_DIR = os.path.join(BASE_DIR, "pcap_logs")
SIM_LOG_DIR = os.path.join(BASE_DIR, "simulation logs")

# === MQTT CONFIG ===
broker = "mqtt-broker"
port = 1883
topic = "lock/control"
client = mqtt.Client()

def on_connect(client, userdata, flags, rc):
    print("[MQTT] Connected with result code " + str(rc))
    client.subscribe(topic)

def on_message(client, userdata, msg):
    payload = msg.payload.decode()
    print(f"[MQTT] Received: {payload}")

    try:
        if payload == "lock":
            smart_lock["locked"] = True
        elif payload == "unlock":
            smart_lock["locked"] = False
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

# === FLASK ROUTES (BASIC STATUS) ==
app.secret_key = 'abc123'  # Required for using sessions

@app.route("/login", methods=["POST"])
def login():
    data = request.get_json()
    username = data.get("username")
    password = data.get("password")

    if username == 'hacker' and password == 'letmein':
        session['user'] = 'admin'
        return jsonify({"message": "Backdoor access granted"}), 200
    else:
        return jsonify({"message": "Access denied"}), 403

@app.route("/status")
def status():
    return jsonify({
        "lock_state": "Locked" if smart_lock["locked"] else "Unlocked",
        "battery": f"{smart_lock['battery_level']}%",
        "simulated_pin": smart_lock["pin_input"]  # Vulnerable disclosure
    })

# === START MQTT CLIENT THREAD ===
threading.Thread(target=mqtt_thread, daemon=True).start()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=1882)
