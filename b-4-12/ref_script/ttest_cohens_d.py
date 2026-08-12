## Description:
##      This script compares cognitive test scores between Alzheimer's patients
##      and controls for benchmark b-4-12. It performs an independent t-test,
##      computes Cohen's d effect size with 95% CI via bootstrapping, and
##      interprets the effect size (small/medium/large). Results include mean
##      difference, p-value, Cohen's d, and confidence interval bounds.

import os
import numpy as np
import pandas as pd
from scipy import stats
import warnings
warnings.filterwarnings("ignore")

def load_data(data_file):
    print(f"Loading data from: {os.path.abspath(data_file)}")
    df = pd.read_csv(data_file)
    print(f"Dataset shape: {df.shape}")
    
    controls = df[df['Group'] == 'Control']['CognitiveScore'].values
    alzheimers = df[df['Group'] == 'Alzheimers']['CognitiveScore'].values
    
    print(f"\nGroup statistics:")
    print(f"  Controls: n={len(controls)}, mean={np.mean(controls):.2f}, SD={np.std(controls, ddof=1):.2f}")
    print(f"  Alzheimers: n={len(alzheimers)}, mean={np.mean(alzheimers):.2f}, SD={np.std(alzheimers, ddof=1):.2f}")
    
    return controls, alzheimers

def perform_ttest(controls, alzheimers):
    print(f"\nPerforming independent t-test...")
    
    t_stat, p_val = stats.ttest_ind(controls, alzheimers)
    mean_diff = np.mean(controls) - np.mean(alzheimers)
    
    print(f"  t-statistic: {t_stat:.4f}")
    print(f"  p-value: {p_val:.4e}")
    print(f"  Mean difference: {mean_diff:.2f}")
    
    return t_stat, p_val, mean_diff

def calculate_cohens_d_bootstrap(controls, alzheimers, n_bootstrap=10000):
    print(f"\nCalculating Cohen's d with 95% CI (bootstrapping)...")
    
    # Calculate observed Cohen's d
    mean_diff = np.mean(controls) - np.mean(alzheimers)
    pooled_std = np.sqrt(((len(controls) - 1) * np.var(controls, ddof=1) + 
                          (len(alzheimers) - 1) * np.var(alzheimers, ddof=1)) / 
                         (len(controls) + len(alzheimers) - 2))
    cohens_d = mean_diff / pooled_std
    
    # Bootstrap for CI
    np.random.seed(42)
    bootstrap_d = []
    
    for _ in range(n_bootstrap):
        # Resample with replacement
        boot_controls = np.random.choice(controls, size=len(controls), replace=True)
        boot_alzheimers = np.random.choice(alzheimers, size=len(alzheimers), replace=True)
        
        # Calculate Cohen's d
        boot_mean_diff = np.mean(boot_controls) - np.mean(boot_alzheimers)
        boot_pooled_std = np.sqrt(((len(boot_controls) - 1) * np.var(boot_controls, ddof=1) + 
                                   (len(boot_alzheimers) - 1) * np.var(boot_alzheimers, ddof=1)) / 
                                  (len(boot_controls) + len(boot_alzheimers) - 2))
        boot_d = boot_mean_diff / boot_pooled_std
        bootstrap_d.append(boot_d)
    
    # Calculate 95% CI (percentile method)
    ci_low = np.percentile(bootstrap_d, 2.5)
    ci_high = np.percentile(bootstrap_d, 97.5)
    
    # Interpret effect size
    if abs(cohens_d) < 0.2:
        interpretation = "Negligible"
    elif abs(cohens_d) < 0.5:
        interpretation = "Small"
    elif abs(cohens_d) < 0.8:
        interpretation = "Medium"
    else:
        interpretation = "Large"
    
    print(f"  Cohen's d: {cohens_d:.3f}")
    print(f"  95% CI: [{ci_low:.3f}, {ci_high:.3f}]")
    print(f"  Effect size interpretation: {interpretation}")
    
    return cohens_d, ci_low, ci_high, interpretation

def save_results(mean_diff, p_val, cohens_d, ci_low, ci_high, interpretation, output_dir):
    os.makedirs(output_dir, exist_ok=True)
    
    results_df = pd.DataFrame({
        'Mean_Difference': [round(mean_diff, 3)],
        'P_Value': [f"{p_val:.4e}" if p_val < 0.0001 else round(p_val, 4)],
        'Cohens_d': [round(cohens_d, 3)],
        'CI_Lower': [round(ci_low, 3)],
        'CI_Upper': [round(ci_high, 3)],
        'Effect_Size_Interpretation': [interpretation]
    })
    
    file_path = os.path.join(output_dir, 'ttest_cohens_d_results.csv')
    results_df.to_csv(file_path, index=False)
    print(f"\nResults saved to: {os.path.abspath(file_path)}")

def main():
    task_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    output_dir = os.path.join(task_dir, "ref_answer")
    data_file = os.path.join(task_dir, "data", "cognitive_scores.csv")
    controls, alzheimers = load_data(data_file)
    
    t_stat, p_val, mean_diff = perform_ttest(controls, alzheimers)
    cohens_d, ci_low, ci_high, interpretation = calculate_cohens_d_bootstrap(controls, alzheimers)
    save_results(mean_diff, p_val, cohens_d, ci_low, ci_high, interpretation, output_dir)
    
    print(f"\n{'='*80}")
    print("t-test with Cohen's d Complete!")
    print(f"  Mean difference: {mean_diff:.2f}, p={p_val:.4e}")
    print(f"  Cohen's d: {cohens_d:.3f} [{ci_low:.3f}, {ci_high:.3f}] - {interpretation}")
    print(f"{'='*80}")

if __name__ == "__main__":
    main()

