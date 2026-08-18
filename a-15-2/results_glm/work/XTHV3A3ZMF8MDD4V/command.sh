import pandas as pd

files = [
    "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_714/toolsgenie_20260714/data/Matrix_of_SNP_genotypes.csv",
    "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_714/toolsgenie_20260714/data/Matrix_of_bulk_omics_measurements.csv",
    "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_714/toolsgenie_20260714/data/Matrix_of_bulk_omics_positions.csv",
    "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_714/toolsgenie_20260714/data/Matrix_of_cell_type_composition.csv",
]

for f in files:
    print("=" * 80)
    print("FILE:", f)
    df = pd.read_csv(f, index_col=0)
    print("SHAPE (rows x cols):", df.shape)
    print("INDEX NAME:", df.index.name)
    print("INDEX (first 10):", list(df.index[:10]))
    print("COLUMNS (first 10):", list(df.columns[:10]))
    print("DTYPES:")
    print(df.dtypes)
    print("FIRST 5 ROWS, FIRST 5 COLS:")
    print(df.iloc[:5, :5])
    print()
