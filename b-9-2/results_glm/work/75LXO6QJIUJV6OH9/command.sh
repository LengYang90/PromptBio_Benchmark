import subprocess
subprocess.check_call(['pip', 'install', 'lifelines'])

import pandas as pd
from lifelines import CoxPHFitter

data_path = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/b-9-2/result_79/toolsgenie_20260709/data/simulated_cox_data.csv"
output_path = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/b-9-2/result_79/toolsgenie_20260709/data/cox_regression_results.csv"

df = pd.read_csv(data_path)
df['gene_score'] = pd.Categorical(df['gene_score'], categories=['low', 'medium', 'high'])

dummies = pd.get_dummies(df['gene_score'], prefix='gene_score', drop_first=True, dtype=float)
model_df = pd.concat([df[['pfs_time', 'progression_event', 'age', 'sex']], dummies], axis=1)

cph = CoxPHFitter()
cph.fit(model_df, duration_col='pfs_time', event_col='progression_event')

print("=== MODEL SUMMARY ===")
print(cph.summary)
print("\n=== CONCORDANCE INDEX ===")
print(cph.concordance_index_)

summary = cph.summary
rows = []
for cov, label in [('gene_score_medium', 'medium_vs_low'), ('gene_score_high', 'high_vs_low')]:
    r = summary.loc[cov]
    rows.append({
        'Gene_Score': label,
        'Hazard_Ratio': r['exp(coef)'],
        'CI_Lower_95': r['exp(coef) lower 95%'],
        'CI_Upper_95': r['exp(coef) upper 95%'],
        'P_value': r['p']
    })

results_df = pd.DataFrame(rows)
results_df.to_csv(output_path, index=False)

print("\n=== RESULTS DATAFRAME (rounded to 4 decimals for display) ===")
print(results_df.round(4).to_string(index=False))

print("\n=== SAVED CSV CONTENT (full precision) ===")
print(pd.read_csv(output_path).to_string(index=False))
