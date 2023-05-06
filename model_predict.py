import sys
import json
from collections import deque
import tensorflow as tf
import numpy as np

def pad_data(data, target_length=70):
    data_length = len(data)
    if data_length < target_length:
        padding_length = target_length - data_length
        padded_data = np.pad(data, ((0, padding_length), (0, 0)), mode='constant', constant_values=0)
    else:
        padded_data = data[:target_length]
    return padded_data

# Function to preprocess a single data sample
def preprocess_single_sample(json_data):
    filtered_data = []
    for item in json_data:
        filtered_item = [{item["rotation_x"], item["rotation_y"], item["rotation_z"],
                          item["acceleration_x"], item["acceleration_y"], item["acceleration_z"]}]
        float_item = [float(val) for val_set in filtered_item for val in val_set]
        filtered_data.append(float_item)

    return np.array(filtered_data)

def predict_with_convlstm(json_data, model, window_size=70, probability_threshold=0.5):
    sliding_window = deque(maxlen=window_size)

    # Create a mapping of indices to dance groove names
    dance_grooves = {0: "down bounce", 1: "front jack"}

    # Preprocess the single data sample and add it to the sliding window
    processed_json = preprocess_single_sample(json_data)
    print(processed_json)

    for processed_item in processed_json:
        sliding_window.append(processed_item)
        # If the sliding window is full, make a prediction
        if len(sliding_window) == window_size:
            window_data = np.array(sliding_window)
            window_data = np.expand_dims(window_data, axis=0)  # Add batch dimension
            window_data = np.expand_dims(window_data, axis=-1)  # Add channel dimension

            prediction = model.predict(window_data)
            predicted_class = np.argmax(prediction)

            if prediction[0][predicted_class] > probability_threshold:
                result = {"Detected groove": dance_grooves[predicted_class]}
            else:
                result = {"No groove detected": True}

            yield result

if __name__ == "__main__":
    model_path = sys.argv[1]
    input_data = json.loads(sys.argv[2])

    model = tf.keras.models.load_model(model_path)
    prediction_result = predict_with_convlstm(input_data, model)

    print(json.dumps(prediction_result))