import pandas as pd

f = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_714/toolsgenie_20260714/mQTL_results.txt"
df = pd.read_csv(f, sep="\t")

print("=== File Format ===")
print(f"File: {f}")
print(f"Separator: tab (\\t)")
print(f"Shape: {df.shape[0]} rows x {df.shape[1]} columns")
print(f"\n=== Column Names ===")
print(list(df.columns))
print(f"\n=== Column Types ===")
print(df.dtypes)
print(f"\n=== First 5 Rows ===")
print(df.head().to_string(index=False))
print(f"\n=== Last 5 Rows ===")
print(df.tail().to_string(index=False))
print(f"\n=== Total Number of Rows ===")
print(len(df))

print(f"\n=== Significant P-values (p < 0.05) ===")
sig = df[df["p.value"] < 0.05]
print(f"Count: {len(sig)}")
if len(sig) > 0:
    print(sig.to_string(index=False))
    print(f"\nMin p-value: {df['p.value'].min()}")
    print(f"Corresponding row:")
    print(df.loc[df['p.value'].idxmin()].to_string())
else:
    print("No significant p-values found.")
