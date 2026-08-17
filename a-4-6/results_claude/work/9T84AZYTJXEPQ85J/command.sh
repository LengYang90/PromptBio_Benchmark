import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# Load and examine the results file
results_file = '/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-4-6/result_10/toolsgenie_20260516/dna_methylation_results.tsv'
results = pd.read_csv(results_file, sep='\t')

print("=== CELL-TYPE-SPECIFIC ASSOCIATION TESTING RESULTS SUMMARY ===\n")

# File structure verification
print("1. OUTPUT FILE STRUCTURE:")
print(f"   - File path: {results_file}")
print(f"   - Dimensions: {results.shape[0]} rows × {results.shape[1]} columns")
print(f"   - Columns: {list(results.columns)}")
print(f"   - File size: {results.memory_usage(deep=True).sum() / 1024:.1f} KB\n")

# Data completeness check
print("2. DATA COMPLETENESS:")
print(f"   - Missing values: {results.isnull().sum().sum()}")
print(f"   - Unique CpG sites: {results['response'].nunique()}")
print(f"   - Unique cell types: {results['celltype'].nunique()}")
print(f"   - Unique terms: {results['term'].nunique()}\n")

# P-value distribution analysis
print("3. P-VALUE DISTRIBUTION:")
print(f"   - Range: {results['p.value'].min():.6f} - {results['p.value'].max():.6f}")
print(f"   - Mean: {results['p.value'].mean():.6f}")
print(f"   - Median: {results['p.value'].median():.6f}")
print(f"   - Standard deviation: {results['p.value'].std():.6f}")

# Significance analysis
alpha_levels = [0.05, 0.01, 0.001]
print("\n4. SIGNIFICANCE ANALYSIS:")
for alpha in alpha_levels:
    sig_count = (results['p.value'] < alpha).sum()
    print(f"   - p < {alpha}: {sig_count} associations ({sig_count/len(results)*100:.1f}%)")

# Bonferroni correction
bonf_alpha = 0.05 / len(results)
bonf_sig = (results['p.value'] < bonf_alpha).sum()
print(f"   - Bonferroni corrected (p < {bonf_alpha:.2e}): {bonf_sig} associations")

# Term-specific analysis
print("\n5. RESULTS BY TERM TYPE:")
term_summary = results.groupby('term').agg({
    'p.value': ['count', 'mean', 'min'],
    'estimate': ['mean', 'std']
}).round(6)
print(term_summary)

# Cell type analysis
print("\n6. RESULTS BY CELL TYPE:")
celltype_summary = results.groupby('celltype').agg({
    'p.value': ['count', lambda x: (x < 0.05).sum()],
    'estimate': ['mean', 'std']
}).round(6)
celltype_summary.columns = ['count', 'sig_p05', 'est_mean', 'est_std']
print(celltype_summary)

# Top significant associations
print("\n7. TOP 10 MOST SIGNIFICANT ASSOCIATIONS:")
top_sig = results.nsmallest(10, 'p.value')[['response', 'celltype', 'term', 'estimate', 'p.value']]
print(top_sig.to_string(index=False))

# Effect size analysis
print(f"\n8. EFFECT SIZE ANALYSIS:")
print(f"   - Estimate range: {results['estimate'].min():.2e} - {results['estimate'].max():.2e}")
print(f"   - Mean absolute estimate: {np.abs(results['estimate']).mean():.2e}")
print(f"   - Large effects (|estimate| > 1e6): {(np.abs(results['estimate']) > 1e6).sum()}")

print(f"\n=== ANALYSIS COMPLETE ===")
print(f"Summary: Analyzed {results['response'].nunique()} CpG sites across {results['celltype'].nunique()} cell types")
print(f"with {results['term'].nunique()} different terms, generating {len(results)} total associations.")
