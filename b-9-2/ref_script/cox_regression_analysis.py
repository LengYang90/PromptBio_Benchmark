"""
Cox Proportional Hazards Model Analysis
========================================
Fit a Cox model to assess the effect of gene signature score (low/medium/high) 
on progression-free survival, adjusting for age and sex.
Report hazard ratios and 95% CIs for gene signature score.
"""

import os
import pandas as pd
import numpy as np
from lifelines import CoxPHFitter
import warnings
warnings.filterwarnings('ignore')

task_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Load the data
data_path = os.path.join(task_dir, "data", "simulated_cox_data.csv")
df = pd.read_csv(data_path)

# Prepare data for Cox regression
# Create dummy variables for gene_score (categorical variable)
# Using 'low' as reference category
df_cox = df[['pfs_time', 'progression_event', 'age', 'sex']].copy()

# Create dummy variables for gene_score with 'low' as reference
gene_dummies = pd.get_dummies(df['gene_score'], prefix='gene_score', drop_first=False)
df_cox['gene_score_medium'] = gene_dummies['gene_score_medium'].astype(int)
df_cox['gene_score_high'] = gene_dummies['gene_score_high'].astype(int)

# Fit Cox proportional hazards model
cph = CoxPHFitter()
cph.fit(df_cox, duration_col='pfs_time', event_col='progression_event')

# Extract hazard ratios and 95% CIs for gene signature score only
summary_df = cph.summary
gene_score_results = summary_df[summary_df.index.str.contains('gene_score')].copy()

# Create results table
results_table = pd.DataFrame({
    'Gene_Score': ['Medium vs Low', 'High vs Low'],
    'Hazard_Ratio': [np.exp(gene_score_results.loc['gene_score_medium', 'coef']),
                     np.exp(gene_score_results.loc['gene_score_high', 'coef'])],
    'CI_Lower_95': [np.exp(gene_score_results.loc['gene_score_medium', 'coef lower 95%']),
                    np.exp(gene_score_results.loc['gene_score_high', 'coef lower 95%'])],
    'CI_Upper_95': [np.exp(gene_score_results.loc['gene_score_medium', 'coef upper 95%']),
                    np.exp(gene_score_results.loc['gene_score_high', 'coef upper 95%'])],
    'P_value': [gene_score_results.loc['gene_score_medium', 'p'],
                gene_score_results.loc['gene_score_high', 'p']]
})

# Display results
print("=" * 80)
print("Cox Regression: Gene Signature Score Effect on Progression-Free Survival")
print("(Adjusted for age and sex)")
print("=" * 80)
print("\nHazard Ratios and 95% Confidence Intervals:\n")
for idx, row in results_table.iterrows():
    print(f"{row['Gene_Score']}:")
    print(f"  HR = {row['Hazard_Ratio']:.3f}, 95% CI: ({row['CI_Lower_95']:.3f}, {row['CI_Upper_95']:.3f}), p = {row['P_value']:.4f}")

# Save results to ref folder
output_path = os.path.join(task_dir, "ref_answer", "cox_regression_results.csv")
results_table.to_csv(output_path, index=False)
print(f"\n✓ Results saved to: {output_path}")

