import numpy as np
import pandas as pd
from sklearn.preprocessing import StandardScaler

# 1. Load data
data_path = '/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/b-8-10/result_79/toolsgenie_20260709/data/microbiome_il6_data.csv'
df = pd.read_csv(data_path)

# 2. Separate features and target
taxa_cols = [f'Taxon_{i:03d}' for i in range(1, 501)]
X = df[taxa_cols].values.astype(float)
y = df['IL6'].values.astype(float)
D = X.shape[1]

# 3. CLR with multiplicative replacement for zeros
X_replaced = X.copy()
for i in range(X_replaced.shape[0]):
    row = X_replaced[i]
    zero_mask = row <= 0
    n_zeros = int(zero_mask.sum())
    if n_zeros > 0:
        n_nz = D - n_zeros
        min_nz = row[~zero_mask].min()
        delta = (n_nz / D) * min_nz
        row[zero_mask] = delta
        row /= row.sum()
log_X = np.log(X_replaced)
clr_X = log_X - log_X.mean(axis=1, keepdims=True)

# 4. Standardize CLR features
X_scaled = StandardScaler().fit_transform(clr_X)

# 5. Add intercept column (column of ones)
n = X_scaled.shape[0]
X_design = np.hstack([np.ones((n, 1)), X_scaled])

# Elastic net penalized quantile regression via proximal gradient descent
def fit_enet_qr(X, y, tau, alpha=0.01, l1_ratio=0.5, lr=0.001, max_iter=10000, tol=1e-6):
    n, p = X.shape
    beta = np.zeros(p)
    for it in range(max_iter):
        residual = y - X @ beta
        # subgradient of pinball loss w.r.t. beta: -X^T @ g, g_i in {tau, -(1-tau), 0}
        g = np.where(residual > 0, -tau, np.where(residual < 0, (1.0 - tau), 0.0))
        grad = X.T @ g / n  # mean gradient for numerical stability
        # gradient step
        z = beta - lr * grad
        # proximal operator (elastic net): exclude intercept (index 0) from penalty
        beta_new = z.copy()
        beta_new[1:] = np.sign(z[1:]) * np.maximum(np.abs(z[1:]) - lr * alpha * l1_ratio, 0.0)
        beta_new[1:] = beta_new[1:] / (1.0 + lr * alpha * (1.0 - l1_ratio))
        diff = np.max(np.abs(beta_new - beta))
        beta = beta_new
        if diff < tol:
            break
    # final loss
    residual = y - X @ beta
    pinball = np.mean(np.where(residual >= 0, tau * residual, (tau - 1.0) * residual))
    penalty = alpha * (l1_ratio * np.sum(np.abs(beta[1:])) + (1.0 - l1_ratio) * 0.5 * np.sum(beta[1:] ** 2))
    loss = pinball + penalty
    return beta, loss, it + 1

taus = [0.1, 0.5, 0.9]
coefs = {}
for tau in taus:
    beta, loss, n_iter = fit_enet_qr(X_design, y, tau)
    coefs[tau] = beta
    n_nonzero = int(np.sum(np.abs(beta[1:]) > 1e-10))
    print(f"tau={tau}: {n_nonzero} non-zero coefficients, final loss={loss:.6f}, iterations={n_iter}")

# 7. Top 20 taxa by absolute coefficient for tau=0.9
coef_09 = coefs[0.9][1:]
top20_idx = np.argsort(np.abs(coef_09))[::-1][:20]
print("\nTop 20 taxa by absolute coefficient value (tau=0.9):")
for idx in top20_idx:
    print(f"{taxa_cols[idx]}: {coef_09[idx]:.6f}")

# 8. Save all coefficients to CSV
coef_df = pd.DataFrame({
    'Taxon': taxa_cols,
    'coef_tau_0.1': coefs[0.1][1:],
    'coef_tau_0.5': coefs[0.5][1:],
    'coef_tau_0.9': coefs[0.9][1:],
})
output_path = '/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/b-8-10/result_79/toolsgenie_20260709/quantile_regression_coefficients_temp.csv'
coef_df.to_csv(output_path, index=False)
print(f"\nCoefficients saved to: {output_path}")
