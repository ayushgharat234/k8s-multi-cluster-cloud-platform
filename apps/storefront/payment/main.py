from flask import Flask, jsonify
from google.cloud import secretmanager
import os

app = Flask(__name__)

def get_secret(secret_id):
    client = secretmanager.SecretManagerServiceClient()
    project_id = os.getenv("GOOGLE_CLOUD_PROJECT")
    name = f"projects/{project_id}/secrets/{secret_id}/versions/latest"
    
    try:
        response = client.access_secret_version(request={"name": name})
        return response.payload.data.decode("UTF-8")
    except Exception as e:
        return f"Error: {str(e)}"

@app.route('/health')
def health():
    return jsonify({"status": "healthy", "cloud": "GCP"})

@app.route('/payment/config')
def get_config():
    # Demonstrating Secret Manager access via Workload Identity
    api_key = get_secret("payment-api-key")
    return jsonify({
        "service": "payment-service",
        "identity_verified": True,
        "api_key_snip": f"{api_key[:4]}****" 
    })

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8080)
