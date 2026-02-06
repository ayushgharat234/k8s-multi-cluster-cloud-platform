# Stage 1: Build
FROM dhi.io/python:3-debian13-sfw-ent-dev as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt
# Stage 2: Runtime
FROM dhi.io/python:3-debian13-sfw-ent-dev
WORKDIR /app
# Copy installed packages from builder
COPY --from=builder /root/.local /root/.local
ENV PATH=/root/.local/bin:$PATH
COPY . .
# Security: Run as non-root user (provided by the hardened image or default user)
USER 1001
EXPOSE 8080
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]