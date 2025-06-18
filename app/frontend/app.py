from flask import Flask, request, redirect, render_template_string, send_from_directory, jsonify
import requests
import os

app = Flask(__name__)

BASE_DIR = os.path.dirname(__file__)
SITES_DIR = os.path.join(BASE_DIR, "output", "sites")

@app.route("/", methods=["GET", "POST"])
def index():
    companies = sorted(next(os.walk(SITES_DIR))[1]) if os.path.exists(SITES_DIR) else []

    if request.method == "POST":
        company = request.form["company"].lower()
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
        </style>
    </head>
    <body>
        <div class="container">
            <h1>DevOps Portal</h1>
            <p>Select your company</p>
            <form method="post">
                <select name="company">
                    {% for company in companies %}
                        <option value="{{ company }}">{{ company.capitalize() }}</option>
                    {% endfor %}
                </select><br/>
                <button type="submit">View Dashboard</button>
            </form>
        </div>
    </body>
    </html>
    """
    return render_template_string(html_template, companies=companies)

@app.route("/sites/<company>/<path:filename>")
def serve_static_file(company, filename):
    return send_from_directory(os.path.join(SITES_DIR, company), filename)

@app.route("/sites/<company>/")
def serve_index(company):
    return send_from_directory(os.path.join(SITES_DIR, company), "index.html")

@app.route("/api/services")
def proxy_services():
    company = request.args.get("company")
    try:
        # Use ALB directly
        resp = requests.get(
            f"http://dashboard-alb-2077270126.us-west-2.elb.amazonaws.com/api/services.json?company={company}",
            timeout=3
        )
        return jsonify(resp.json())
    except Exception as e:
        import traceback
        print("ERROR in /api/services:", traceback.format_exc())
        return jsonify({"error": "Unable to fetch service data", "details": str(e)}), 500

@app.route("/health")
def health():
    return "OK", 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
