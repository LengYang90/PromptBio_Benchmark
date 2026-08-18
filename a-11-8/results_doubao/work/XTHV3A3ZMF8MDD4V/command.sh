import pandas as pd

file_list = [
    "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-11-8/result_11/toolsgenie_20260623/data/ppi_network.csv",
    "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-11-8/result_11/toolsgenie_20260623/data/mirna_target.csv"
]

for file_path in file_list:
    print(f"\n=== File: {file_path} ===")
    df = pd.read_csv(file_path, index_col=0)
    print(f"Column names: {list(df.columns)}")
    print(f"Total row count: {len(df)}")
    print("First 5 rows:")
    print(df.head())
