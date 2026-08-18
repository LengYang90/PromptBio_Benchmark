import pandas as pd
import numpy as np

# File paths
bulk_omics_file = '/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-4-6/result_10/toolsgenie_20260516/data/Matrix_of_bulk_omics_measurements.csv'
cell_comp_file = '/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-4-6/result_10/toolsgenie_20260516/data/Matrix_of_cell_type_composition.csv'
covariates_file = '/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-4-6/result_10/toolsgenie_20260516/data/Matrix_of_ovariates.csv'
traits_file = '/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-4-6/result_10/toolsgenie_20260516/data/Matrix_of_traits.csv'

files = [
    ('Bulk Omics Measurements', bulk_omics_file),
    ('Cell Type Composition', cell_comp_file),
    ('Covariates', covariates_file),
    ('Traits', traits_file)
]

for name, filepath in files:
    print(f"\n=== {name} ===")
    print(f"File: {filepath}")
    
    try:
        df = pd.read_csv(filepath, index_col=0)
        
        print(f"Dimensions: {df.shape[0]} rows × {df.shape[1]} columns")
        print(f"Index name: {df.index.name}")
        print(f"Column names: {list(df.columns)}")
        print(f"Data types:\n{df.dtypes}")
        print(f"Missing values: {df.isnull().sum().sum()}")
        
        # Only describe if DataFrame has columns
        if df.shape[1] > 0:
            print("Numeric summary:")
            print(df.describe())
        else:
            print("Numeric summary: Cannot describe - DataFrame has no columns")
            print("File appears to be empty or corrupted")
        
        print("First 3 rows:")
        print(df.head(3))
        
        print("Sample index values:", df.index[:5].tolist())
        
    except Exception as e:
        print(f"Error reading file: {str(e)}")
        print("File may be corrupted or in an unexpected format")
