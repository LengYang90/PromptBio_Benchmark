import pandas as pd
import importlib.util
import subprocess
import sys

if importlib.util.find_spec("gseapy") is None:
    subprocess.check_call([sys.executable, "-m", "pip", "install", "gseapy"])
import gseapy

rnk_path = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-2-8/result_714/toolsgenie_20260714/data/gene_rnk.txt"
out_dir = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-2-8/result_714/toolsgenie_20260714/data/gsea_output"
full_result_path = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-2-8/result_714/toolsgenie_20260714/data/gsea_result.csv"
top5_path = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-2-8/result_714/toolsgenie_20260714/data/gsea_top5_result.csv"

df = pd.read_csv(rnk_path, sep="\t", header=None, names=["gene", "score"])

pre_res = gseapy.prerank(
    rnk=df,
    gene_sets="GO_Biological_Process_2023",
    outdir=out_dir,
    seed=42,
    min_size=15,
    max_size=500,
    permutation_num=1000,
    threads=4,
    no_plot=True
)

res = pre_res.res2d

print("Shape:", res.shape)
print("Columns:", list(res.columns))
print("\nHead:")
print(res.head().to_string())

standard_cols = ["Name", "Term", "ES", "NES", "NOM p-val", "FDR q-val", "FWER p-val", "RANK AT MAX", "LEADING EDGE"]
keep_cols = [c for c in standard_cols if c in res.columns]
res_full = res[keep_cols].copy()

res_full["_abs_NES"] = res_full["NES"].abs()
res_full = res_full.sort_values(by=["FDR q-val", "_abs_NES"], ascending=[True, False])
res_full = res_full.drop(columns=["_abs_NES"])

res_full.to_csv(full_result_path, index=False)

top5 = res_full.head(5)
top5.to_csv(top5_path, index=False)

print("\n===== TOP 5 RESULTS =====")
print(top5.to_string())
