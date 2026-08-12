import pandas as pd

result_path = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-2-8/result_714/toolsgenie_20260714/data/gsea_result.csv"
top5_path = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-2-8/result_714/toolsgenie_20260714/data/gsea_top5_result.csv"

df = pd.read_csv(result_path)
print("=== gsea_result.csv ===")
print("Shape:", df.shape)
print("Columns:", list(df.columns))
print("First 10 rows:")
print(df.head(10).to_string())

print("\n=== gsea_top5_result.csv ===")
top5 = pd.read_csv(top5_path)
print(top5.to_string())

required = ["Name", "Term", "NES", "FDR q-val"]
print("\n=== Column Verification ===")
print("gsea_result.csv contains required columns:", all(c in df.columns for c in required))
print("gsea_top5_result.csv contains required columns:", all(c in top5.columns for c in required))
