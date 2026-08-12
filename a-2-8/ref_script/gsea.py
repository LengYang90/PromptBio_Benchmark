import os
import gseapy as gp
import pandas as pd

task_dir = os.path.dirname(os.path.dirname(__file__))
tmp_dir = os.path.join(task_dir, "tmp")
os.makedirs(tmp_dir, exist_ok=True)

file_path = os.path.join(task_dir, "data", "gene_rnk.txt")
res_path = os.path.join(task_dir, "ref_answer", "gsea_result.csv")
res_top5_path = os.path.join(task_dir, "ref_answer", "gsea_top5_result.csv")
fig_path = os.path.join(tmp_dir, "gsea_plots")


def run_gsea_analysis(ranked_gene_file):
    gsea_res = gp.prerank(
        rnk=ranked_gene_file,
        gene_sets=["GO_Biological_Process_2021"],
        outdir=fig_path,
        verbose=True,
        threads=20,
        permutation_num=1000,
        min_size=15,
        max_size=500,
        seed=42,
        no_plot=False,
    )
    return gsea_res.res2d


results = run_gsea_analysis(file_path)

significant_results = results[results["FDR q-val"] < 0.25].sort_values(
    "NES", ascending=False
)

results.to_csv(res_path, index=False)
significant_results.head(5).to_csv(res_top5_path, index=False)
