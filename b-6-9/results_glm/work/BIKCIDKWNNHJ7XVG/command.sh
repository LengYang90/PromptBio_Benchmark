import pandas as pd
import numpy as np
from sklearn.manifold import MDS
from scipy.spatial.distance import pdist

path = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/b-6-9/result_79/toolsgenie_20260709/data/gene_expression.csv"
df = pd.read_csv(path, index_col=0)

groups = df['Group']
features = df.drop(columns=['Group'])

mds = MDS(n_components=2, random_state=42, dissimilarity='euclidean', normalized_stress='auto')
coords = mds.fit_transform(features)
stress = mds.stress_

centroids = np.array([coords[groups == g].mean(axis=0) for g in groups.unique()])
between_dist = np.mean(pdist(centroids))

within_dists = [np.mean(pdist(coords[groups == g])) for g in groups.unique() if (groups == g).sum() > 1]
within_dist = np.mean(within_dists)

ratio = between_dist / within_dist

out_path = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/b-6-9/result_79/toolsgenie_20260709/data/mds_results.txt"
with open(out_path, 'w') as f:
    f.write(f"Stress: {stress}\n")
    f.write(f"Between_Within_Ratio: {ratio}\n")

with open(out_path, 'r') as f:
    print(f.read())
