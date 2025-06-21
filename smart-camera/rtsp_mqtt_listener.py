import paho.mqtt.client as mqtt
import subprocess
import signal
import time

broker = "mqtt-broker"
port = 1883
topic = "camera/control"
stream_process = None

def on_connect(client, userdata, flags, rc):
    print("Connected to MQTT Broker")
    client.subscribe(topic)

def on_message(client, userdata, msg):
    global stream_process
    payload = msg.payload.decode()
    print(f"[MQTT] Received: {payload}")

    if payload == "start" and stream_process is None:
        print("▶️ Starting RTSP Stream...")
        stream_process = subprocess.Popen([
            "ffmpeg", "-re", "-stream_loop", "-1",
            "-i", "smart-camera/cctv.mp4",  # Adjust path if needed
            "-rtsp_transport", "tcp", "-c", "copy", "-f", "rtsp",
            "rtsp://rtsp_server_osi:8554/live"
        ])
    elif payload == "stop" and stream_process:
        print("⏹️ Stopping RTSP Stream...")
        stream_process.send_signal(signal.SIGINT)
        stream_process = None

client = mqtt.Client()
client.on_connect = on_connect
client.on_message = on_message

client.connect(broker, port, 60)
client.loop_forever()
