import tensorflow as tf
from flask import Flask, request, jsonify, Response, stream_with_context
from subprocess import Popen, PIPE, TimeoutExpired
import json
import threading

app = Flask(__name__)

# A lock to prevent race conditions when accessing the shared data structure
results_lock = threading.Lock()
latest_results = {}

@app.route('/process_data', methods=['POST'])
def process_data():
    global latest_results

    if not request.json:
        return jsonify({"error": "Invalid input data"}), 400

    json_data = request.get_json()
    json_data_str = json.dumps(json_data)

    try:
        # Run the model_predict.py script with the input data as a string
        process = Popen(["python", "model_predict.py"], stdin=PIPE, stdout=PIPE, stderr=PIPE, text=True)
        stdout, stderr = process.communicate(json_data_str, timeout=15)

        if process.returncode != 0:
            return jsonify({"error": f"Error during prediction: {stderr}"}), 500

        with results_lock:
            latest_results = json.loads(stdout)

        return jsonify(latest_results)

    except TimeoutExpired:
        process.kill()
        return jsonify({"error": "Prediction timed out"}), 504

@app.route('/get_results', methods=['GET'])
def get_results():
    with results_lock:
        return jsonify(latest_results)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
