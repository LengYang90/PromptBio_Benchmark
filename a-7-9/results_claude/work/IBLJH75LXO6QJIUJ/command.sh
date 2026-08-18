import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# Load data
merip_data = pd.read_excel('/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-9/result_10/toolsgenie_20260516/data/MeRIP_RNA_result.xlsx')
proteomic_data = pd.read_excel('/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-9/result_10/toolsgenie_20260516/data/Proteomic_data.xlsx')

# Extract log2FC values
proteomic_log2fc = proteomic_data['log2FC'].dropna()
m6a_log2fc = merip_data['m_log2FC'].dropna()
gene_expr_log2fc = merip_data['g_log2FC'].dropna()
combined_log2fc = pd.concat([proteomic_log2fc, m6a_log2fc, gene_expr_log2fc])

# Create 2x2 panel plot
fig, axes = plt.subplots(2, 2, figsize=(12, 10))
fig.suptitle('Effect Size (log2FC) Distributions', fontsize=16, fontweight='bold')

# Panel 1: Proteomic log2FC
axes[0,0].hist(proteomic_log2fc, bins=50, alpha=0.7, color='blue', edgecolor='black')
axes[0,0].set_title('Proteomic log2FC', fontweight='bold')
axes[0,0].set_xlabel('log2FC')
axes[0,0].set_ylabel('Frequency')
axes[0,0].grid(True, alpha=0.3)

# Panel 2: m6A methylation log2FC
axes[0,1].hist(m6a_log2fc, bins=50, alpha=0.7, color='red', edgecolor='black')
axes[0,1].set_title('m6A Methylation log2FC', fontweight='bold')
axes[0,1].set_xlabel('log2FC')
axes[0,1].set_ylabel('Frequency')
axes[0,1].grid(True, alpha=0.3)

# Panel 3: Gene expression log2FC
axes[1,0].hist(gene_expr_log2fc, bins=50, alpha=0.7, color='green', edgecolor='black')
axes[1,0].set_title('Gene Expression log2FC', fontweight='bold')
axes[1,0].set_xlabel('log2FC')
axes[1,0].set_ylabel('Frequency')
axes[1,0].grid(True, alpha=0.3)

# Panel 4: Combined log2FC
axes[1,1].hist(combined_log2fc, bins=50, alpha=0.7, color='purple', edgecolor='black')
axes[1,1].set_title('Combined log2FC', fontweight='bold')
axes[1,1].set_xlabel('log2FC')
axes[1,1].set_ylabel('Frequency')
axes[1,1].grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig('/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-9/result_10/toolsgenie_20260516/effect_size_distribution.png', dpi=300, bbox_inches='tight')
plt.show()
