FROM python:3.13-slim-bookworm
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8080
USER nobody
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "main:app"]
