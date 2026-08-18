import pandas as pd
import os

file_paths = [
    "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-4-6/result_11/toolsgenie_20260623/data/Matrix_of_bulk_omics_measurements.csv",
    "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-4-6/result_11/toolsgenie_20260623/data/Matrix_of_cell_type_composition.csv",
    "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-4-6/result_11/toolsgenie_20260623/data/Matrix_of_ovariates.csv",
    "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-4-6/result_11/toolsgenie_20260623/data/Matrix_of_traits.csv"
]

sample_id_sets = {}

for fpath in file_paths:
    fname = os.path.basename(fpath)
    print("="*80)
    print(f"File: {fname}")
    df = pd.read_csv(fpath, index_col=0)
    # Transpose bulk omics matrix to set samples as row index
    if fname == "Matrix_of_bulk_omics_measurements.csv":
        df = df.T
    print(f"Dimensions: {df.shape[0]} samples, {df.shape[1]} features/columns")
    print(f"Column names: {list(df.columns)}")
    print("First 5 rows:")
    print(df.head())
    sample_id_sets[fname] = set(df.index)
    # Explicit warning for corrupted covariates file
    if fname == "Matrix_of_ovariates.csv" and df.shape[1] == 0:
        print("WARNING: This file is corrupted/empty, no valid covariate data available!")

print("\n" + "="*80)
print("Sample ID consistency check:")
all_ids = list(sample_id_sets.values())
consistent = all(s == all_ids[0] for s in all_ids)
if consistent:
    print("PASS: All sample identifiers are consistent across all 4 files, suitable for association testing.")
else:
    print("FAIL: Sample identifiers are not consistent! Mismatches found between files:")
    for i in range(1, len(all_ids)):
        fname1 = list(sample_id_sets.keys())[0]
        fname2 = list(sample_id_sets.keys())[i]
        missing_in_2 = all_ids[0] - all_ids[i]
        missing_in_1 = all_ids[i] - all_ids[0]
        if missing_in_2 or missing_in_1:
            print(f"Between {fname1} and {fname2}:")
            if missing_in_2:
                print(f"Samples present in {fname1} but missing in {fname2}: {missing_in_2}")
            if missing_in_1:
                print(f"Samples present in {fname2} but missing in {fname1}: {missing_in_1}")
