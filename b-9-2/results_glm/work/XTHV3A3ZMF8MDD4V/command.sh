import pandas as pd

path = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/b-9-2/result_79/toolsgenie_20260709/data/simulated_cox_data.csv"
df = pd.read_csv(path)

print("=== FIRST FEW ROWS ===")
print(df.head())
print("\n=== COLUMN NAMES ===")
print(list(df.columns))
print("\n=== DATA TYPES ===")
print(df.dtypes)
print("\n=== NUMBER OF ROWS ===")
print(len(df))
print("\n=== SUMMARY STATISTICS ===")
print(df.describe(include='all'))
print("\n=== MISSING VALUES ===")
print(df.isnull().sum())
print("\n=== UNIQUE VALUES IN CATEGORICAL COLUMNS ===")
for col in df.select_dtypes(include=['object', 'category']).columns:
    print(f"\n{col}: {df[col].unique().tolist()}")
