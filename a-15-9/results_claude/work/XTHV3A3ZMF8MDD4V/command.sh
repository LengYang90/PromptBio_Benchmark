import pandas as pd
import numpy as np

# Load the three files
pheno_path = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-9/result_10/toolsgenie_20260516/data/Pheno.csv"
protein_path = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-9/result_10/toolsgenie_20260516/data/protein.csv"
rna_path = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-9/result_10/toolsgenie_20260516/data/rna.csv"

# Load and inspect Pheno.csv
print("=== PHENO.CSV INSPECTION ===")
pheno = pd.read_csv(pheno_path, index_col=0)
print(f"Dimensions: {pheno.shape}")
print(f"Sample IDs (first 10): {list(pheno.index[:10])}")
print(f"Columns: {list(pheno.columns)}")
print(f"Data types:\n{pheno.dtypes}")
print(f"Summary statistics:\n{pheno.describe()}")
print(f"Missing values: {pheno.isnull().sum().sum()}")
print(f"Sample data (first 5 rows):\n{pheno.head()}")

print("\n=== PROTEIN.CSV INSPECTION ===")
protein = pd.read_csv(protein_path, index_col=0)
print(f"Dimensions: {protein.shape}")
print(f"Sample IDs (first 10): {list(protein.index[:10])}")
print(f"Feature names (first 10): {list(protein.columns[:10])}")
print(f"Data type: {protein.dtypes.iloc[0]}")
print(f"Value range: [{protein.min().min():.3f}, {protein.max().max():.3f}]")
print(f"Missing values: {protein.isnull().sum().sum()}")
print(f"Sample data (first 5x5):\n{protein.iloc[:5, :5]}")

print("\n=== RNA.CSV INSPECTION ===")
rna = pd.read_csv(rna_path, index_col=0)
print(f"Dimensions: {rna.shape}")
print(f"Sample IDs (first 10): {list(rna.index[:10])}")
print(f"Feature names (first 10): {list(rna.columns[:10])}")
print(f"Data type: {rna.dtypes.iloc[0]}")
print(f"Value range: [{rna.min().min():.3f}, {rna.max().max():.3f}]")
print(f"Missing values: {rna.isnull().sum().sum()}")
print(f"Sample data (first 5x5):\n{rna.iloc[:5, :5]}")

print("\n=== SAMPLE ID OVERLAP ANALYSIS ===")
pheno_samples = set(pheno.index)
protein_samples = set(protein.index)
rna_samples = set(rna.index)

print(f"Pheno samples: {len(pheno_samples)}")
print(f"Protein samples: {len(protein_samples)}")
print(f"RNA samples: {len(rna_samples)}")
print(f"Common samples (all three): {len(pheno_samples & protein_samples & rna_samples)}")
print(f"Common samples (protein & RNA): {len(protein_samples & rna_samples)}")
