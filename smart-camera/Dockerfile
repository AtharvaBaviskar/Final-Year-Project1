FROM python:3.10-slim

# Set working directory
WORKDIR /app

# Copy all files into container
COPY . /app

# Install network tools, SSH server, and FFmpeg for RTSP streaming
RUN apt update && apt install -y \
    iputils-ping netcat-openbsd curl ffmpeg openssh-server && \
    apt clean && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip install -r requirements.txt

# Make sure entrypoint is executable
RUN chmod +x /app/entrypoint.sh

# Expose Flask (1882), MQTT (if needed), and optional RTSP (8554)
EXPOSE 1882 8554 22

# Entrypoint will handle launching Flask and FFmpeg
ENTRYPOINT ["/app/entrypoint.sh"]

