import pandas as pd

path = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/b-6-9/result_79/toolsgenie_20260709/data/gene_expression.csv"
df = pd.read_csv(path, index_col=0)

print("=== First 5 rows ===")
print(df.head())
print("\n=== Column names ===")
print(list(df.columns))
print("\n=== Shape ===")
print(df.shape)
print("\n=== Group-related columns (guess) ===")
print([c for c in df.columns if any(k in c.lower() for k in ['group','label','class','condition','type','treatment'])])
print("\n=== Data types ===")
print(df.dtypes)
print("\n=== Basic statistics ===")
print(df.describe(include='all'))
