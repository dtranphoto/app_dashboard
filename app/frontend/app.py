from flask import Flask, request, redirect, render_template_string, send_from_directory, jsonify, Response
import requests
import os
import time
from prometheus_client import generate_latest, CONTENT_TYPE_LATEST, Counter, Histogram

app = Flask(__name__)

# === Metrics Setup ===
REQUEST_COUNT = Counter("request_count", "Total requests", ["method", "endpoint"])
REQUEST_LATENCY = Histogram("request_latency_seconds", "Request latency", ["endpoint"])

# === Paths ===
BASE_DIR = os.path.dirname(__file__)
SITES_DIR = os.path.join(BASE_DIR, "output", "sites")

# # === Routes ===

@app.route("/sites/<company>/<path:filename>")
def serve_static_file(company, filename):
    REQUEST_COUNT.labels(method="GET", endpoint=f"/sites/{company}/{filename}").inc()
    return send_from_directory(os.path.join(SITES_DIR, company), filename)


@app.route("/sites/<company>/")
def serve_index(company):
    REQUEST_COUNT.labels(method="GET", endpoint=f"/sites/{company}/").inc()
    return send_from_directory(os.path.join(SITES_DIR, company), "index.html")


@app.route("/api/services")
def proxy_services():
    REQUEST_COUNT.labels(method="GET", endpoint="/api/services").inc()
    start = time.time()

    company = request.args.get("company", "nintendo").lower()
    API_HOST = os.environ.get("API_HOST", "https://monitor.dtinfra.site")

    # Try both /mock-api/services.json and /services.json (for fallback testing)
    url = f"{API_HOST}/services.json?company={company}"
    print(f"➡️ Fetching mock data from: {url}")

    try:
        resp = requests.get(url, timeout=3)
        resp.raise_for_status()  # Raise if HTTP error
        return jsonify(resp.json())
    except Exception as e:
        print(f"❌ Error fetching mock data: {e}")
        return jsonify({"error": "Unable to fetch service data", "details": str(e)}), 500
    finally:
        REQUEST_LATENCY.labels(endpoint="/api/services").observe(time.time() - start)



@app.route("/metrics")
def metrics():
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)


@app.route("/health")
def health():
    return "OK", 200

@app.route("/api/stop", methods=["POST"])
def shutdown_all():
    data = request.get_json()
    print("🛑 Received shutdown alert from Alertmanager!")
    print("📦 Full alert payload:")
    print(data)

    # Optional: Basic safety check
    if not data or "alerts" not in data:
        return "Invalid alert payload", 400

    # Optionally confirm it's a DashboardInactive alert
    if any(alert.get("labels", {}).get("alertname") == "DashboardInactive" for alert in data["alerts"]):
        print("✅ Confirmed DashboardInactive alert — initiating shutdown.")
        #os.system("cd terraform && terraform destroy -auto-approve")
        return "Shutdown initiated", 200
    else:
        print("⚠️ Received non-matching alert — ignoring.")
        return "Ignored", 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)

