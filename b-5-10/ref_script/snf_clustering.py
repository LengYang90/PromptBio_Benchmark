import numpy as np
import pandas as pd
from sklearn.preprocessing import StandardScaler
from sklearn.metrics.pairwise import euclidean_distances
from sklearn.cluster import SpectralClustering
import os
import snf

def affinity_matrix(X, K=20):
    distances = euclidean_distances(X)
    np.fill_diagonal(distances, 0)
    sort_idx = np.argsort(distances, axis=1)
    sigma = np.mean(distances)
    W = np.exp(-distances ** 2 / (2 * sigma ** 2))
    for i in range(W.shape[0]):
        mask = np.ones(W.shape[1], dtype=bool)
        mask[sort_idx[i, :K]] = False
        W[i, mask] = 0
    W = (W + W.T) / 2
    return W

def main():
    task_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    data_dir = os.path.join(task_dir, "data")
    result_dir = os.path.join(task_dir, "ref_answer")
    os.makedirs(result_dir, exist_ok=True)
    expr_file = os.path.join(data_dir, "gene_expression.csv")
    cnv_file = os.path.join(data_dir, "copy_number_variation.csv")
    result_file = os.path.join(result_dir, "snf_cluster_assignments.txt")
    n_clusters = 3

    expr = pd.read_csv(expr_file)
    cnv = pd.read_csv(cnv_file)
    assert expr.shape[0] == cnv.shape[0], "Sample size mismatch between views"

    scaler = StandardScaler()
    expr_scaled = scaler.fit_transform(expr.values)
    cnv_scaled = scaler.fit_transform(cnv.values)

    W_expr = affinity_matrix(expr_scaled, K=20)
    W_cnv = affinity_matrix(cnv_scaled, K=20)

    W_fused = snf.snf([W_expr, W_cnv], K=20, t=20)

    clustering = SpectralClustering(n_clusters=n_clusters, affinity='precomputed', random_state=42)
    labels = clustering.fit_predict(W_fused)

    with open(result_file, "w") as f:
        f.write("Sample\tCluster\n")
        for idx, label in enumerate(labels):
            f.write(f"{idx + 1}\t{label}\n")
    print("SNF clustering results:")
    for idx, label in enumerate(labels):
        print(f"Sample {idx + 1}: Cluster {label}")
    print(f"\nCluster assignments saved to: {result_file}")

if __name__ == "__main__":
    main()
