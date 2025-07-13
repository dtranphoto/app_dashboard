from flask import Flask, jsonify, request
import os

app = Flask(__name__)

# Start with the env var version
firmware_version = os.environ.get("FIRMWARE_VERSION", "v1.0")

def run_bist_tests(version):
    return {
        "firmware_version_check": "PASS",
        "disk_space_check": "PASS",
        "sensor_calibration": "PASS",
        "network_ping": "PASS"
    }

@app.route("/status")
def status():
    return jsonify({
        "firmware_version": firmware_version,
        "update_status": "SUCCESS",
        "bist_results": run_bist_tests(firmware_version)
    })

@app.route("/update", methods=["POST"])
def update():
    global firmware_version
    new_version = request.args.get("version")
    if not new_version:
        return jsonify({"error": "No version specified"}), 400

    firmware_version = new_version
    return jsonify({"message": f"Firmware updated to {new_version}"}), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
