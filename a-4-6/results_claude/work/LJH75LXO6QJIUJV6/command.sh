import pandas as pd
import numpy as np
from scipy import stats
import statsmodels.api as sm

# Load combined dataset
data = pd.read_csv('/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-4-6/result_10/toolsgenie_20260516/combined_dataset.csv', index_col=0)

# First, let's check the actual column names to identify cell types correctly
print("Available columns in combined dataset:")
print(data.columns.tolist())

# Identify columns
cpg_cols = [col for col in data.columns if col.startswith('cg')]
# Update cell type column names based on the actual data structure
# From the history, we know there are 7 cell types, let's identify them correctly
cell_type_cols = [col for col in data.columns if col not in cpg_cols and col != 'disease']
disease_col = 'disease'

print(f"\nIdentified columns:")
print(f"CpG sites: {cpg_cols}")
print(f"Cell types: {cell_type_cols}")
print(f"Disease column: {disease_col}")

# Initialize results list
results = []

# For each CpG site
for cpg in cpg_cols:
    # Prepare data for regression
    y = data[cpg]
    
    # Create design matrix with disease and cell types
    X = pd.DataFrame({
        'intercept': 1,
        'disease': data[disease_col]
    })
    
    # Add cell type main effects
    for cell in cell_type_cols:
        X[cell] = data[cell]
    
    # Add disease * cell type interactions
    for cell in cell_type_cols:
        X[f'disease:{cell}'] = data[disease_col] * data[cell]
    
    # Fit linear model
    model = sm.OLS(y, X).fit()
    
    # Extract results for each term
    for term in X.columns:
        if term == 'intercept':
            continue
            
        # Determine cell type for interaction terms
        if ':' in term:
            celltype = term.split(':')[1]
        elif term in cell_type_cols:
            celltype = term
        else:
            celltype = 'overall'
        
        results.append({
            'response': cpg,
            'celltype': celltype,
            'term': term,
            'estimate': model.params[term],
            'statistic': model.tvalues[term],
            'p.value': model.pvalues[term]
        })

# Convert to DataFrame
results_df = pd.DataFrame(results)

# Save results
results_df.to_csv('/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-4-6/result_10/toolsgenie_20260516/dna_methylation_results.tsv', sep='\t', index=False)

print(f"\nCell-type-specific association testing completed:")
print(f"- Analyzed {len(cpg_cols)} CpG sites")
print(f"- Tested {len(cell_type_cols)} cell types")
print(f"- Generated {len(results_df)} association results")
print(f"- Results saved to dna_methylation_results.tsv")

# Display sample of results
print(f"\nSample of results:")
print(results_df.head(10))
