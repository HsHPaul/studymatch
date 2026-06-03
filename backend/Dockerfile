# Container-Image für das StudyMatch-Backend (FastAPI).
# Wird von Render aus diesem Dockerfile gebaut; der Port kommt zur Laufzeit aus $PORT.
FROM python:3.11-slim

WORKDIR /app

# Abhängigkeiten zuerst kopieren – besseres Layer-Caching bei Code-Änderungen.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Anwendungscode
COPY . .

# Render gibt den Port über $PORT vor. Die Migration ist idempotent
# (no-op, wenn die DB bereits auf head ist). Single-Worker ist Absicht:
# passt zum Free-Tier-RAM und zum WebSocket-Chat (kein Shared State nötig).
# exec ersetzt die Shell durch uvicorn → uvicorn wird PID 1 und fährt bei
# SIGTERM (Render-Spin-down) sauber herunter.
CMD ["sh", "-c", "alembic upgrade head && exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
