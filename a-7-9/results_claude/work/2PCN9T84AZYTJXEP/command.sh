import subprocess
import sys

# Install required package
subprocess.check_call([sys.executable, "-m", "pip", "install", "openpyxl"])

import pandas as pd
from scipy.stats import chi2_contingency
import numpy as np

# Load MeRIP data
merip_data = pd.read_excel('/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-9/result_10/toolsgenie_20260516/data/MeRIP_RNA_result.xlsx')

# First, let's check the actual column names
print("Available columns in MeRIP data:")
print(merip_data.columns.tolist())
print()

# Based on previous inspection, the correct column names should be identified
# Let's look for columns containing 'm6A' and 'DEG' or similar patterns
m6a_cols = [col for col in merip_data.columns if 'm6A' in str(col)]
deg_cols = [col for col in merip_data.columns if 'DEG' in str(col)]

print("Columns containing 'm6A':", m6a_cols)
print("Columns containing 'DEG':", deg_cols)
print()

# Use the correct column names (assuming they exist with different formatting)
# From the data inspection, we likely have columns like 'm6A status' and 'DEG status'
# Let's try different possible variations
possible_m6a_names = ['m6A status', 'm6A_status', 'm6A Status', 'M6A status', 'M6A_status']
possible_deg_names = ['DEG status', 'DEG_status', 'DEG Status', 'deg status', 'deg_status']

m6a_col = None
deg_col = None

# Find the correct column names
for col in merip_data.columns:
    if any(name.lower().replace('_', ' ').replace(' ', '') == col.lower().replace('_', ' ').replace(' ', '') 
           for name in possible_m6a_names):
        m6a_col = col
    if any(name.lower().replace('_', ' ').replace(' ', '') == col.lower().replace('_', ' ').replace(' ', '') 
           for name in possible_deg_names):
        deg_col = col

if m6a_col is None or deg_col is None:
    print("Could not find the exact column names. Let's examine all columns:")
    for i, col in enumerate(merip_data.columns):
        print(f"{i}: {col}")
        if i < len(merip_data.columns):
            print(f"   Sample values: {merip_data[col].dropna().unique()[:5]}")
    print()
    
    # If we still can't find them, let's look for columns with categorical data
    # that might represent m6A and DEG status
    categorical_cols = []
    for col in merip_data.columns:
        if merip_data[col].dtype == 'object':
            unique_vals = merip_data[col].dropna().unique()
            if len(unique_vals) < 10:  # Likely categorical
                categorical_cols.append((col, unique_vals))
    
    print("Potential categorical columns:")
    for col, vals in categorical_cols:
        print(f"{col}: {vals}")
    
    # Make educated guesses based on common patterns
    m6a_col = categorical_cols[0][0] if len(categorical_cols) > 0 else None
    deg_col = categorical_cols[1][0] if len(categorical_cols) > 1 else None

print(f"Using m6A column: {m6a_col}")
print(f"Using DEG column: {deg_col}")
print()

if m6a_col and deg_col:
    # Filter out rows with missing m6A status or DEG status
    filtered_data = merip_data.dropna(subset=[m6a_col, deg_col])
    
    print(f"Original data shape: {merip_data.shape}")
    print(f"Filtered data shape: {filtered_data.shape}")
    print()
    
    # Create contingency table
    contingency_table = pd.crosstab(filtered_data[m6a_col], filtered_data[deg_col])
    
    print("Contingency Table:")
    print(contingency_table)
    print()
    
    # Perform chi-square test
    chi2_stat, p_value, dof, expected = chi2_contingency(contingency_table)
    
    print("Chi-square Test Results:")
    print(f"Chi-square statistic: {chi2_stat}")
    print(f"p-value: {p_value}")
    print(f"Degrees of freedom: {dof}")
    print()
    
    print("Expected frequencies:")
    print(expected)
    
    # Save p-value to file
    with open('/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-9/result_10/toolsgenie_20260516/chisq_test_p_value.txt', 'w') as f:
        f.write(str(p_value))
    
    print(f"\nChi-square test p-value saved to chisq_test_p_value.txt: {p_value}")
else:
    print("Error: Could not identify the correct m6A and DEG status columns.")
    print("Please check the column names in the dataset.")
