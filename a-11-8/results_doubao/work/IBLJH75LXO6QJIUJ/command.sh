import pandas as pd

# Define absolute paths
EDGES_PATH = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-11-8/result_11/toolsgenie_20260623/preprocessed_edges.csv"
NODE_TYPES_PATH = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-11-8/result_11/toolsgenie_20260623/node_types.csv"
OUTPUT_PATH = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-11-8/result_11/toolsgenie_20260623/cross_layer_hubs.csv"

# Calculate degree centrality for undirected network
edges = pd.read_csv(EDGES_PATH)
all_nodes = pd.concat([edges["source"], edges["target"]])
degree_df = all_nodes.value_counts().reset_index()
degree_df.columns = ["node", "degree_centrality"]

# Merge with node types and filter gene nodes
node_types = pd.read_csv(NODE_TYPES_PATH)
merged_df = pd.merge(degree_df, node_types, on="node", how="inner")
gene_degrees = merged_df[merged_df["node_type"] == "gene"]

# Compute 90th percentile threshold and filter cross-layer hubs
threshold = gene_degrees["degree_centrality"].quantile(0.9)
hubs = gene_degrees[gene_degrees["degree_centrality"] >= threshold].copy()
hubs["type"] = "gene"
hubs = hubs[["node", "degree_centrality", "type"]]

# Save output
hubs.to_csv(OUTPUT_PATH, index=False)
