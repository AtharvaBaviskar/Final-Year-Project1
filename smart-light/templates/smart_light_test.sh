#!/bin/bash

# === CONFIGURATION ===
BROKER_IP="127.0.0.1"        # Use 127.0.0.1 if running from host, or 192.168.250.14 if from inside container
BROKER_PORT="1886"           # Use 1886 if you're outside the container (host machine)
SMART_LIGHT_IP="192.168.250.11"
FLASK_PORT="1881"
LOGFILE="smart_light_test_$(date '+%Y%m%d_%H%M%S').log"

echo "=== SMART LIGHT IoT TEST ===" | tee -a "$LOGFILE"
echo "Test started at $(date)" | tee -a "$LOGFILE"

# === SEND MQTT MESSAGES ===
echo -e "\n[STEP 1] Sending MQTT: Power ON" | tee -a "$LOGFILE"
mosquitto_pub -h "$BROKER_IP" -p "$BROKER_PORT" -t "light/control" -m "power:on" 2>&1 | tee -a "$LOGFILE"
sleep 1

echo -e "\n[STEP 2] Sending MQTT: Brightness 75" | tee -a "$LOGFILE"
mosquitto_pub -h "$BROKER_IP" -p "$BROKER_PORT" -t "light/control" -m "brightness:75" 2>&1 | tee -a "$LOGFILE"
sleep 1

echo -e "\n[STEP 3] Sending MQTT: Color 0,255,100 (Greenish)" | tee -a "$LOGFILE"
mosquitto_pub -h "$BROKER_IP" -p "$BROKER_PORT" -t "light/control" -m "color:0,255,100" 2>&1 | tee -a "$LOGFILE"
sleep 1

# === GET STATUS FROM FLASK ===
echo -e "\n[STEP 4] Verifying via /status endpoint" | tee -a "$LOGFILE"
curl -s "http://${SMART_LIGHT_IP}:${FLASK_PORT}/status" | tee -a "$LOGFILE"

echo -e "\n[TEST COMPLETE] Log saved to $LOGFILE"
