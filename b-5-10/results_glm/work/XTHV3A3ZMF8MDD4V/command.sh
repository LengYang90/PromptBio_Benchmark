import pandas as pd

files = [
    "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/b-5-10/result_79/toolsgenie_20260709/data/gene_expression.csv",
    "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/b-5-10/result_79/toolsgenie_20260709/data/copy_number_variation.csv",
]

for f in files:
    print("=" * 80)
    print("FILE:", f)
    print("=" * 80)
    df = pd.read_csv(f, index_col=0)
    print("\n--- First 5 rows ---")
    print(df.head())
    print("\n--- Shape (rows x columns) ---")
    print(df.shape)
    print("\n--- Column names ---")
    print(list(df.columns))
    print("\n--- Index name ---")
    print(df.index.name)
    print("\n--- Data types ---")
    print(df.dtypes)
    print("\n--- Missing values (per column) ---")
    print(df.isnull().sum())
    print("Total missing:", df.isnull().sum().sum())
    print("\n--- Basic statistics ---")
    print(df.describe(include='all'))
    print("\n")
