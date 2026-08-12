import numpy as np
import pandas as pd
from scipy.spatial.distance import pdist, squareform
from sklearn.cluster import KMeans

base = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/b-5-10/result_79/toolsgenie_20260709/data"
ge = pd.read_csv(base + "/gene_expression.csv", index_col=0).values
cnv = pd.read_csv(base + "/copy_number_variation.csv", index_col=0).values

n = ge.shape[0]
K = 20
T = 20

def status_and_kernel(X, K):
    D = squareform(pdist(X, metric='euclidean'))
    D_sorted = np.sort(D, axis=1)
    mu = D_sorted[:, :K].mean(axis=1)
    mu[mu == 0] = 1e-10
    W = np.exp(-(D**2) / (mu[:, None] * mu[None, :]))
    P = W.copy()
    Q = np.zeros_like(W)
    idx = np.argsort(D, axis=1)[:, :K]
    for i in range(D.shape[0]):
        Q[i, idx[i]] = W[i, idx[i]]
    rs = Q.sum(axis=1, keepdims=True)
    rs[rs == 0] = 1e-10
    Q = Q / rs
    return P, Q

P1, Q1 = status_and_kernel(ge, K)
P2, Q2 = status_and_kernel(cnv, K)

def normalize(P):
    P = P.copy()
    np.fill_diagonal(P, 0)
    s = P.sum(axis=1, keepdims=True)
    s[s == 0] = 1e-10
    P = P / s
    np.fill_diagonal(P, 0.5)
    return P

P1_old, P2_old = P1.copy(), P2.copy()
for t in range(T):
    P1_new = Q1 @ P2_old @ Q1.T
    P2_new = Q2 @ P1_old @ Q2.T
    P1_old = normalize(P1_new)
    P2_old = normalize(P2_new)

F = (P1_old + P2_old) / 2.0

deg = F.sum(axis=1)
deg[deg == 0] = 1e-10
D_inv_sqrt = np.diag(1.0 / np.sqrt(deg))
L = np.eye(n) - D_inv_sqrt @ F @ D_inv_sqrt
eigvals, eigvecs = np.linalg.eigh(L)
emb = eigvecs[:, :3]
norm = np.linalg.norm(emb, axis=1, keepdims=True)
norm[norm == 0] = 1e-10
emb = emb / norm
km = KMeans(n_clusters=3, random_state=42, n_init=10)
labels = km.fit_predict(emb)

out = base + "/snf_cluster_assignments.txt"
with open(out, 'w') as f:
    f.write("Sample\tCluster\n")
    for i in range(n):
        f.write(f"Sample_{i+1}\t{int(labels[i])}\n")

unique, counts = np.unique(labels, return_counts=True)
print("Cluster sizes:")
for u, c in zip(unique, counts):
    print(f"  Cluster {u}: {c}")
print("\nPreview of output file:")
with open(out) as f:
    for i, line in enumerate(f):
        if i < 10:
            print(line.rstrip())
print("\nOutput saved to:", out)
