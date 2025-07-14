from flask import Flask, jsonify, request
import os

app = Flask(__name__)

FIRMWARE_PATH = "/app/firmware.bin"
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

    # Get version from query param
    new_version = request.args.get("version")
    if not new_version:
        return jsonify({"error": "No version specified"}), 400

    # Save binary firmware to file
    firmware_data = request.data
    if not firmware_data:
        return jsonify({"error": "No firmware binary received"}), 400

    try:
        with open(FIRMWARE_PATH, "wb") as f:
            f.write(firmware_data)

        firmware_version = new_version
        return jsonify({"message": f"Firmware flashed to {firmware_version}"}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
