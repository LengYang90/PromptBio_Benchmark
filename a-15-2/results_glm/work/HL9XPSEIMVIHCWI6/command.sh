import pandas as pd

base = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_714/toolsgenie_20260714/data"

snp_pos = pd.read_csv(f"{base}/Matrix_of_trait_positions.csv", index_col=0)
cpg_pos = pd.read_csv(f"{base}/Matrix_of_bulk_omics_positions.csv", index_col=0)
ctc = pd.read_csv(f"{base}/Matrix_of_cell_type_composition.csv", index_col=0)

print("=" * 80)
print("ALL SNP POSITIONS (31 SNPs):")
print(snp_pos.to_string())

print("\n" + "=" * 80)
print("ALL CpG POSITIONS (6 CpGs):")
print(cpg_pos.to_string())

print("\n" + "=" * 80)
print("FULL CELL TYPE COMPOSITION (53 samples x 3 cell types):")
print(ctc.to_string())

print("\n" + "=" * 80)
print("CIS SNP-CpG PAIRS (within 1Mb = 1,000,000 bp):")
pairs = []
for snp_id, srow in snp_pos.iterrows():
    for cpg_id, crow in cpg_pos.iterrows():
        dist = abs(int(srow["Position"]) - int(crow["Position"]))
        if dist <= 1_000_000:
            pairs.append({"SNP": snp_id, "SNP_Position": int(srow["Position"]),
                          "CpG": cpg_id, "CpG_Position": int(crow["Position"]),
                          "Distance": dist})
cis_df = pd.DataFrame(pairs)
print(cis_df.to_string(index=False))
print(f"\nTotal cis pairs: {len(cis_df)} (out of {len(snp_pos)*len(cpg_pos)} possible)")

out = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_714/toolsgenie_20260714/cis_SNP_CpG_pairs.csv"
cis_df.to_csv(out, index=False)
print(f"\nSaved cis pairs to: {out}")
