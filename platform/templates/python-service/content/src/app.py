from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route('/')
def hello():
    return jsonify({
        "message": "Hello from ${{ values.name }}!",
        "status": "Running",
        "version": "1.0.0"
    })

@app.route('/health') # Keep for backward compatibility
@app.route('/healthz')
def health():
    return jsonify({"status": "alive"})

@app.route('/ready')
def ready():
    return jsonify({"status": "ready"})

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port)