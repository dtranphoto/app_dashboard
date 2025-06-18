from flask import Flask, jsonify, request
from flask_cors import CORS
import random, json, os
from datetime import datetime, timedelta

app = Flask(__name__)
CORS(app)

def load_services_from_file(company):
    file_path = f"services/services_{company}.json"
    print(f"🔍 Loading: {file_path}")  # <-- Add this
    if not os.path.exists(file_path):
        return []
    with open(file_path) as f:
        return json.load(f)

def generate_mock_data(company):
    raw_services = load_services_from_file(company)
    enriched = []
    for svc in raw_services:
        enriched.append({
            "id": svc["id"],
            "region": svc["region"],
            "status": random.choice(["Healthy", "Degraded", "Down"]),
            "latency_ms": random.randint(80, 350),
            "uptime_percent": round(random.uniform(95.0, 99.99), 2),
            "throughput_rps": round(random.uniform(100, 500), 1),
            "error_rate": round(random.uniform(0, 5), 2),
            "instances": random.randint(1, 10),
            "restarts": random.randint(0, 5),
            "last_deploy": (datetime.utcnow() - timedelta(hours=random.randint(1, 48))).strftime("%Y-%m-%d %H:%M"),
            "team_owner": random.choice(["Infra", "Data", "Backend", "Frontend"]),
            "version": random.choice(["v1.0.0", "v1.4.2", "v2.0.0", "v3.1.1"]),
        })
    return enriched

@app.route("/services.json")
def services():
    company = request.args.get("company", "nintendo").lower()
    data = generate_mock_data(company)
    return jsonify(data)

@app.route("/health")
def health():
    return "OK", 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001, debug=True)
