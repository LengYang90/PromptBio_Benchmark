#!/bin/bash

# Set working directory
WORK_DIR="/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-8/result_10/toolsgenie_20260516"
cd "$WORK_DIR"

# Clean up previous failed attempt
echo "=== CLEANING UP PREVIOUS ATTEMPT ==="
rm -f core.* diann_log.txt report.tsv speclib.tsv speclib.predicted.speclib
rm -rf temp_diann

# Input file paths
MZML_FILE="/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-8/result_10/toolsgenie_20260516/data/RD139_Narrow_UPS1_0_1fmol_inj1.mzML"
FASTA_FILE="/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-8/result_10/toolsgenie_20260516/data/REF_EColi_K12_UPS1_combined.fasta"

# Output file path
OUTPUT_REPORT="/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-8/result_10/toolsgenie_20260516/report.tsv"

# DIA-NN executable path
DIANN_PATH="/usr/diann/1.8.1/diann"

echo "=== DIA-NN LIBRARY-FREE DIA ANALYSIS (MODIFIED) ==="

# Create temporary directory for DIA-NN
echo "Creating temporary directory for DIA-NN..."
mkdir -p ./temp_diann

# Set memory limits to prevent crashes
ulimit -c 0  # Disable core dumps
ulimit -v 8388608  # Limit virtual memory to 8GB

echo "Running DIA-NN with conservative parameters to avoid crashes..."

# Use more conservative parameters and reduced complexity
"$DIANN_PATH" \
  --f "$MZML_FILE" \
  --fasta "$FASTA_FILE" \
  --out "$OUTPUT_REPORT" \
  --lib "" \
  --gen-spec-lib \
  --predictor \
  --fasta-search \
  --qvalue 0.01 \
  --matrices \
  --out-lib "./speclib.tsv" \
  --temp ./temp_diann \
  --verbose 1 \
  --threads 2 \
  --peak-center \
  --no-ifs-removal 2>&1 | tee diann_log.txt

# Check if DIA-NN completed successfully
DIANN_EXIT_CODE=$?

echo "=== DIA-NN EXECUTION COMPLETED (Exit Code: $DIANN_EXIT_CODE) ==="

# If first attempt failed, try with even more conservative settings
if [ $DIANN_EXIT_CODE -ne 0 ] || [ ! -f "$OUTPUT_REPORT" ]; then
    echo "=== FIRST ATTEMPT FAILED, TRYING CONSERVATIVE APPROACH ==="
    
    # Clean up and try again with minimal parameters
    rm -f report.tsv speclib.tsv diann_log.txt
    
    "$DIANN_PATH" \
      --f "$MZML_FILE" \
      --fasta "$FASTA_FILE" \
      --out "$OUTPUT_REPORT" \
      --fasta-search \
      --qvalue 0.05 \
      --temp ./temp_diann \
      --threads 1 \
      --verbose 1 2>&1 | tee diann_log_retry.txt
    
    DIANN_EXIT_CODE=$?
    echo "=== RETRY COMPLETED (Exit Code: $DIANN_EXIT_CODE) ==="
fi

# Check DIA-NN log for errors
echo "=== CHECKING DIA-NN LOG ==="
if [ -f "diann_log.txt" ]; then
    echo "DIA-NN log file contents:"
    tail -20 diann_log.txt
fi

if [ -f "diann_log_retry.txt" ]; then
    echo "DIA-NN retry log file contents:"
    tail -20 diann_log_retry.txt
fi

# Verify output files
echo "=== OUTPUT VERIFICATION ==="
echo "Checking for output files in current directory:"
ls -la | grep -E "\.(tsv|txt|log)$"

if [ -f "$OUTPUT_REPORT" ]; then
    echo "SUCCESS: Main report file generated:"
    ls -lh "$OUTPUT_REPORT"
    echo "First few lines of report.tsv:"
    head -5 "$OUTPUT_REPORT"
    echo "Total lines in report:"
    wc -l "$OUTPUT_REPORT"
    
    # Check if report contains meaningful data
    if [ $(wc -l < "$OUTPUT_REPORT") -gt 1 ]; then
        echo "Report contains $(wc -l < "$OUTPUT_REPORT") lines of data"
    else
        echo "WARNING: Report file is empty or contains only header"
    fi
else
    echo "ERROR: Main output file $OUTPUT_REPORT was not generated"
    echo "Checking for any alternative output files..."
    find . -name "*.tsv" -o -name "*.txt" | head -10
fi

if [ -f "./speclib.tsv" ]; then
    echo "SUCCESS: Spectral library generated:"
    ls -lh "./speclib.tsv"
elif [ -f "./speclib.predicted.speclib" ]; then
    echo "SUCCESS: Predicted spectral library generated:"
    ls -lh "./speclib.predicted.speclib"
fi

# Final status check
echo "=== FINAL STATUS CHECK ==="
if [ -f "$OUTPUT_REPORT" ] && [ $(wc -l < "$OUTPUT_REPORT") -gt 1 ]; then
    echo "SUCCESS: DIA-NN analysis completed successfully"
    echo "Output file: $OUTPUT_REPORT"
else
    echo "FAILURE: DIA-NN analysis did not produce valid results"
    echo "Check log files for detailed error information"
fi

echo "=== ANALYSIS COMPLETE ==="
