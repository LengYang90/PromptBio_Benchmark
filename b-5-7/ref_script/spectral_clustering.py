import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from sklearn.metrics.pairwise import rbf_kernel
from sklearn.cluster import SpectralClustering
from sklearn.metrics import silhouette_score

def compute_laplacian_eigenvalues(X, gamma=1.0):
    W = rbf_kernel(X, gamma=gamma)
    D = np.diag(W.sum(axis=1))
    L = D - W
    eigvals = np.linalg.eigvalsh(L)
    eigvals = np.sort(eigvals)
    return eigvals

def plot_laplacian_eigenvalues(eigvals, output_path, optimal_k=None, eigengap=None):
    x = np.arange(1, len(eigvals) + 1)
    plt.figure(figsize=(8, 5))
    plt.plot(x, eigvals, marker='o')

    if optimal_k is not None and eigengap is not None and 1 <= optimal_k < len(eigvals):
        x1, x2 = optimal_k, optimal_k + 1
        y1, y2 = eigvals[x1 - 1], eigvals[x2 - 1]
        plt.plot([x1, x2], [y1, y2], color='red', linewidth=2.5, label='Largest eigengap')
        xm, ym = (x1 + x2) / 2, (y1 + y2) / 2
        plt.annotate(
            f"eigengap={eigengap:.4f}",
            xy=(xm, ym),
            xytext=(10, 12),
            textcoords='offset points',
            color='red',
            fontsize=10
        )
        plt.legend()

    plt.title('Sorted Eigenvalues of the Laplacian Matrix')
    plt.xlabel('Index')
    plt.ylabel('Eigenvalue')
    plt.tight_layout()
    plt.savefig(output_path)
    plt.close()
    print(f"Laplacian eigenvalues plot saved to: {output_path}")

def estimate_optimal_clusters(eigvals, max_clusters=10):
    eigengaps = np.diff(eigvals[:max_clusters+1])
    optimal_k = int(np.argmax(eigengaps)) + 1
    return optimal_k, eigengaps

def spectral_clustering_and_silhouette(X, n_clusters, gamma=1.0, random_state=42):
    sc = SpectralClustering(
        n_clusters=n_clusters,
        affinity='rbf',
        gamma=gamma,
        assign_labels='kmeans',
        random_state=random_state
    )
    labels = sc.fit_predict(X)
    score = silhouette_score(X, labels)
    return labels, score

def main():
    task_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    data_file = os.path.join(task_dir, "data", "bio_dataset.csv")
    result_dir = os.path.join(task_dir, "ref_answer")
    os.makedirs(result_dir, exist_ok=True)
    eigvals_csv_file = os.path.join(result_dir, "laplacian_eigenvalues.csv")
    eigvals_plot_file = os.path.join(result_dir, "laplacian_eigenvalues.png")

    df = pd.read_csv(data_file)
    X = df.values

    eigvals = compute_laplacian_eigenvalues(X, gamma=0.01)
    pd.DataFrame({"eigenvalue": eigvals}).to_csv(eigvals_csv_file, index_label="index")
    print(f"Laplacian eigenvalues saved to: {eigvals_csv_file}")

    optimal_k, eigengaps = estimate_optimal_clusters(eigvals, max_clusters=10)
    selected_eigengap = eigengaps[optimal_k - 1]

    plot_laplacian_eigenvalues(
        eigvals,
        eigvals_plot_file,
        optimal_k=optimal_k,
        eigengap=selected_eigengap
    )

    print("\nFirst 15 Laplacian eigenvalues:")
    for i, val in enumerate(eigvals[:15]):
        print(f"  Eigenvalue {i+1}: {val:.6f}")

    print(f"\nEigengaps (first 10): {eigengaps}")
    print(f"Estimated optimal number of clusters (by eigengap heuristic): {optimal_k}")

    print("\nSilhouette scores for spectral clustering (k=2..6):")
    best_score = -1
    best_k = None
    for k in range(2, 7):
        labels, score = spectral_clustering_and_silhouette(X, n_clusters=k, gamma=1.0, random_state=42)
        print(f"  k={k}: silhouette score = {score:.4f}")
        if score > best_score:
            best_score = score
            best_k = k

    print(f"\nBest silhouette score: {best_score:.4f} (k={best_k})")
    print(f"\nFinal recommendation for number of clusters: {optimal_k} (eigengap), {best_k} (silhouette)")

if __name__ == "__main__":
    main()
