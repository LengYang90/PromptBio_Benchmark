import pandas as pd
import matplotlib.pyplot as plt
from sklearn.mixture import GaussianMixture

# Define paths
INPUT_FILE = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-4-8/result_11/toolsgenie_20260623/data/ChIP_data.csv"
OUTPUT_PLOT = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-4-8/result_11/toolsgenie_20260623/segmentation_model_plot.png"

# Load data
df = pd.read_csv(INPUT_FILE, index_col=0)
experiments = df.index.unique()

# Initialize plot
fig, axes = plt.subplots(nrows=2, ncols=1, figsize=(12, 8))

for idx, exp in enumerate(experiments):
    # Process dataset
    exp_data = df[df.index == exp].copy()
    exp_data = exp_data.sort_values("chromStart")
    exp_data["midpoint"] = (exp_data["chromStart"] + exp_data["chromEnd"]) / 2
    
    # Fit GMM
    counts = exp_data["count"].values.reshape(-1, 1)
    gmm = GaussianMixture(n_components=2, random_state=42)
    exp_data["class"] = gmm.fit_predict(counts)
    
    # Calculate separation threshold
    mean_vals = sorted(gmm.means_.flatten())
    threshold = (mean_vals[0] + mean_vals[1]) / 2
    
    # Plot
    ax = axes[idx]
    ax.scatter(exp_data["midpoint"], exp_data["count"], c=exp_data["class"], cmap="viridis", alpha=0.5, s=10)
    ax.axhline(y=threshold, color="red", linestyle="--", label=f"Threshold = {threshold:.2f}")
    ax.set_xlabel("Genomic Position")
    ax.set_ylabel("ChIP-seq Signal")
    ax.set_title(f"Experiment: {exp}")
    ax.legend()

plt.tight_layout()
plt.savefig(OUTPUT_PLOT, dpi=300)
plt.close()
