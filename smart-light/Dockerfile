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
RUN apt update && apt install -y iputils-ping netcat-openbsd curl

# Install Python dependencies
RUN pip install -r requirements.txt

CMD ["python3", "app.py"]

