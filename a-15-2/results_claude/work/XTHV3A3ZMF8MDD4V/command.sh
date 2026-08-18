import pandas as pd
import numpy as np

# Load and inspect all data files
snp_file = '/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_2/toolsgenie_20260430/data/Matrix_of_SNP_genotypes.csv'
omics_file = '/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_2/toolsgenie_20260430/data/Matrix_of_bulk_omics_measurements.csv'
positions_file = '/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_2/toolsgenie_20260430/data/Matrix_of_bulk_omics_positions.csv'
composition_file = '/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_2/toolsgenie_20260430/data/Matrix_of_cell_type_composition.csv'

# Load SNP genotype data
snp_data = pd.read_csv(snp_file, index_col=0)
print("=== SNP Genotype Data ===")
print(f"Dimensions: {snp_data.shape}")
print(f"SNPs (rows): {snp_data.index.name if snp_data.index.name else 'Index'}")
print(f"Samples (columns): {list(snp_data.columns[:5])}{'...' if len(snp_data.columns) > 5 else ''}")
print(f"Data types: {snp_data.dtypes.value_counts().to_dict()}")
print(f"Sample values:\n{snp_data.iloc[:3, :3]}")
print(f"Unique genotype values: {sorted(snp_data.iloc[:, 0].unique())}")
print()

# Load bulk omics measurements (methylation)
omics_data = pd.read_csv(omics_file, index_col=0)
print("=== Bulk Omics Measurements (Methylation) ===")
print(f"Dimensions: {omics_data.shape}")
print(f"CpG sites (rows): {omics_data.index.name if omics_data.index.name else 'Index'}")
print(f"Samples (columns): {list(omics_data.columns[:5])}{'...' if len(omics_data.columns) > 5 else ''}")
print(f"Data types: {omics_data.dtypes.value_counts().to_dict()}")
print(f"Value range: {omics_data.min().min():.3f} to {omics_data.max().max():.3f}")
print(f"Sample values:\n{omics_data.iloc[:3, :3]}")
print()

# Load omics positions
positions_data = pd.read_csv(positions_file, index_col=0)
print("=== Omics Positions ===")
print(f"Dimensions: {positions_data.shape}")
print(f"Columns: {list(positions_data.columns)}")
print(f"Data types:\n{positions_data.dtypes}")
print(f"Sample values:\n{positions_data.head()}")
print()

# Load cell type composition
composition_data = pd.read_csv(composition_file, index_col=0)
print("=== Cell Type Composition ===")
print(f"Dimensions: {composition_data.shape}")
print(f"Cell types (columns): {list(composition_data.columns)}")
print(f"Samples (rows): {composition_data.index.name if composition_data.index.name else 'Index'}")
print(f"Data types: {composition_data.dtypes.value_counts().to_dict()}")
print(f"Composition range: {composition_data.min().min():.3f} to {composition_data.max().max():.3f}")
print(f"Sample values:\n{composition_data.head()}")
print()

# Check sample alignment across datasets
print("=== Sample Alignment Check ===")
snp_samples = set(snp_data.columns)
omics_samples = set(omics_data.columns)
composition_samples = set(composition_data.index)

print(f"SNP samples: {len(snp_samples)}")
print(f"Omics samples: {len(omics_samples)}")
print(f"Composition samples: {len(composition_samples)}")

common_samples = snp_samples & omics_samples & composition_samples
print(f"Common samples across all datasets: {len(common_samples)}")

if len(common_samples) < len(snp_samples):
    print(f"Missing samples in omics: {snp_samples - omics_samples}")
    print(f"Missing samples in composition: {snp_samples - composition_samples}")
