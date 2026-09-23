FROM python:3.11-slim
WORKDIR /app
RUN pip install fastapi uvicorn asyncpg python-jose aiohttp PyJWT --no-cache-dir
COPY main.py .
RUN useradd -m -u 1001 sentinel && chown -R sentinel:sentinel /app
USER sentinel
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2", "--proxy-headers"]
HEALTHCHECK --interval=20s --timeout=5s CMD curl -f http://localhost:8000/health || exit 1
