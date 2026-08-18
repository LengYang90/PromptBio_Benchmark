## Description:
##      This script uses LSTM neural network to predict daily ICU occupancy for next 7 days.
##      Uses past 21 days of admission data for benchmark question b-8-5.

import os
import pandas as pd
import numpy as np
from sklearn.preprocessing import MinMaxScaler
from sklearn.metrics import mean_squared_error, mean_absolute_error
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import LSTM, Dense, Dropout
from tensorflow.keras.callbacks import EarlyStopping
import warnings
warnings.filterwarnings('ignore')

# Set random seeds for reproducibility
np.random.seed(42)
tf.random.set_seed(42)

def create_sequences(data, lookback=21, forecast_horizon=7):
    """
    Create sequences for LSTM training.
    
    Args:
        data: 1D array of time series data
        lookback: Number of past days to use as input (21)
        forecast_horizon: Number of future days to predict (7)
    
    Returns:
        X: Input sequences of shape (samples, lookback, 1)
        y: Target sequences of shape (samples, forecast_horizon)
    """
    X, y = [], []
    
    for i in range(len(data) - lookback - forecast_horizon + 1):
        X.append(data[i:i+lookback])
        y.append(data[i+lookback:i+lookback+forecast_horizon])
    
    return np.array(X), np.array(y)

def main():
    task_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    data_file = os.path.join(task_dir, "data", "icu_occupancy_timeseries.csv")
    result_dir = os.path.join(task_dir, "ref_answer")
    os.makedirs(result_dir, exist_ok=True)
    
    # Output file
    performance_file = os.path.join(result_dir, "test_performance.csv")
    
    # Load data
    print(f"Loading data from: {os.path.abspath(data_file)}")
    df = pd.read_csv(data_file)
    
    print(f"Dataset shape: {df.shape}")
    print(f"Date range: {df['Date'].min()} to {df['Date'].max()}")
    
    # Extract ICU occupancy values
    icu_data = df['ICU_Occupancy'].values
    
    print(f"\nICU Occupancy Statistics:")
    print(f"  Total days: {len(icu_data)}")
    print(f"  Min: {icu_data.min():.1f}")
    print(f"  Max: {icu_data.max():.1f}")
    print(f"  Mean: {icu_data.mean():.1f}")
    print(f"  Std: {icu_data.std():.1f}")
    
    # Normalize data
    print(f"\nNormalizing data...")
    scaler = MinMaxScaler(feature_range=(0, 1))
    icu_data_scaled = scaler.fit_transform(icu_data.reshape(-1, 1)).flatten()
    
    # Create sequences
    lookback = 21  # Past 21 days
    forecast_horizon = 7  # Predict next 7 days
    
    print(f"\nCreating sequences:")
    print(f"  Lookback window: {lookback} days")
    print(f"  Forecast horizon: {forecast_horizon} days")
    
    X, y = create_sequences(icu_data_scaled, lookback, forecast_horizon)
    
    print(f"  Total sequences: {len(X)}")
    print(f"  Input shape: {X.shape}")
    print(f"  Output shape: {y.shape}")
    
    # Split into train and test (80-20 split)
    split_idx = int(0.8 * len(X))
    
    X_train, X_test = X[:split_idx], X[split_idx:]
    y_train, y_test = y[:split_idx], y[split_idx:]
    
    # Reshape X for LSTM [samples, timesteps, features]
    X_train = X_train.reshape((X_train.shape[0], X_train.shape[1], 1))
    X_test = X_test.reshape((X_test.shape[0], X_test.shape[1], 1))
    
    print(f"\nTrain-Test Split (80-20):")
    print(f"  Training sequences: {len(X_train)}")
    print(f"  Test sequences: {len(X_test)}")
    
    # Build LSTM model
    print(f"\nBuilding LSTM model...")
    model = Sequential([
        LSTM(64, activation='relu', return_sequences=True, input_shape=(lookback, 1)),
        Dropout(0.2),
        LSTM(32, activation='relu'),
        Dropout(0.2),
        Dense(16, activation='relu'),
        Dense(forecast_horizon)
    ])
    
    model.compile(optimizer='adam', loss='mse', metrics=['mae'])
    
    print(f"\nModel Architecture:")
    model.summary()
    
    # Early stopping callback
    early_stopping = EarlyStopping(
        monitor='val_loss',
        patience=10,
        restore_best_weights=True
    )
    
    # Train model
    print(f"\nTraining LSTM model...")
    history = model.fit(
        X_train, y_train,
        epochs=100,
        batch_size=32,
        validation_split=0.2,
        callbacks=[early_stopping],
        verbose=1
    )
    
    # Make predictions
    print(f"\nMaking predictions...")
    y_train_pred = model.predict(X_train, verbose=0)
    y_test_pred = model.predict(X_test, verbose=0)
    
    # Inverse transform predictions and actual values
    # Reshape for inverse transform
    y_train_actual = scaler.inverse_transform(y_train.reshape(-1, 1)).reshape(y_train.shape)
    y_train_pred_actual = scaler.inverse_transform(y_train_pred.reshape(-1, 1)).reshape(y_train_pred.shape)
    
    y_test_actual = scaler.inverse_transform(y_test.reshape(-1, 1)).reshape(y_test.shape)
    y_test_pred_actual = scaler.inverse_transform(y_test_pred.reshape(-1, 1)).reshape(y_test_pred.shape)
    
    # Calculate metrics
    train_rmse = np.sqrt(mean_squared_error(y_train_actual.flatten(), y_train_pred_actual.flatten()))
    train_mae = mean_absolute_error(y_train_actual.flatten(), y_train_pred_actual.flatten())
    
    test_rmse = np.sqrt(mean_squared_error(y_test_actual.flatten(), y_test_pred_actual.flatten()))
    test_mae = mean_absolute_error(y_test_actual.flatten(), y_test_pred_actual.flatten())
    
    print(f"\nModel Performance:")
    print(f"  Training RMSE: {train_rmse:.4f}")
    print(f"  Training MAE: {train_mae:.4f}")
    print(f"\n  Test RMSE: {test_rmse:.4f}")
    print(f"  Test MAE: {test_mae:.4f}")
    
    # Save performance metrics (only Test RMSE as requested)
    performance_df = pd.DataFrame({
        'Metric': ['Test_RMSE'],
        'Value': [test_rmse]
    })
    performance_df.to_csv(performance_file, index=False)
    print(f"\nTest performance saved to: {os.path.abspath(performance_file)}")
    
    # Display sample predictions
    print(f"\nSample Test Predictions (first 3 sequences):")
    for i in range(min(3, len(y_test_actual))):
        print(f"\nSequence {i+1}:")
        print(f"  Actual:    {y_test_actual[i].round(1)}")
        print(f"  Predicted: {y_test_pred_actual[i].round(1)}")

if __name__ == "__main__":
    main()

