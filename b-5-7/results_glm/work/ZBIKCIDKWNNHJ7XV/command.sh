import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from sklearn.metrics.pairwise import rbf_kernel

data_path = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/b-5-7/result_79/toolsgenie_20260709/data/bio_dataset.csv"
csv_out = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/b-5-7/result_79/toolsgenie_20260709/data/laplacian_eigenvalues.csv"
png_out = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/b-5-7/result_79/toolsgenie_20260709/data/laplacian_eigenvalues.png"

X = pd.read_csv(data_path).values
W = rbf_kernel(X, gamma=0.01)
d = W.sum(axis=1)
d_inv_sqrt = 1.0 / np.sqrt(d)
L_sym = np.eye(W.shape[0]) - (d_inv_sqrt[:, None] * W * d_inv_sqrt[None, :])

eigvals, _ = np.linalg.eigh(L_sym)
eigvals = np.sort(eigvals)

gaps = np.diff(eigvals)
optimal_idx = int(np.argmax(gaps))
optimal_k = optimal_idx + 1

pd.DataFrame({"index": np.arange(len(eigvals)), "eigenvalue": eigvals}).to_csv(csv_out, index=False)

plt.figure(figsize=(10, 6), dpi=150)
plt.plot(np.arange(len(eigvals)), eigvals, marker='o', markersize=3, linewidth=1)
plt.axvline(x=optimal_idx, color='r', linestyle='--', label=f'Largest eigengap at index {optimal_idx}')
plt.annotate(f'Optimal k = {optimal_k}', xy=(optimal_idx, eigvals[optimal_idx]),
             xytext=(optimal_idx + 5, eigvals[optimal_idx] + 0.02),
             arrowprops=dict(arrowstyle='->', color='red'),
             fontsize=11, color='red')
plt.xlabel('Eigenvalue Index')
plt.ylabel('Eigenvalue')
plt.title('Laplacian Eigenvalues (Spectral Clustering)')
plt.grid(True, alpha=0.3)
plt.legend()
plt.tight_layout()
plt.savefig(png_out)
plt.close()

print("=== Sorted Eigenvalues ===")
print(eigvals)
print("\n=== Eigengaps ===")
print(gaps)
print(f"\n=== Optimal number of clusters (k) = {optimal_k} ===")
print(f"Largest eigengap at index {optimal_idx} (between eigenvalue {optimal_idx} and {optimal_idx+1})")
