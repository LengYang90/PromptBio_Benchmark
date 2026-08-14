import pandas as pd

files = [
    "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_714/toolsgenie_20260714/data/Matrix_of_trait_positions.csv",
    "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_714/toolsgenie_20260714/data/Matrix_of_ovariates.csv",
]

for f in files:
    print("=" * 80)
    print("FILE:", f)
    df = pd.read_csv(f, index_col=0)
    print("SHAPE (rows x cols):", df.shape)
    print("INDEX NAME:", df.index.name)
    print("INDEX:", list(df.index))
    print("COLUMNS:", list(df.columns))
    print("DTYPES:")
    print(df.dtypes)
    print("FIRST 5 ROWS:")
    print(df.head())
    print()
