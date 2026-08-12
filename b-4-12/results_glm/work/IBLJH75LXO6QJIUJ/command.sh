import pandas as pd

path = '/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/b-4-12/result_79/toolsgenie_20260709/data/ttest_cohens_d_results.csv'
df = pd.read_csv(path)
print(f"File: {path}")
print(f"Shape: {df.shape}")
print(f"Columns: {list(df.columns)}")
print("\n=== Contents ===")
print(df.to_string(index=False))
