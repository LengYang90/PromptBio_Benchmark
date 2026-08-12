import pandas as pd
import numpy as np
from scipy.stats import ttest_ind

df = pd.read_csv('/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/b-4-12/result_79/toolsgenie_20260709/data/cognitive_scores.csv')

alz = df.loc[df['Group'] == 'Alzheimers', 'CognitiveScore'].values
ctrl = df.loc[df['Group'] == 'Control', 'CognitiveScore'].values

mean_alz, mean_ctrl = alz.mean(), ctrl.mean()
sd_alz, sd_ctrl = alz.std(ddof=1), ctrl.std(ddof=1)
n1, n2 = len(alz), len(ctrl)

t_stat, p_val = ttest_ind(alz, ctrl, equal_var=False)
mean_diff = mean_alz - mean_ctrl

pooled_sd = np.sqrt(((n1-1)*sd_alz**2 + (n2-1)*sd_ctrl**2) / (n1+n2-2))
cohens_d = mean_diff / pooled_sd

np.random.seed(42)
n_boot = 10000
boot_ds = np.empty(n_boot)
for i in range(n_boot):
    a = np.random.choice(alz, size=n1, replace=True)
    c = np.random.choice(ctrl, size=n2, replace=True)
    sa, sc = a.std(ddof=1), c.std(ddof=1)
    ps = np.sqrt(((n1-1)*sa**2 + (n2-1)*sc**2) / (n1+n2-2))
    boot_ds[i] = (a.mean() - c.mean()) / ps

ci_lower, ci_upper = np.percentile(boot_ds, [2.5, 97.5])

abs_d = abs(cohens_d)
if abs_d < 0.2:
    interp = 'negligible'
elif abs_d < 0.5:
    interp = 'small'
elif abs_d < 0.8:
    interp = 'medium'
else:
    interp = 'large'

results = pd.DataFrame([{
    'Mean_Difference': mean_diff,
    'P_Value': p_val,
    'Cohens_d': cohens_d,
    'CI_Lower': ci_lower,
    'CI_Upper': ci_upper,
    'Effect_Size_Interpretation': interp
}])

out_path = '/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/b-4-12/result_79/toolsgenie_20260709/data/ttest_cohens_d_results.csv'
results.to_csv(out_path, index=False)

print("=== Group Statistics ===")
print(f"Alzheimers: mean={mean_alz:.4f}, sd={sd_alz:.4f}, n={n1}")
print(f"Control:    mean={mean_ctrl:.4f}, sd={sd_ctrl:.4f}, n={n2}")
print("\n=== Results ===")
print(results.to_string(index=False))
