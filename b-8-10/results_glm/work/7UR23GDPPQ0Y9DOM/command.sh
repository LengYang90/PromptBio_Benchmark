import pandas as pd

path = '/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/b-8-10/result_79/toolsgenie_20260709/high_il6_specific_taxa.csv'
df = pd.read_csv(path)

print(f"Shape: {df.shape}")
print(f"Columns: {list(df.columns)}")
print(f"Column dtypes:\n{df.dtypes}")
print(f"\nExpected columns ['Taxon', 'Coefficient'] present: {list(df.columns) == ['Taxon', 'Coefficient']}")
print(f"\nFile content:")
print(df.to_string(index=False))
