# syntax=docker/dockerfile:1.6
# Build context is the `backend/` directory (set via Render's "Root Directory").
FROM python:3.11-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PORT=8000

# ---- OS deps for pyodbc (MS ODBC Driver 18 for SQL Server) ----
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl gnupg2 ca-certificates \
        unixodbc unixodbc-dev \
        gcc g++ \
    && curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
        | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/debian/12/prod bookworm main" \
        > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y --no-install-recommends msodbcsql18 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# ---- Python deps (cache layer) ----
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# ---- App code ----
COPY . .

# ---- Non-root user (Render security recommendation) ----
RUN useradd --create-home --uid 1000 appuser \
    && chown -R appuser:appuser /app
USER appuser

# ---- Health check ----
# Render will hit /health on this path to know the service is live.
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD curl -fsS http://127.0.0.1:${PORT}/health || exit 1

EXPOSE 8000

# Production-ish: 1 worker is fine for the free/starter tier; bump later.
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT} --proxy-headers --forwarded-allow-ips='*'"]
