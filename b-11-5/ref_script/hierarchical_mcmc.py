import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import warnings
warnings.filterwarnings('ignore')

try:
    import pymc as pm
    import arviz as az
    PYMC_AVAILABLE = True
except ImportError:
    PYMC_AVAILABLE = False
    raise ImportError("PyMC not available")

def main():
    task_dir = os.path.dirname(os.path.dirname(__file__))

    data_file = os.path.join(task_dir, "data", "gene_expression_data.csv")
    summary_file = os.path.join(task_dir, "ref_answer", "hierarchical_model_summary.txt")
    random_effects_variance_file = os.path.join(task_dir, "ref_answer", "random_effects_variance_posterior.csv")
    trace_plot_file = os.path.join(task_dir, "ref_answer", "trace_plot.png")

    df = pd.read_csv(data_file)
    unique_patients = df['Patient_ID'].unique()
    unique_times = sorted(df['Time_Point'].unique())

    patient_to_idx = {pid: idx for idx, pid in enumerate(unique_patients)}
    time_to_idx = {t: idx for idx, t in enumerate(unique_times)}

    patient_idx = df['Patient_ID'].map(patient_to_idx).values
    time_idx = df['Time_Point'].map(time_to_idx).values
    y = df['Gene_Expression'].values

    n_patients = len(unique_patients)
    n_times = len(unique_times)

    with pm.Model() as hierarchical_model:
        sigma_patient = pm.HalfNormal('sigma_patient', sigma=2.0)
        patient_intercepts = pm.Normal('patient_intercepts',
                                       mu=0,
                                       sigma=sigma_patient,
                                       shape=n_patients)
        time_effects_raw = pm.Normal('time_effects_raw',
                                     mu=0,
                                     sigma=5,
                                     shape=n_times)
        time_effects = pm.Deterministic('time_effects',
                                        time_effects_raw - time_effects_raw[0])
        intercept = pm.Normal('intercept', mu=5, sigma=2)
        sigma_error = pm.HalfNormal('sigma_error', sigma=1.0)
        mu = (intercept +
              patient_intercepts[patient_idx] +
              time_effects[time_idx])
        y_obs = pm.Normal('y_obs', mu=mu, sigma=sigma_error, observed=y)
        trace = pm.sample(2000, tune=1000, return_inferencedata=True,
                         random_seed=42, progressbar=True)

    summary = az.summary(trace, var_names=['intercept', 'time_effects',
                                            'sigma_patient', 'sigma_error'])

    sigma_patient_samples = trace.posterior['sigma_patient'].values.flatten()
    sigma_patient_squared_samples = sigma_patient_samples ** 2

    random_effects_var_mean = np.mean(sigma_patient_squared_samples)
    random_effects_var_median = np.median(sigma_patient_squared_samples)
    random_effects_var_ci_lower = np.percentile(sigma_patient_squared_samples, 2.5)
    random_effects_var_ci_upper = np.percentile(sigma_patient_squared_samples, 97.5)

    with open(summary_file, "w") as f:
        f.write("Hierarchical Bayesian Model Summary\n")
        f.write("=" * 70 + "\n\n")
        f.write("Model Structure:\n")
        f.write(f"  Fixed effects: {n_times} time points\n")
        f.write(f"  Random effects: {n_patients} patient-level intercepts\n")
        f.write(f"  Observations: {len(y)}\n\n")
        f.write("Posterior Summary:\n")
        f.write(str(summary))
        f.write("\n\n")
        f.write("Random Effects Variance (sigma_patient^2) Posterior:\n")
        f.write(f"  Mean: {random_effects_var_mean:.4f}\n")
        f.write(f"  Median: {random_effects_var_median:.4f}\n")
        f.write(f"  95% Credible Interval: [{random_effects_var_ci_lower:.4f}, {random_effects_var_ci_upper:.4f}]\n")
    print(f"Summary written to {summary_file}")

    variance_df = pd.DataFrame({
        'sigma_patient_squared': sigma_patient_squared_samples,
        'sigma_patient': sigma_patient_samples
    })
    variance_df.to_csv(random_effects_variance_file, index=False)
    print(f"Random effects variance posterior written to {random_effects_variance_file}")

    axes = az.plot_trace(trace, var_names=['intercept', 'time_effects',
                                           'sigma_patient', 'sigma_error'],
                         compact=True, figsize=(12, 10))
    plt.tight_layout()
    plt.savefig(trace_plot_file, dpi=300, bbox_inches='tight')
    plt.close()
    print(f"Trace plot written to {trace_plot_file}")

if __name__ == "__main__":
    main()
