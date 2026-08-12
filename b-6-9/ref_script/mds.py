import os
import numpy as np
import pandas as pd
from sklearn.preprocessing import StandardScaler
from sklearn.manifold import MDS
from scipy.spatial.distance import pdist, squareform

task_dir = os.path.dirname(os.path.dirname(__file__))
os.makedirs(os.path.join(task_dir, "ref_answer"), exist_ok=True)

def calculate_distance_ratio(X_2d, groups):
    unique_groups = np.unique(groups)
    distances_2d = squareform(pdist(X_2d))

    within_distances = []
    for group in unique_groups:
        group_indices = np.where(groups == group)[0]
        if len(group_indices) > 1:
            group_distances = distances_2d[np.ix_(group_indices, group_indices)]
            triu_indices = np.triu_indices(len(group_indices), k=1)
            within_distances.extend(group_distances[triu_indices].tolist())
    mean_within = np.mean(within_distances) if within_distances else 0

    between_distances = []
    for i, group1 in enumerate(unique_groups):
        group1_indices = np.where(groups == group1)[0]
        for j, group2 in enumerate(unique_groups):
            if i < j:
                group2_indices = np.where(groups == group2)[0]
                between_distances.extend(
                    distances_2d[np.ix_(group1_indices, group2_indices)].flatten().tolist()
                )
    mean_between = np.mean(between_distances) if between_distances else 0

    if mean_within > 0:
        return mean_between / mean_within
    return np.inf if mean_between > 0 else 0


def calculate_stress(X_original, X_mds_2d):
    distances_original = pdist(X_original)
    distances_mds = pdist(X_mds_2d)
    numerator = np.sum((distances_original - distances_mds) ** 2)
    denominator = np.sum(distances_original ** 2)
    return np.sqrt(numerator / denominator) if denominator > 0 else 0


df = pd.read_csv(os.path.join(task_dir, "data", "gene_expression.csv"))
if "Group" not in df.columns:
    raise ValueError("Group column not found in gene_expression.csv")
if "Sample_ID" not in df.columns:
    raise ValueError("Sample_ID column not found in gene_expression.csv")

gene_cols = [col for col in df.columns if col.startswith("Gene_")]
X = df[gene_cols].values
groups = df["Group"].values

X_scaled = StandardScaler().fit_transform(X)

mds = MDS(n_components=2, random_state=42, dissimilarity='euclidean')
X_mds_2d = mds.fit_transform(X_scaled)

stress = calculate_stress(X_scaled, X_mds_2d)
distance_ratio = calculate_distance_ratio(X_mds_2d, groups)

with open(os.path.join(task_dir, "ref_answer", "mds_results.txt"), "w") as f:
    f.write(f"Stress: {stress:.6f}\n")
    f.write(f"Between_Within_Ratio: {distance_ratio:.6f}\n")
