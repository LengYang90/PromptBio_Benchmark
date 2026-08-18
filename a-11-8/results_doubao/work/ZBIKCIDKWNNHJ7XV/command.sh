import pandas as pd
import os

# Define absolute paths
INPUT_DIR = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-11-8/result_11/toolsgenie_20260623/data"
OUTPUT_DIR = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-11-8/result_11/toolsgenie_20260623"

ppi_path = os.path.join(INPUT_DIR, "ppi_network.csv")
mirna_path = os.path.join(INPUT_DIR, "mirna_target.csv")
edges_output = os.path.join(OUTPUT_DIR, "preprocessed_edges.csv")
node_types_output = os.path.join(OUTPUT_DIR, "node_types.csv")

# Process PPI edges
ppi_df = pd.read_csv(ppi_path, index_col=0)
ppi_edges = ppi_df[["preferredName_A", "preferredName_B"]].rename(columns={"preferredName_A": "source", "preferredName_B": "target"})
ppi_edges["edge_type"] = "ppi"

# Process miRNA-target edges
mirna_df = pd.read_csv(mirna_path, index_col=0)
mirna_edges = mirna_df.reset_index()[["miRNA", "target_gene"]].rename(columns={"miRNA": "source", "target_gene": "target"})
mirna_edges["edge_type"] = "mirna_target"

# Combine and save edges
all_edges = pd.concat([ppi_edges, mirna_edges], ignore_index=True)
all_edges.to_csv(edges_output, index=False)

# Generate node type dictionary
mirna_nodes = set(mirna_df.index.unique())
gene_nodes = set(ppi_df["preferredName_A"]).union(set(ppi_df["preferredName_B"])).union(set(mirna_df["target_gene"]))

node_type_dict = {}
for node in mirna_nodes:
    node_type_dict[node] = "miRNA"
for node in gene_nodes:
    node_type_dict[node] = "gene"

# Save node types
node_type_df = pd.DataFrame.from_dict(node_type_dict, orient="index", columns=["node_type"]).rename_axis("node")
node_type_df.to_csv(node_types_output)

# Print summary
print(f"Preprocessed edges saved to: {edges_output}")
print(f"Total edges: {len(all_edges)} (PPI: {len(ppi_edges)}, miRNA-target: {len(mirna_edges)})")
print(f"Node types saved to: {node_types_output}")
print(f"Total nodes: {len(node_type_dict)} (miRNA: {len(mirna_nodes)}, gene: {len(gene_nodes)})")
