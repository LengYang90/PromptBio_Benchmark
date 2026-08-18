import pandas as pd
import statsmodels.api as sm

# Define input/output absolute paths
methyl_path = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-4-6/result_11/toolsgenie_20260623/data/Matrix_of_bulk_omics_measurements.csv"
cell_type_path = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-4-6/result_11/toolsgenie_20260623/data/Matrix_of_cell_type_composition.csv"
trait_path = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-4-6/result_11/toolsgenie_20260623/data/Matrix_of_traits.csv"
output_path = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-4-6/result_11/toolsgenie_20260623/dna_methylation_results.txt"

# Load and align data
methyl_df = pd.read_csv(methyl_path, index_col=0).T
cell_df = pd.read_csv(cell_type_path, index_col=0)
trait_df = pd.read_csv(trait_path, index_col=0)
merged = methyl_df.join(cell_df).join(trait_df)

cpgs = methyl_df.columns.tolist()
cell_types = cell_df.columns.tolist()
results = []

# Run association tests
for cpg in cpgs:
    for ct in cell_types:
        y = merged[cpg]
        X = merged[[ct, 'disease']].copy()
        X['interaction'] = X['disease'] * X[ct]
        X = sm.add_constant(X)
        
        model = sm.OLS(y, X).fit()
        
        results.append([
            cpg, ct, f"disease:{ct}",
            model.params['interaction'],
            model.tvalues['interaction'],
            model.pvalues['interaction']
        ])

# Format and save results
res_df = pd.DataFrame(results, columns=['response', 'celltype', 'term', 'estimate', 'statistic', 'p.value'])
with open(output_path, 'w') as f:
    f.write("# covariate effects are not reported due to the corrupted input covariates file\n")
res_df.to_csv(output_path, mode='a', index=False, sep='\t')
