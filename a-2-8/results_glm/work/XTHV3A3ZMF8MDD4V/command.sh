import pandas as pd
import csv

path = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-2-8/result_714/toolsgenie_20260714/data/gene_rnk.txt"

# First 20 lines (raw)
print("===== FIRST 20 LINES (RAW) =====")
with open(path) as f:
    for i, line in enumerate(f):
        if i >= 20:
            break
        print(repr(line.rstrip("\n")))

# Total line count
with open(path) as f:
    total_lines = sum(1 for _ in f)
print(f"\n===== TOTAL LINES: {total_lines} =====")

# Delimiter detection (sniff first line)
with open(path) as f:
    sample = f.read(4096)
    try:
        dialect = csv.Sniffer().sniff(sample, delimiters="\t, ;|")
        delim = dialect.delimiter
    except Exception:
        delim = "\t"
print(f"\n===== DETECTED DELIMITER: {repr(delim)} =====")

# Load with pandas - file has NO header row (standard .rnk format), use header=None
df = pd.read_csv(path, sep=delim, header=None, names=["gene", "score"])
print("\n===== SHAPE =====")
print(df.shape)

print("\n===== COLUMNS =====")
print(list(df.columns))

print("\n===== DTYPES =====")
print(df.dtypes)

print("\n===== HEAD =====")
print(df.head(20).to_string())

print("\n===== MISSING VALUES (per column) =====")
print(df.isna().sum())

print("\n===== DUPLICATE ROWS =====")
print(df.duplicated().sum())

print("\n===== DUPLICATES IN FIRST COLUMN (gene names) =====")
print(df.iloc[:, 0].duplicated().sum())

# Numeric column anomaly check
num_cols = df.select_dtypes(include="number").columns
for c in num_cols:
    print(f"\n===== STATS FOR {c} =====")
    print(df[c].describe())
    print(f"Inf count: {((df[c] == float('inf')) | (df[c] == float('-inf'))).sum()}")
