# Build Stage
FROM python:3.11-slim AS builder
WORKDIR /app

COPY requirements.txt .
# Install dependencies to a temporary location
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Final Stage (Distroless)
# Contains minimal Python runtime, no shell, no package manager
FROM gcr.io/distroless/python3-debian12
WORKDIR /app

# Copy installed python packages
COPY --from=builder /install /usr/local
# Copy application code
COPY src/ /app

# Distroless runs as non-root by default (usually), but let's be explicit
USER 65532:65532

# Python buffers stdout, which delays logs in K8s. This fixes it.
ENV PYTHONUNBUFFERED=1

EXPOSE 5000
ENTRYPOINT ["python3", "app.py"]