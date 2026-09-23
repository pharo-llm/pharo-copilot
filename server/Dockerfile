FROM python:3.13-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY gateway.py .
USER 10001:10001
CMD ["uvicorn", "gateway:app", "--host", "0.0.0.0", "--port", "8080", "--workers", "1", "--no-access-log", "--limit-concurrency", "64", "--timeout-keep-alive", "5"]
