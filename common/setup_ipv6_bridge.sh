#!/bin/bash
set -e

echo "[*] Removing existing Docker network 'iot_net' if it exists..."
sudo docker network rm iot_net 2>/dev/null || true

echo "[*] Creating custom Docker bridge network 'iot_net' with IPv4 and IPv6 support..."
sudo docker network create   --driver bridge   --subnet 192.168.250.0/24   --gateway 192.168.250.1   --ip-range 192.168.250.0/24   --ipv6   --subnet fd00:dead:beef::/64   --gateway fd00:dead:beef::1   iot_net

echo "[✓] IPv4 and IPv6 Docker network 'iot_net' created successfully."
