import pandas as pd

path = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/b-5-7/result_79/toolsgenie_20260709/data/bio_dataset.csv"
df = pd.read_csv(path)

print("=== FIRST FEW ROWS ===")
print(df.head())
print("\n=== SHAPE ===")
print(df.shape)
print("\n=== COLUMN NAMES ===")
print(list(df.columns))
print("\n=== DATA TYPES ===")
print(df.dtypes)
print("\n=== BASIC STATISTICS ===")
print(df.describe(include='all'))
print("\n=== MISSING VALUES (per column) ===")
print(df.isnull().sum())
print("\n=== TOTAL MISSING VALUES ===")
print(df.isnull().sum().sum())
