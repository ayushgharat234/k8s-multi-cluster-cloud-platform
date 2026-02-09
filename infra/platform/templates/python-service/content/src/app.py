from fastapi import FastAPI
from pydantic import BaseModel
from prometheus_client import make_wsgi_app
from werkzeug.middleware.dispatcher import DispatcherMiddleware

app = FastAPI()

class HealthCheck(BaseModel):
    status: str = "ok"
    version: str = "1.0.0"

@app.get("/health")
def health_check() -> HealthCheck:
    return HealthCheck(status="ok")

@app.get("/")
def read_root():
    return {"message": "Hello from ${{ values.name }}!"}
# Export Prometheus metrics on /metrics
app_dispatch = DispatcherMiddleware(app, {
    '/metrics': make_wsgi_app()
})