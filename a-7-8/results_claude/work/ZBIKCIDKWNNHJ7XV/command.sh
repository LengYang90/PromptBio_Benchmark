#!/bin/bash

# Set up working directory
WORK_DIR="/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-8/result_10/toolsgenie_20260516"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# Input file paths
MZML_FILE="/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-8/result_10/toolsgenie_20260516/data/RD139_Narrow_UPS1_0_1fmol_inj1.mzML"
FASTA_FILE="/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-8/result_10/toolsgenie_20260516/data/REF_EColi_K12_UPS1_combined.fasta"

echo "=== DIA-NN ENVIRONMENT SETUP AND VALIDATION ==="

# Check DIA-NN installation
echo "1. Checking DIA-NN installation:"
which diann
diann --version

# Validate input files
echo "2. Validating input files:"
echo "mzML file: $MZML_FILE"
ls -lh "$MZML_FILE"
echo "FASTA file: $FASTA_FILE"  
ls -lh "$FASTA_FILE"

# Test DIA-NN basic functionality
echo "3. Testing DIA-NN basic functionality:"
diann --help | head -20

# Verify file accessibility for DIA-NN
echo "4. File accessibility check:"
file "$MZML_FILE"
file "$FASTA_FILE"

echo "5. Working directory prepared:"
pwd
ls -la

echo "=== SETUP COMPLETE - Ready for DIA analysis ==="
