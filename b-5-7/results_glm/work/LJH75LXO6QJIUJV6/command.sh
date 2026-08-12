import pandas as pd
import os

csv_path = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/b-5-7/result_79/toolsgenie_20260709/data/laplacian_eigenvalues.csv"
png_path = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/b-5-7/result_79/toolsgenie_20260709/data/laplacian_eigenvalues.png"

df = pd.read_csv(csv_path)
print("=== CSV Verification ===")
print(f"Column names: {list(df.columns)}")
print(f"Total row count: {len(df)}")
print("\nFirst 10 rows:")
print(df.head(10).to_string())
eigvals = df["eigenvalue"].values
is_sorted = all(eigvals[i] <= eigvals[i+1] for i in range(len(eigvals)-1))
print(f"\nEigenvalues sorted ascending: {is_sorted}")

print("\n=== PNG Verification ===")
exists = os.path.exists(png_path)
print(f"File exists: {exists}")
if exists:
    size_bytes = os.path.getsize(png_path)
    print(f"File size: {size_bytes} bytes ({size_bytes/1024:.2f} KB)")
