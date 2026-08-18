import pandas as pd

path = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/b-8-5/result_79/toolsgenie_20260709/data/test_performance.csv"
df = pd.read_csv(path)
print("Shape:", df.shape)
print("Columns:", list(df.columns))
print("Dtypes:")
print(df.dtypes)
print("\n=== Contents ===")
print(df.to_string(index=False))
