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

# === Routes ===

@app.route("/", methods=["GET", "POST"])
def index():
    REQUEST_COUNT.labels(method=request.method, endpoint="/").inc()
    start = time.time()

    companies = sorted(next(os.walk(SITES_DIR))[1]) if os.path.exists(SITES_DIR) else []

    if request.method == "POST":
        company = request.form["company"].lower()
        REQUEST_LATENCY.labels(endpoint="/").observe(time.time() - start)
        return redirect(f"/sites/{company}/")

    html_template = """
    <html>
    <head>
        <title>DevOps Dashboard Portal</title>
        <style>
            body {
                font-family: 'Segoe UI', sans-serif;
                background-color: #f2f6fc;
                display: flex;
                justify-content: center;
                align-items: center;
                height: 100vh;
                margin: 0;
            }
            .container {
                background: white;
                padding: 40px;
                border-radius: 12px;
                box-shadow: 0 8px 24px rgba(0, 0, 0, 0.1);
                text-align: center;
                max-width: 400px;
                width: 100%;
            }
            h1 {
                color: #005FCC;
                margin-bottom: 10px;
            }
            p {
                color: #333;
                margin-bottom: 20px;
                font-size: 16px;
            }
            select, button {
                width: 100%;
                padding: 10px;
                font-size: 16px;
                margin-top: 10px;
                border-radius: 6px;
                border: 1px solid #ccc;
            }
            button {
                background-color: #007BFF;
                color: white;
                border: none;
                cursor: pointer;
            }
            button:hover {
                background-color: #005FCC;
            }
            .banner {
                background-color: #fff3cd;
                color: #856404;
                border: 1px solid #ffeeba;
                padding: 10px;
                border-radius: 5px;
                font-size: 14px;
                text-align: center;
                position: fixed;
                bottom: 20px;
                left: 50%;
                transform: translateX(-50%);
                width: calc(100% - 40px);
                max-width: 400px;
                z-index: 1000;
                box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
                opacity: 1;
                transition: opacity 1s ease-out;
            }
            .spinner {
                margin: 20px auto;
                width: 40px;
                height: 40px;
                border: 4px solid #ccc;
                border-top: 4px solid #007BFF;
                border-radius: 50%;
                animation: spin 1s linear infinite;
            }
            @keyframes spin {
                0% { transform: rotate(0deg); }
                100% { transform: rotate(360deg); }
            }
        </style>
    </head>
    <body>
        <div class="container">
            
            <div id="form-area">
                <h1>DevOps Portal</h1>
                <p>Select your company</p>
               <form id="company-form" onsubmit="return handleFormSubmit(event)">
                    <select id="company-select" name="company">
                        {% for company in companies %}
                            <option value="{{ company }}">{{ company.capitalize() }}</option>
                        {% endfor %}
                    </select><br/>
                    <button type="submit">View Dashboard</button>
                </form>
            </div>

            <div id="loading" style="display: none;">
                <p>🚀 Preparing your dashboard...</p>
                <div class="spinner"></div>
                <div id="status-text" style="margin-top: 20px; font-size: 15px; color: #333;"></div>
            </div>

            <div class="banner">⚠️ Dashboards will shut down after 5 minutes of inactivity.</div>
        </div>

        <script>
        function handleFormSubmit(e) {
            e.preventDefault();
            const company = document.getElementById("company-select").value.toLowerCase();

            document.getElementById("form-area").style.display = "none";
            document.getElementById("loading").style.display = "block";

            const steps = [
                "Building static dashboard...",
                "Running Terraform to provision AWS infrastructure...",
                "Starting mock API and ECS containers...",
                "Bootstrapping Prometheus and Grafana...",
                "Verifying container health on AWS...",
                "Redirecting to your dashboard..."
            ];

            const statusText = document.getElementById("status-text");
            let i = 0;

            function updateStep() {
                if (i < steps.length) {
                    statusText.innerText = steps[i];
                    i++;
                    setTimeout(updateStep, 2000);
                } else {
                    window.location.href = `/sites/${company}/`;
                }
            }

            updateStep();
            return false;
        }
        </script>
        <script>
            window.addEventListener("DOMContentLoaded", () => {
                const banner = document.querySelector(".banner");
                setTimeout(() => {
                    banner.style.opacity = "0";
                }, 6000);  // fades after 6 seconds
            });
        </script>
    </body>
    </html>
    """
    REQUEST_LATENCY.labels(endpoint="/").observe(time.time() - start)
    return render_template_string(html_template, companies=companies)

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
    print(data)  # This will include alert name, labels, annotations, etc.

    # For now, don’t shut anything down:
    # os.system("cd terraform && terraform destroy -auto-approve")

    return "Shutdown simulated", 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)

