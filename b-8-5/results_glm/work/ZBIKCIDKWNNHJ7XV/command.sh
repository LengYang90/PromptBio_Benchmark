import os
os.environ['CUDA_VISIBLE_DEVICES'] = '-1'

import random
import numpy as np
import pandas as pd
import tensorflow as tf
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import LSTM, Dense
from tensorflow.keras.callbacks import EarlyStopping
from sklearn.preprocessing import MinMaxScaler
from sklearn.metrics import mean_squared_error, mean_absolute_error

random.seed(42)
np.random.seed(42)
tf.random.set_seed(42)
tf.config.set_visible_devices([], 'GPU')

data_path = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/b-8-5/result_79/toolsgenie_20260709/data/icu_occupancy_timeseries.csv"
df = pd.read_csv(data_path)
df['Date'] = pd.to_datetime(df['Date'])
df.set_index('Date', inplace=True)
values = df['ICU_Occupancy'].values.reshape(-1, 1)

split_idx = int(len(values) * 0.8)
train_values = values[:split_idx]
test_values = values[split_idx:]

scaler = MinMaxScaler()
train_scaled = scaler.fit_transform(train_values)
test_scaled = scaler.transform(test_values)

def create_sequences(data, input_len=21, output_len=7):
    X, y = [], []
    for i in range(len(data) - input_len - output_len + 1):
        X.append(data[i:i+input_len])
        y.append(data[i+input_len:i+input_len+output_len])
    return np.array(X), np.array(y)

X_train, y_train = create_sequences(train_scaled)
X_test, y_test = create_sequences(test_scaled)

model = Sequential([
    LSTM(64, return_sequences=False, input_shape=(21, 1)),
    Dense(32, activation='relu'),
    Dense(7)
])
model.compile(optimizer='adam', loss='mse')

early_stop = EarlyStopping(monitor='val_loss', patience=20, restore_best_weights=True)
model.fit(X_train, y_train, epochs=200, batch_size=16, validation_split=0.2,
          callbacks=[early_stop], verbose=1)

y_pred_scaled = model.predict(X_test, verbose=0)
y_pred = scaler.inverse_transform(y_pred_scaled.reshape(-1, 1)).reshape(y_pred_scaled.shape)
y_true = scaler.inverse_transform(y_test.reshape(-1, 1)).reshape(y_test.shape)

y_pred_flat = y_pred.flatten()
y_true_flat = y_true.flatten()

rmse = np.sqrt(mean_squared_error(y_true_flat, y_pred_flat))
mae = mean_absolute_error(y_true_flat, y_pred_flat)
mape = np.mean(np.abs((y_true_flat - y_pred_flat) / y_true_flat)) * 100

output_path = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/b-8-5/result_79/toolsgenie_20260709/data/test_performance.csv"
results = pd.DataFrame({'Metric': ['RMSE', 'MAE', 'MAPE'], 'Value': [rmse, mae, mape]})
results.to_csv(output_path, index=False)

print(f"\nTest RMSE: {rmse:.4f}")
print("\n=== Output File Contents ===")
print(pd.read_csv(output_path).to_string(index=False))
