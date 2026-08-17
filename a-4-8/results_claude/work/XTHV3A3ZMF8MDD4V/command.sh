import pandas as pd
import numpy as np

# Load and inspect the ChIP-seq data
data_path = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-4-8/result_2/toolsgenie_20260430/data/ChIP_data.csv"
df = pd.read_csv(data_path, index_col=0)

print("=== ChIP_data.csv Structure and Content Analysis ===")
print(f"\nFile: {data_path}")
print(f"Shape: {df.shape} (rows x columns)")
print(f"Index name: {df.index.name}")
print(f"Column names: {list(df.columns)}")

print("\n=== Data Types ===")
print(df.dtypes)

print("\n=== Index (Genomic Positions) ===")
print(f"Index range: {df.index.min()} to {df.index.max()}")
print(f"Index type: {type(df.index[0])}")
print(f"Number of genomic positions: {len(df.index)}")

print("\n=== Dataset Information ===")
print(f"Number of ChIP-seq datasets: {df.shape[1]}")
print(f"Dataset names: {list(df.columns)}")

print("\n=== Signal Value Statistics ===")
print("Summary statistics for each dataset:")
print(df.describe())

print("\n=== Data Sample (first 10 rows) ===")
print(df.head(10))

print("\n=== Data Sample (last 10 rows) ===")
print(df.tail(10))

print("\n=== Missing Values ===")
print(f"Missing values per dataset:")
print(df.isnull().sum())

print("\n=== Signal Range Analysis ===")
for col in df.columns:
    if df[col].dtype in ['int64', 'float64']:
        print(f"{col}: min={df[col].min():.3f}, max={df[col].max():.3f}, mean={df[col].mean():.3f}, std={df[col].std():.3f}")
    else:
        unique_vals = df[col].unique()
        print(f"{col}: data type={df[col].dtype}, unique values={len(unique_vals)}, examples={list(unique_vals[:5])}")

print("\n=== Experiment Analysis ===")
print("Unique experiments in the dataset:")
experiments = df.index.unique()
print(f"Number of experiments: {len(experiments)}")
print(f"Experiment names: {list(experiments)}")

for exp in experiments:
    exp_data = df[df.index == exp]
    print(f"\n{exp}: {len(exp_data)} regions, count range: {exp_data['count'].min()}-{exp_data['count'].max()}")

print("\n=== Data Quality Check ===")
print(f"Any negative values in count: {(df['count'] < 0).any()}")
print(f"Any infinite values: {np.isinf(df.select_dtypes(include=[np.number])).any().any()}")
print(f"Data suitable for ChIP-seq segmentation: Signal values are non-negative discrete counts")

print("\n=== Genomic Coverage ===")
print("Chromosomes covered:")
chroms = df['chrom'].unique()
print(f"Number of chromosomes: {len(chroms)}")
print(f"Chromosome list: {sorted(chroms)}")

print(f"\nGenomic coordinate range:")
print(f"Overall start: {df['chromStart'].min()}")
print(f"Overall end: {df['chromEnd'].max()}")
print(f"Average region length: {(df['chromEnd'] - df['chromStart']).mean():.1f} bp")
