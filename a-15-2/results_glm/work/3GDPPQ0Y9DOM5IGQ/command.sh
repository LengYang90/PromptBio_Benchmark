import pandas as pd
import numpy as np
import statsmodels.formula.api as smf

base = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_714/toolsgenie_20260714/data"
out_dir = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_714/toolsgenie_20260714"

snp_geno = pd.read_csv(f"{base}/Matrix_of_SNP_genotypes.csv", index_col=0)
meth = pd.read_csv(f"{base}/Matrix_of_bulk_omics_measurements.csv", index_col=0)
ctc = pd.read_csv(f"{base}/Matrix_of_cell_type_composition.csv", index_col=0)
cov = pd.read_csv(f"{base}/Matrix_of_ovariates.csv", index_col=0)
cis_pairs = pd.read_csv(f"{out_dir}/cis_SNP_CpG_pairs.csv")

sample_ids = snp_geno.columns.tolist()
cov.index = sample_ids
ctc = ctc.loc[sample_ids]
cov = cov.loc[sample_ids]

cell_types = ["CD4T", "CD8T", "NK"]
results = []

for _, pair in cis_pairs.iterrows():
    snp_id = pair["SNP"]
    cpg_id = pair["CpG"]
    geno = snp_geno.loc[snp_id, sample_ids].astype(float).values
    meth_vals = meth.loc[cpg_id, sample_ids].astype(float).values
    for ct in cell_types:
        ct_prop = ctc[ct].values
        df = pd.DataFrame({
            "methylation": meth_vals,
            "genotype": geno,
            "celltype_prop": ct_prop,
            "PC1": cov["PC1"].values,
            "PC2": cov["PC2"].values,
            "PC3": cov["PC3"].values
        })
        model = smf.ols("methylation ~ genotype + celltype_prop + genotype:celltype_prop + PC1 + PC2 + PC3", data=df).fit()
        term = "genotype:celltype_prop"
        results.append({
            "SNP": snp_id,
            "CpG": cpg_id,
            "celltype": ct,
            "estimate": model.params[term],
            "statistic": model.tvalues[term],
            "p.value": model.pvalues[term]
        })

results_df = pd.DataFrame(results)
results_df.to_csv(f"{out_dir}/mQTL_results.txt", sep="\t", index=False)

print(results_df.head(20).to_string(index=False))
print(f"\nTotal number of rows: {len(results_df)}")
