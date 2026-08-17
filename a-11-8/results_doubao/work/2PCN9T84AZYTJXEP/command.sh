import pandas as pd
import networkx as nx
import matplotlib.pyplot as plt
from matplotlib.patches import Patch

# Define absolute paths
BASE_DIR = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-11-8/result_11/toolsgenie_20260623"
EDGES_PATH = f"{BASE_DIR}/preprocessed_edges.csv"
NODE_TYPES_PATH = f"{BASE_DIR}/node_types.csv"
HUBS_PATH = f"{BASE_DIR}/cross_layer_hubs.csv"
OUTPUT_IMG = f"{BASE_DIR}/integrated_network.png"

# Load input data
edges = pd.read_csv(EDGES_PATH)
node_types = pd.read_csv(NODE_TYPES_PATH)
hubs = pd.read_csv(HUBS_PATH)
hub_gene_set = set(hubs["node"].tolist())

# Build network graph
G = nx.from_pandas_edgelist(edges, source="source", target="target")

# Assign two-layer positions: miRNA top layer (y=2), gene bottom layer (y=0)
miRNA_nodes = node_types[node_types["node_type"] == "miRNA"]["node"].tolist()
gene_nodes = node_types[node_types["node_type"] == "gene"]["node"].tolist()
pos = {}
for idx, node in enumerate(miRNA_nodes):
    pos[node] = (idx + 1, 2)
for idx, node in enumerate(gene_nodes):
    pos[node] = (idx + 1, 0)

# Set node style attributes
node_colors, node_sizes, node_edgecolors = [], [], []
for node in G.nodes:
    ntype = node_types.loc[node_types["node"] == node, "node_type"].iloc[0]
    if ntype == "miRNA":
        node_colors.append("#FFA500")
        node_sizes.append(300)
        node_edgecolors.append("#000000")
    else:
        node_colors.append("#1E90FF")
        if node in hub_gene_set:
            node_sizes.append(800)
            node_edgecolors.append("#FF0000")
        else:
            node_sizes.append(300)
            node_edgecolors.append("#000000")

# Generate plot
plt.figure(figsize=(12, 8))
nx.draw_networkx_edges(G, pos, alpha=0.5, edge_color="gray")
nx.draw_networkx_nodes(G, pos, node_color=node_colors, node_size=node_sizes, edgecolors=node_edgecolors, linewidths=2)
nx.draw_networkx_labels(G, pos, font_size=10, font_weight="bold")

# Add legend
legend = [
    Patch(facecolor="#FFA500", edgecolor="black", label="miRNA"),
    Patch(facecolor="#1E90FF", edgecolor="black", label="Gene"),
    Patch(facecolor="#1E90FF", edgecolor="red", linewidth=2, label="Cross-layer Hub Gene")
]
plt.legend(handles=legend, loc="upper right")
plt.axis("off")
plt.tight_layout()

# Save publication quality output
plt.savefig(OUTPUT_IMG, dpi=300, bbox_inches="tight")
plt.close()
