import pandas as pd
import numpy as np

# Load data files
snp_file = '/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_2/toolsgenie_20260430/data/Matrix_of_SNP_genotypes.csv'
omics_file = '/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_2/toolsgenie_20260430/data/Matrix_of_bulk_omics_measurements.csv'
positions_file = '/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_2/toolsgenie_20260430/data/Matrix_of_bulk_omics_positions.csv'
trait_positions_file = '/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_2/toolsgenie_20260430/data/Matrix_of_trait_positions.csv'

# Load datasets
snp_data = pd.read_csv(snp_file, index_col=0)
omics_data = pd.read_csv(omics_file, index_col=0)
omics_positions = pd.read_csv(positions_file, index_col=0)

# Check for SNP positions
try:
    snp_positions = pd.read_csv(trait_positions_file, index_col=0)
    print(f"SNP positions loaded: {snp_positions.shape}")
    print(f"SNP position columns: {list(snp_positions.columns)}")
    print(f"Sample SNP positions:\n{snp_positions.head()}")
except FileNotFoundError:
    print("SNP positions file not found, using placeholder positions")
    snp_positions = pd.DataFrame({'Position': range(100000000, 100000000 + len(snp_data) * 1000000, 1000000)}, 
                                index=snp_data.index)

print(f"\nSNP data: {snp_data.shape[0]} SNPs, {snp_data.shape[1]} samples")
print(f"CpG data: {omics_data.shape[0]} CpG sites, {omics_data.shape[1]} samples")
print(f"CpG positions: {omics_positions.shape}")
print(f"SNP positions: {snp_positions.shape}")

# Define cis-window (1Mb = 1,000,000 bp)
cis_window = 1000000

# Identify cis SNP-CpG pairs
cis_pairs = []
for snp in snp_data.index:
    snp_pos = snp_positions.loc[snp, 'Position']
    for cpg in omics_data.index:
        cpg_pos = omics_positions.loc[cpg, 'Position']
        distance = abs(snp_pos - cpg_pos)
        if distance <= cis_window:
            cis_pairs.append({
                'SNP': snp,
                'CpG': cpg,
                'SNP_pos': snp_pos,
                'CpG_pos': cpg_pos,
                'distance': distance
            })

cis_df = pd.DataFrame(cis_pairs)
print(f"\nIdentified {len(cis_pairs)} cis SNP-CpG pairs within {cis_window/1000000}Mb")
print(f"Distance range: {cis_df['distance'].min()} - {cis_df['distance'].max()} bp")

# Save cis pairs
output_dir = '/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_2/toolsgenie_20260430'
cis_pairs_file = f'{output_dir}/cis_pairs.csv'
cis_df.to_csv(cis_pairs_file, index=False)

print(f"\nCis pairs saved to: {cis_pairs_file}")
print(f"Sample cis pairs:\n{cis_df.head()}")
