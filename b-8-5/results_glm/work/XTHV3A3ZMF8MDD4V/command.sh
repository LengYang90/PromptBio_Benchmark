import pandas as pd

path = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/b-8-5/result_79/toolsgenie_20260709/data/icu_occupancy_timeseries.csv"
df = pd.read_csv(path)

print("=== SHAPE ===")
print(df.shape)

print("\n=== COLUMN NAMES ===")
print(list(df.columns))

print("\n=== DATA TYPES ===")
print(df.dtypes)

print("\n=== FIRST 10 ROWS ===")
print(df.head(10).to_string())

print("\n=== LAST 5 ROWS ===")
print(df.tail(5).to_string())

print("\n=== BASIC STATISTICS ===")
print(df.describe(include='all').to_string())

print("\n=== MISSING VALUES ===")
print(df.isnull().sum())
print("\nTotal missing:", df.isnull().sum().sum())
