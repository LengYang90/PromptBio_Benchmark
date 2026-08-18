import pandas as pd
import numpy as np

# Load data files
methylation = pd.read_csv('/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-4-6/result_10/toolsgenie_20260516/data/Matrix_of_bulk_omics_measurements.csv', index_col=0)
cell_comp = pd.read_csv('/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-4-6/result_10/toolsgenie_20260516/data/Matrix_of_cell_type_composition.csv', index_col=0)
traits = pd.read_csv('/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-4-6/result_10/toolsgenie_20260516/data/Matrix_of_traits.csv', index_col=0)

# Transpose methylation data to have samples as rows
methylation_t = methylation.T

# Find common samples across all datasets
common_samples = set(methylation_t.index) & set(cell_comp.index) & set(traits.index)
common_samples = sorted(list(common_samples))

print(f"Original sample counts:")
print(f"Methylation: {methylation_t.shape[0]} samples, {methylation_t.shape[1]} CpGs")
print(f"Cell composition: {cell_comp.shape[0]} samples, {cell_comp.shape[1]} cell types")
print(f"Traits: {traits.shape[0]} samples, {traits.shape[1]} traits")
print(f"Common samples: {len(common_samples)}")

# Align datasets to common samples
methylation_aligned = methylation_t.loc[common_samples]
cell_comp_aligned = cell_comp.loc[common_samples]
traits_aligned = traits.loc[common_samples]

# Merge all data
combined_data = pd.concat([methylation_aligned, cell_comp_aligned, traits_aligned], axis=1)

print(f"\nData alignment check:")
print(f"All methylation samples in common: {all(idx in common_samples for idx in methylation_aligned.index)}")
print(f"All cell composition samples in common: {all(idx in common_samples for idx in cell_comp_aligned.index)}")
print(f"All trait samples in common: {all(idx in common_samples for idx in traits_aligned.index)}")
print(f"Combined dataset shape: {combined_data.shape}")

# Save combined dataset
combined_data.to_csv('/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-4-6/result_10/toolsgenie_20260516/combined_dataset.csv')

print(f"\nCombined dataset saved with:")
print(f"- {len(common_samples)} samples")
print(f"- {methylation_aligned.shape[1]} CpG sites")
print(f"- {cell_comp_aligned.shape[1]} cell types")
print(f"- {traits_aligned.shape[1]} disease trait")
print(f"- Ready for cell-type-specific association testing")
