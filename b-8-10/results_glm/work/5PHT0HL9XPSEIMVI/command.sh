import pandas as pd
import numpy as np

input_path = '/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/b-8-10/result_79/toolsgenie_20260709/quantile_regression_coefficients_temp.csv'
output_path = '/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/b-8-10/result_79/toolsgenie_20260709/high_il6_specific_taxa.csv'

df = pd.read_csv(input_path)

df['abs_coef_0.9'] = df['coef_tau_0.9'].abs()
df['abs_coef_0.5'] = df['coef_tau_0.5'].abs()

threshold_09 = df['abs_coef_0.9'].quantile(0.75)
threshold_05 = df['abs_coef_0.5'].quantile(0.25)

selected = df[(df['abs_coef_0.9'] > threshold_09) & (df['abs_coef_0.5'] < threshold_05)].copy()
selected['specificity_score'] = selected['abs_coef_0.9'] - selected['abs_coef_0.5']
selected = selected.sort_values('specificity_score', ascending=False)

result = selected[['Taxon', 'coef_tau_0.9']].rename(columns={'coef_tau_0.9': 'Coefficient'})
result.to_csv(output_path, index=False)

print(f"Total number of taxa selected: {len(result)}")
print(f"75th percentile of |coef_tau_0.9|: {threshold_09:.6f}")
print(f"25th percentile of |coef_tau_0.5|: {threshold_05:.6f}")
print("\nSelected taxa (sorted by specificity score descending):")
print(result.to_string(index=False))

print("\n--- Verification: reading output file back ---")
verify = pd.read_csv(output_path)
print(verify.to_string(index=False))
print(f"\nOutput file saved to: {output_path}")
print(f"Rows in output file: {len(verify)}")
