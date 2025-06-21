#FROM python:3.10-slim
#WORKDIR /app
#COPY requirements.txt .
#RUN pip install -r requirements.txt
#COPY app/app.py app.py
#CMD ["python3", "app.py"]

FROM python:3.10-slim

# Existing setup...
WORKDIR /app
COPY . /app

# ✅ Add tools for network testing
RUN sed -i 's|http://deb.debian.org|http://deb.debian.net|g' /etc/apt/sources.list && \
    apt update && apt install -y --no-install-recommends \
    iputils-ping netcat-openbsd curl ffmpeg openssh-server && \
    apt clean && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip install -r requirements.txt

CMD ["python3", "app.py"]


