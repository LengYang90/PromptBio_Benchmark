import pandas as pd

# Load data with first column as row index
input_file = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-4-8/result_11/toolsgenie_20260623/data/ChIP_data.csv"
df = pd.read_csv(input_file, index_col=0)

# Print required information
print("First 10 rows:")
print(df.head(10))

print("\nColumn names:")
print(df.columns.tolist())

print("\nNumber of unique datasets (stored in row index 'experiment'):")
print(df.index.nunique())

print("\nSummary statistics for numeric columns:")
print(df.describe())
