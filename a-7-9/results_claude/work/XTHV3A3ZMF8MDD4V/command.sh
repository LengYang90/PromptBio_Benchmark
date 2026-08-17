import pandas as pd
import numpy as np

# Load the Excel files
merip_file = '/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-9/result_10/toolsgenie_20260516/data/MeRIP_RNA_result.xlsx'
proteomic_file = '/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-9/result_10/toolsgenie_20260516/data/Proteomic_data.xlsx'

# Load MeRIP data
merip_data = pd.read_excel(merip_file)
print("=== MeRIP_RNA_result.xlsx Structure ===")
print(f"Shape: {merip_data.shape}")
print(f"Columns: {list(merip_data.columns)}")
print(f"Data types:\n{merip_data.dtypes}")
print(f"\nFirst 5 rows:\n{merip_data.head()}")
print(f"\nSummary statistics:\n{merip_data.describe()}")

print("\n" + "="*50 + "\n")

# Load Proteomic data
proteomic_data = pd.read_excel(proteomic_file)
print("=== Proteomic_data.xlsx Structure ===")
print(f"Shape: {proteomic_data.shape}")
print(f"Columns: {list(proteomic_data.columns)}")
print(f"Data types:\n{proteomic_data.dtypes}")
print(f"\nFirst 5 rows:\n{proteomic_data.head()}")
print(f"\nSummary statistics:\n{proteomic_data.describe()}")

# Check for missing values
print(f"\nMeRIP missing values:\n{merip_data.isnull().sum()}")
print(f"\nProteomic missing values:\n{proteomic_data.isnull().sum()}")

# Check unique values in categorical columns if any
for col in merip_data.columns:
    if merip_data[col].dtype == 'object':
        print(f"\nMeRIP {col} unique values: {merip_data[col].unique()}")

for col in proteomic_data.columns:
    if proteomic_data[col].dtype == 'object':
        print(f"\nProteomic {col} unique values: {proteomic_data[col].unique()}")
