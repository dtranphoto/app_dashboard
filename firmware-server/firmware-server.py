from flask import Flask, request, jsonify
import requests
from kubernetes import client, config
import os

app = Flask(__name__)

# Load in-cluster config (K8s service account)
try:
    config.load_incluster_config()
except:
    config.load_kube_config()

v1 = client.CoreV1Api()

NAMESPACE = "staging"
CAR_LABEL_SELECTOR = "app=car"
CAR_PORT = 8080
FIRMWARE_DIR = "/app/firmware"

@app.route("/push", methods=["POST"])
def push_firmware():
    version = request.args.get("version")
    if not version:
        return jsonify({"error": "Missing firmware version"}), 400

    firmware_path = os.path.join(FIRMWARE_DIR, f"firmware_v{version}.bin")

    if not os.path.exists(firmware_path):
        return jsonify({"error": f"Firmware file not found: {firmware_path}"}), 404

    with open(firmware_path, "rb") as f:
        firmware_data = f.read()

    pods = v1.list_namespaced_pod(namespace=NAMESPACE, label_selector=CAR_LABEL_SELECTOR)
    results = {}

    for pod in pods.items:
        pod_ip = pod.status.pod_ip
        if not pod_ip:
            results[pod.metadata.name] = "No pod IP"
            continue

        url = f"http://{pod_ip}:{CAR_PORT}/update"
        try:
            r = requests.post(url, data=firmware_data, timeout=3)
            results[pod.metadata.name] = r.json()
        except Exception as e:
            results[pod.metadata.name] = f"Failed: {str(e)}"

    return jsonify({
        "pushed_version": version,
        "results": results
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8090)

