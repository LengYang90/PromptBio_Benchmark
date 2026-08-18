#!/usr/bin/env python3

import os
import xml.etree.ElementTree as ET
from collections import defaultdict

# Set base directory
base_dir = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-8/result_10/toolsgenie_20260516"
output_dir = base_dir

print("=== ANALYZING DIA-NN ZERO IDENTIFICATION ISSUE ===")

# 1. Analyze DIA-NN log files
log_files = [
    os.path.join(base_dir, "report.log.txt"),
    os.path.join(base_dir, "report.stats.tsv"), 
    os.path.join(base_dir, "diann_log_retry.txt")
]

print("\n1. ANALYZING DIA-NN LOG FILES:")
for log_file in log_files:
    if os.path.exists(log_file):
        print(f"\n--- {os.path.basename(log_file)} ---")
        with open(log_file, 'r') as f:
            content = f.read()
            print(f"File size: {len(content)} characters")
            
            # Look for key issues
            issues = []
            if "Cannot perform mass calibration" in content:
                issues.append("Mass calibration failed - too few precursors")
            if "neural networks will not be used" in content:
                issues.append("Neural networks disabled - insufficient data")
            if "Number of IDs at 0.01 FDR: 0" in content:
                issues.append("Zero identifications at 1% FDR")
            if "precursors generated" in content:
                import re
                match = re.search(r'(\d+) precursors generated', content)
                if match:
                    issues.append(f"Generated {match.group(1)} precursors from FASTA")
            
            print("Key findings:")
            for issue in issues:
                print(f"  - {issue}")
            
            # Print relevant excerpts
            lines = content.split('\n')
            for i, line in enumerate(lines):
                if any(keyword in line.lower() for keyword in ['error', 'warning', 'cannot', 'failed', 'too few']):
                    print(f"  Line {i+1}: {line.strip()}")
    else:
        print(f"File not found: {log_file}")

# 2. Deep inspection of mzML file
mzml_file = os.path.join(base_dir, "data/RD139_Narrow_UPS1_0_1fmol_inj1.mzML")
print(f"\n2. DEEP mzML FILE ANALYSIS:")
print(f"File: {mzml_file}")

if os.path.exists(mzml_file):
    print(f"File size: {os.path.getsize(mzml_file) / (1024*1024):.1f} MB")
    
    # Parse mzML to understand acquisition method
    try:
        tree = ET.parse(mzml_file)
        root = tree.getroot()
        
        # Find namespace
        ns = {'ms': 'http://psi.hupo.org/ms/obo'}
        if not root.tag.startswith('{'):
            ns = {'ms': ''}
        
        # Analyze scan types and acquisition method
        scan_types = defaultdict(int)
        ms_levels = defaultdict(int)
        acquisition_methods = set()
        isolation_windows = []
        
        # Look for spectra
        spectra_found = 0
        for spectrum in root.iter():
            if 'spectrum' in spectrum.tag.lower():
                spectra_found += 1
                if spectra_found > 100:  # Limit analysis to first 100 spectra
                    break
                
                # Get MS level
                ms_level = None
                for cv_param in spectrum.iter():
                    if 'cvParam' in cv_param.tag:
                        accession = cv_param.get('accession', '')
                        name = cv_param.get('name', '')
                        value = cv_param.get('value', '')
                        
                        if accession == 'MS:1000511':  # MS level
                            ms_level = int(value)
                            ms_levels[ms_level] += 1
                        elif accession == 'MS:1000579':  # MS1 spectrum
                            scan_types['MS1'] += 1
                        elif accession == 'MS:1000580':  # MSn spectrum  
                            scan_types['MSn'] += 1
                        elif 'DIA' in name.upper() or 'SWATH' in name.upper():
                            acquisition_methods.add('DIA/SWATH')
                        elif 'isolation window' in name.lower():
                            try:
                                isolation_windows.append(float(value))
                            except:
                                pass
        
        print(f"Total spectra analyzed: {min(spectra_found, 100)}")
        print(f"MS levels found: {dict(ms_levels)}")
        print(f"Scan types: {dict(scan_types)}")
        print(f"Acquisition methods detected: {acquisition_methods if acquisition_methods else 'Standard MS/MS'}")
        
        if isolation_windows:
            print(f"Isolation windows: {len(set(isolation_windows))} unique windows")
            print(f"Window range: {min(isolation_windows):.1f} - {max(isolation_windows):.1f}")
        
        # Check if this looks like DIA data
        dia_indicators = []
        if len(set(isolation_windows)) > 10:
            dia_indicators.append(f"Multiple isolation windows ({len(set(isolation_windows))})")
        if ms_levels.get(2, 0) > ms_levels.get(1, 0) * 5:
            dia_indicators.append("High MS2/MS1 ratio suggesting DIA")
        if any('DIA' in method or 'SWATH' in method for method in acquisition_methods):
            dia_indicators.append("DIA/SWATH keywords found")
            
        print(f"DIA acquisition indicators: {dia_indicators if dia_indicators else 'None - may be DDA data'}")
        
    except Exception as e:
        print(f"Error parsing mzML: {e}")
        # Fallback: check file content with text search
        with open(mzml_file, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read(10000)  # First 10KB
            if 'DIA' in content.upper() or 'SWATH' in content.upper():
                print("DIA/SWATH keywords found in file header")
            else:
                print("No clear DIA indicators in file header")

# 3. Generate diagnostic summary
print(f"\n3. DIAGNOSTIC SUMMARY:")
print("Potential causes of zero identifications:")
print("- Data type mismatch: File may be DDA data analyzed with DIA parameters")
print("- Mass accuracy issues: Instrument calibration problems")
print("- Low signal quality: Sample concentration too low (0.1 fmol)")
print("- Parameter settings: Default DIA-NN settings may not match acquisition method")
print("- Database mismatch: E.coli database may not match sample composition")

# 4. Write analysis report
report_file = os.path.join(output_dir, "diann_failure_analysis.txt")
with open(report_file, 'w') as f:
    f.write("DIA-NN Zero Identification Analysis Report\n")
    f.write("=" * 50 + "\n\n")
    f.write("ISSUE: DIA-NN analysis completed successfully but produced zero precursor identifications\n\n")
    f.write("KEY FINDINGS:\n")
    f.write("1. Software executed without crashes (exit code 0)\n")
    f.write("2. Predicted spectral library generated (125MB)\n")
    f.write("3. Report files created but contain only headers\n")
    f.write("4. Log shows 'Cannot perform mass calibration, too few confidently identified precursors'\n")
    f.write("5. Neural networks disabled due to insufficient identifications\n\n")
    f.write("LIKELY CAUSES:\n")
    f.write("- Sample concentration too low (0.1 fmol UPS1)\n")
    f.write("- Potential data type mismatch (DDA vs DIA)\n")
    f.write("- Mass accuracy/calibration issues\n")
    f.write("- Incompatible acquisition parameters\n\n")
    f.write("RECOMMENDATIONS:\n")
    f.write("- Verify data acquisition method (DIA vs DDA)\n")
    f.write("- Adjust mass tolerance parameters\n")
    f.write("- Try library-based search if available\n")
    f.write("- Consider alternative search engines\n")

print(f"\nAnalysis report saved to: {report_file}")
