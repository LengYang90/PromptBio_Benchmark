import pandas as pd

# Define input paths
exp_path = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-7/result_11/toolsgenie_20260623/data/gbm.exp.csv"
mut_path = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-7/result_11/toolsgenie_20260623/data/gbm.mut.csv"
cn_path = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-7/result_11/toolsgenie_20260623/data/gbm.cn.csv"
out_dir = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-7/result_11/toolsgenie_20260623"

# Load datasets and set sample ID as index
exp_df = pd.read_csv(exp_path, index_col=0)
mut_df = pd.read_csv(mut_path, index_col=0)
cn_df = pd.read_csv(cn_path, index_col=0)

# Get common samples and align order
common_samples = sorted(list(set(exp_df.index) & set(mut_df.index) & set(cn_df.index)))
exp_aligned = exp_df.reindex(common_samples).apply(pd.to_numeric)
mut_aligned = mut_df.reindex(common_samples).apply(pd.to_numeric)
cn_aligned = cn_df.reindex(common_samples).apply(pd.to_numeric)

# Check missing values
print(f"Common sample count: {len(common_samples)}")
print(f"Missing values in expression matrix: {exp_aligned.isna().sum().sum()}")
print(f"Missing values in mutation matrix: {mut_aligned.isna().sum().sum()}")
print(f"Missing values in copy number matrix: {cn_aligned.isna().sum().sum()}")

# Save aligned datasets
exp_aligned.to_csv(f"{out_dir}/preprocessed_gbm_exp.csv", index=True, header=True)
mut_aligned.to_csv(f"{out_dir}/preprocessed_gbm_mut.csv", index=True, header=True)
cn_aligned.to_csv(f"{out_dir}/preprocessed_gbm_cn.csv", index=True, header=True)
