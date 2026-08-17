import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# Load data
merip_data = pd.read_excel('/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-9/result_10/toolsgenie_20260516/data/MeRIP_RNA_result.xlsx')
proteomic_data = pd.read_excel('/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-9/result_10/toolsgenie_20260516/data/Proteomic_data.xlsx')

# Extract p-values
proteomic_pvals = proteomic_data['p.value'].dropna()
m6a_pvals = merip_data['m_pvalue'].dropna()
gene_expr_pvals = merip_data['g_pvalue'].dropna()
combined_pvals = pd.concat([proteomic_pvals, m6a_pvals, gene_expr_pvals])

# Create 2x2 panel plot
fig, axes = plt.subplots(2, 2, figsize=(12, 10))
fig.suptitle('P-value Distributions', fontsize=16, fontweight='bold')

# Panel 1: Proteomic p-values
axes[0,0].hist(proteomic_pvals, bins=50, alpha=0.7, color='blue', edgecolor='black')
axes[0,0].set_title('Proteomic P-values', fontweight='bold')
axes[0,0].set_xlabel('P-value')
axes[0,0].set_ylabel('Frequency')
axes[0,0].grid(True, alpha=0.3)

# Panel 2: m6A methylation p-values
axes[0,1].hist(m6a_pvals, bins=50, alpha=0.7, color='red', edgecolor='black')
axes[0,1].set_title('m6A Methylation P-values', fontweight='bold')
axes[0,1].set_xlabel('P-value')
axes[0,1].set_ylabel('Frequency')
axes[0,1].grid(True, alpha=0.3)

# Panel 3: Gene expression p-values
axes[1,0].hist(gene_expr_pvals, bins=50, alpha=0.7, color='green', edgecolor='black')
axes[1,0].set_title('Gene Expression P-values', fontweight='bold')
axes[1,0].set_xlabel('P-value')
axes[1,0].set_ylabel('Frequency')
axes[1,0].grid(True, alpha=0.3)

# Panel 4: Combined p-values
axes[1,1].hist(combined_pvals, bins=50, alpha=0.7, color='purple', edgecolor='black')
axes[1,1].set_title('Combined P-values', fontweight='bold')
axes[1,1].set_xlabel('P-value')
axes[1,1].set_ylabel('Frequency')
axes[1,1].grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig('/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-9/result_10/toolsgenie_20260516/p_value_distribution.png', dpi=300, bbox_inches='tight')
plt.show()
