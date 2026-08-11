# Deployed via GitHub Actions CI/CD
from flask import Flask, jsonify
import socket;
import datetime;

app = Flask(__name__);

@app.route('/')
def home():
  return jsonify({
    "message": "Resilient Deploy is alive",
    "hostname": socket.gethostname(),
    "timestamp": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
  })

@app.route("/health")
def health():
  return jsonify({
    "status": "healthy"
  }), 200

if __name__ == '__main__':
  app.run(host="0.0.0.0", port=8080);
