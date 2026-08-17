import os
import pandas as pd
import networkx as nx
import matplotlib.pyplot as plt

task_dir = os.path.dirname(os.path.dirname(__file__))

ppi   = pd.read_csv(os.path.join(task_dir, "data", "ppi_network.csv"))
mirna = pd.read_csv(os.path.join(task_dir, "data", "mirna_target.csv"))

G_ppi   = nx.from_pandas_edgelist(ppi,   "preferredName_A", "preferredName_B", ["score"])
G_mirna = nx.from_pandas_edgelist(mirna, "miRNA", "target_gene", ["interaction_score"])
G_multi = nx.compose(G_ppi, G_mirna)

degree_centrality = nx.degree_centrality(G_multi)
dc_df = pd.DataFrame(list(degree_centrality.items()), columns=["node", "degree_centrality"])
dc_df["type"] = dc_df["node"].apply(
    lambda x: "miRNA" if x.startswith("hsa") or x.startswith("let") else "gene"
)

threshold       = dc_df["degree_centrality"].quantile(0.9)
cross_layer_hubs = dc_df[dc_df["degree_centrality"] >= threshold]

cross_layer_hubs.to_csv(
    os.path.join(task_dir, "ref_answer", "cross_layer_hubs.csv"), index=False
)

plt.figure(figsize=(10, 8))
pos    = nx.spring_layout(G_multi, seed=42)
colors = ["#ff7f0e" if n.startswith("hsa") or n.startswith("let") else "#1f77b4"
          for n in G_multi.nodes()]
sizes  = [800 if n in cross_layer_hubs["node"].values else 300 for n in G_multi.nodes()]
nx.draw_networkx(G_multi, pos, with_labels=True, node_color=colors, node_size=sizes, font_size=8)
plt.title("Integrated PPI + miRNA-target Network (Cross-layer Hubs Highlighted)")
plt.tight_layout()
plt.savefig(os.path.join(task_dir, "ref_answer", "integrated_network.png"), dpi=300)
plt.close()
