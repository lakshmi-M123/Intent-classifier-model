
# Use a slim official Python image
FROM python:3.10-slim

# Prevent Python from writing .pyc files and enable stdout/stderr flushing
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# 1) Install CA bundle and refresh the trust store
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 2) Upgrade pip tooling (gets fresh certifi as well)
RUN python -m pip install --upgrade pip setuptools wheel

# 3) Install Python deps
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy app code and model file(s)
COPY . .

# Train the Model (consider caching or moving to runtime/CI if long)
RUN python3 model/train.py

# Expose the port your app runs on
EXPOSE 6000

# Start the app with gunicorn (4 workers, bind to 0.0.0.0:6000)
CMD ["gunicorn", "--workers", "4", "--bind", "0.0.0.0:6000", "app:app"]