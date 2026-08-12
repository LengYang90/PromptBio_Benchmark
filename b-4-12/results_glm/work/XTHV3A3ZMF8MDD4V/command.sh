import pandas as pd

df = pd.read_csv('/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/b-4-12/result_79/toolsgenie_20260709/data/cognitive_scores.csv')

print("=== SHAPE ===")
print(df.shape)

print("\n=== COLUMN NAMES ===")
print(list(df.columns))

print("\n=== DATA TYPES ===")
print(df.dtypes)

print("\n=== FIRST 10 ROWS ===")
print(df.head(10).to_string())

print("\n=== MISSING VALUES ===")
print(df.isnull().sum())

print("\n=== UNIQUE VALUES IN GROUP/DIAGNOSIS COLUMNS ===")
for col in df.columns:
    lower = col.lower()
    if any(k in lower for k in ['group', 'diagnosis', 'diagnos', 'condition', 'status', 'category', 'label', 'class']):
        print(f"\n{col}: {sorted(df[col].dropna().unique().tolist())}")
