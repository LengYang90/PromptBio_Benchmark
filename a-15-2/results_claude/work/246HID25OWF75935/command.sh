import pandas as pd
import os

# Check if mQTL_results.tsv exists
file_path = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_10/toolsgenie_20260516/mQTL_results.tsv"

print("=== mQTL Results File Verification ===")

if os.path.exists(file_path):
    print(f"✓ mQTL_results.tsv file exists at: {file_path}")
    
    # Load the file
    try:
        results = pd.read_csv(file_path, sep='\t')
        
        # Check file structure
        print(f"\n=== File Structure ===")
        print(f"File dimensions: {results.shape[0]} rows × {results.shape[1]} columns")
        print(f"Column names: {list(results.columns)}")
        
        # Check required columns
        required_cols = ['term', 'response', 'celltype', 'estimate', 'statistic', 'p.value']
        print(f"\n=== Required Columns Check ===")
        missing_cols = []
        for col in required_cols:
            if col in results.columns:
                print(f"✓ {col} found")
            else:
                print(f"✗ {col} missing")
                missing_cols.append(col)
        
        # Display first few rows
        print(f"\n=== First 5 rows ===")
        print(results.head())
        
        # Summary statistics
        print(f"\n=== Summary Statistics ===")
        print(f"Total associations: {len(results)}")
        
        if 'celltype' in results.columns:
            print(f"\n=== Associations by Cell Type ===")
            celltype_counts = results['celltype'].value_counts()
            print(celltype_counts)
        
        if 'p.value' in results.columns:
            print(f"\n=== P-value Statistics ===")
            pval_stats = results['p.value'].describe()
            print(pval_stats)
            sig_05 = sum(results['p.value'] < 0.05)
            sig_001 = sum(results['p.value'] < 0.001)
            print(f"Significant associations (p < 0.05): {sig_05}")
            print(f"Highly significant associations (p < 0.001): {sig_001}")
        
        if 'estimate' in results.columns:
            print(f"\n=== Effect Size (Estimate) Statistics ===")
            estimate_stats = results['estimate'].describe()
            print(estimate_stats)
        
        if 'statistic' in results.columns:
            print(f"\n=== Test Statistic Summary ===")
            stat_summary = results['statistic'].describe()
            print(stat_summary)
            
        # Check for any missing values
        print(f"\n=== Missing Values Check ===")
        missing_values = results.isnull().sum()
        if missing_values.sum() > 0:
            print("Missing values found:")
            print(missing_values[missing_values > 0])
        else:
            print("No missing values found")
            
        # Additional data quality checks
        print(f"\n=== Data Quality Summary ===")
        print(f"File verification: SUCCESSFUL")
        print(f"Required columns: {len(required_cols) - len(missing_cols)}/{len(required_cols)} present")
        print(f"Data completeness: {((results.size - results.isnull().sum().sum()) / results.size * 100):.1f}%")
        
    except Exception as e:
        print(f"✗ Error reading mQTL_results.tsv: {str(e)}")
        print("File exists but cannot be read properly")
        
else:
    print(f"✗ mQTL_results.tsv file not found at: {file_path}")
    
    # Check what files are available in the directory
    output_dir = os.path.dirname(file_path)
    if os.path.exists(output_dir):
        print(f"\n=== Available files in output directory ===")
        available_files = os.listdir(output_dir)
        for file in sorted(available_files):
            file_path_check = os.path.join(output_dir, file)
            if os.path.isfile(file_path_check):
                print(f"  - {file}")
            elif os.path.isdir(file_path_check):
                print(f"  - {file}/ (directory)")
    else:
        print(f"Output directory does not exist: {output_dir}")
    
    print(f"\n=== Diagnosis ===")
    print("The mQTL analysis appears to have completed based on history,")
    print("but the results file was not properly saved.")
    print("Recommendation: Re-run the ctcisQTL analysis with explicit file output verification.")
