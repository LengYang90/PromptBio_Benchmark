import numpy as np
import pandas as pd
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import QuantileRegressor

# 1. Load data
data_path = '/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/b-8-10/result_79/toolsgenie_20260709/data/microbiome_il6_data.csv'
df = pd.read_csv(data_path)

# 2. Separate features and target
taxa_cols = [f'Taxon_{i:03d}' for i in range(1, 501)]
X = df[taxa_cols].values.astype(float)
y = df['IL6'].values.astype(float)
D = X.shape[1]

# 3. Multiplicative replacement for zeros, then CLR
X_replaced = X.copy()
for i in range(X_replaced.shape[0]):
    row = X_replaced[i]
    zero_mask = row <= 0
    n_zeros = int(zero_mask.sum())
    if n_zeros > 0:
        n_nz = D - n_zeros
        min_nz = row[~zero_mask].min()
        delta = (n_nz / D) * min_nz  # proportional to count of non-zero values
        row[zero_mask] = delta
        row /= row.sum()  # renormalize so row sums to 1

log_X = np.log(X_replaced)
clr_X = log_X - log_X.mean(axis=1, keepdims=True)

# 4. Standardize CLR features
X_scaled = StandardScaler().fit_transform(clr_X)

# 5. Fit QuantileRegressor at tau=0.1, 0.5, 0.9
# Note: sklearn's QuantileRegressor supports L1 penalty only (no l1_ratio for elastic net)
# Using alpha=0.01 for regularization strength and solver='highs'
taus = [0.1, 0.5, 0.9]
coefs = {}
for tau in taus:
    model = QuantileRegressor(quantile=tau, alpha=0.01, solver='highs')
    model.fit(X_scaled, y)
    coefs[tau] = model.coef_
    # 6. Print number of non-zero coefficients
    n_nonzero = int(np.sum(np.abs(model.coef_) > 1e-10))
    print(f"tau={tau}: {n_nonzero} non-zero coefficients")

# 7. Print top 20 taxa by absolute coefficient value for tau=0.9
coef_09 = coefs[0.9]
top20_idx = np.argsort(np.abs(coef_09))[::-1][:20]
print("\nTop 20 taxa by absolute coefficient value (tau=0.9):")
for idx in top20_idx:
    print(f"{taxa_cols[idx]}: {coef_09[idx]:.6f}")

# 8. Save all three sets of coefficients to a temporary CSV
coef_df = pd.DataFrame({
    'Taxon': taxa_cols,
    'coef_tau_0.1': coefs[0.1],
    'coef_tau_0.5': coefs[0.5],
    'coef_tau_0.9': coefs[0.9],
})
output_path = '/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/b-8-10/result_79/toolsgenie_20260709/quantile_regression_coefficients_temp.csv'
coef_df.to_csv(output_path, index=False)
print(f"\nCoefficients saved to: {output_path}")
