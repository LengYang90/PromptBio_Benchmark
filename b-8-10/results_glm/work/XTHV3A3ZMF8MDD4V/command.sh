import pandas as pd

path = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/b-8-10/result_79/toolsgenie_20260709/data/microbiome_il6_data.csv"
df = pd.read_csv(path)

print("Shape:", df.shape)
print("\nFirst 20 columns:", list(df.columns[:20]))
print("\nLast 20 columns:", list(df.columns[-20:]))
print("\nData types:\n", df.dtypes)
print("\nFirst 5 rows:\n", df.head())
print("\nBasic statistics:\n", df.describe())

num_df = df.select_dtypes(include='number')
neg_counts = (num_df < 0).sum()
print("\nColumns with negative values (count>0):\n", neg_counts[neg_counts > 0])
zero_counts = (num_df == 0).sum()
print("\nColumns with zero values (count>0):\n", zero_counts[zero_counts > 0])

il6_candidates = [c for c in df.columns if 'il' in c.lower() and '6' in c.lower()]
print("\nIL-6 candidate columns:", il6_candidates)
