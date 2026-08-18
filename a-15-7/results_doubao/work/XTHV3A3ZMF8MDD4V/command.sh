import pandas as pd

file_paths = [
    "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-7/result_11/toolsgenie_20260623/data/gbm.exp.csv",
    "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-7/result_11/toolsgenie_20260623/data/gbm.mut.csv",
    "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-7/result_11/toolsgenie_20260623/data/gbm.cn.csv"
]

for fp in file_paths:
    print(f"\n=== Processing file: {fp} ===")
    df = pd.read_csv(fp)
    print("First 5 rows:")
    print(df.head().to_string())
    rows, cols = df.shape
    print(f"Dimensions: {rows} rows × {cols} columns")
    first_col_unique = df.iloc[:, 0].is_unique
    print(f"First column contains sample IDs: {first_col_unique}")
    if first_col_unique:
        print(f"Sample count: {rows}")
        print(f"Feature count: {cols - 1}")
    else:
        print(f"Number of rows: {rows}, Number of columns: {cols}")
