import pandas as pd
import numpy as np
from sklearn.linear_model import LinearRegression
from scipy import stats

# Load all required data
snp_file = '/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_2/toolsgenie_20260430/data/Matrix_of_SNP_genotypes.csv'
omics_file = '/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_2/toolsgenie_20260430/data/Matrix_of_bulk_omics_measurements.csv'
celltype_file = '/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_2/toolsgenie_20260430/data/Matrix_of_cell_type_composition.csv'
cis_pairs_file = '/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_2/toolsgenie_20260430/cis_pairs.csv'

# Load datasets
snp_data = pd.read_csv(snp_file, index_col=0)
omics_data = pd.read_csv(omics_file, index_col=0)
celltype_data = pd.read_csv(celltype_file, index_col=0)
cis_pairs = pd.read_csv(cis_pairs_file)

print(f"Loaded data:")
print(f"SNPs: {snp_data.shape}")
print(f"Methylation: {omics_data.shape}")
print(f"Cell types: {celltype_data.shape}")
print(f"Cis pairs: {len(cis_pairs)}")

# Align samples across all datasets
common_samples = list(set(snp_data.columns) & set(omics_data.columns) & set(celltype_data.index))
common_samples.sort()

snp_aligned = snp_data[common_samples].T
omics_aligned = omics_data[common_samples].T
celltype_aligned = celltype_data.loc[common_samples]

print(f"\nAligned {len(common_samples)} samples")
print(f"Cell types: {list(celltype_aligned.columns)}")

# Setup cell-type-specific deconvolution framework
results = []

for _, pair in cis_pairs.iterrows():
    snp_id = pair['SNP']
    cpg_id = pair['CpG']
    
    # Get SNP genotypes and CpG methylation values
    X_snp = snp_aligned[snp_id].values
    y_meth = omics_aligned[cpg_id].values
    
    # For each cell type, model methylation as SNP effect weighted by cell type proportion
    for celltype in celltype_aligned.columns:
        # Get cell type proportions
        cell_props = celltype_aligned[celltype].values
        
        # Create design matrix: SNP genotype, cell type proportion, and interaction
        X = np.column_stack([
            X_snp,  # SNP effect
            cell_props,  # Cell type proportion
            X_snp * cell_props  # SNP-celltype interaction (main effect of interest)
        ])
        
        # Fit linear model: methylation ~ SNP + celltype_prop + SNP*celltype_prop
        model = LinearRegression()
        model.fit(X, y_meth)
        
        # Calculate statistics for the interaction term (SNP effect in this cell type)
        y_pred = model.predict(X)
        residuals = y_meth - y_pred
        mse = np.mean(residuals**2)
        
        # Standard error and t-statistic for interaction coefficient
        X_centered = X - np.mean(X, axis=0)
        var_coef = mse * np.linalg.inv(X_centered.T @ X_centered).diagonal()
        se_interaction = np.sqrt(var_coef[2])  # SE for interaction term
        
        estimate = model.coef_[2]  # Interaction coefficient
        t_stat = estimate / se_interaction
        p_value = 2 * (1 - stats.t.cdf(np.abs(t_stat), len(common_samples) - 3))
        
        results.append({
            'SNP': snp_id,
            'CpG': cpg_id,
            'celltype': celltype,
            'estimate': estimate,
            'statistic': t_stat,
            'p.value': p_value
        })

# Convert to DataFrame and save
results_df = pd.DataFrame(results)
output_file = '/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_2/toolsgenie_20260430/mQTL_results.txt'
results_df.to_csv(output_file, sep='\t', index=False)

print(f"\nGenerated {len(results)} SNP-CpG-celltype associations")
print(f"Results saved to: {output_file}")
print(f"\nSample results:")
print(results_df.head(10))
print(f"\nSummary statistics:")
print(f"Significant associations (p < 0.05): {sum(results_df['p.value'] < 0.05)}")
print(f"Effect size range: {results_df['estimate'].min():.6f} to {results_df['estimate'].max():.6f}")
