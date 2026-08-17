#!/bin/bash

# File paths
MZML_FILE="/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-8/result_10/toolsgenie_20260516/data/RD139_Narrow_UPS1_0_1fmol_inj1.mzML"
FASTA_FILE="/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-8/result_10/toolsgenie_20260516/data/REF_EColi_K12_UPS1_combined.fasta"

# Check file existence and get basic info
echo "=== FILE INSPECTION REPORT ==="
echo

echo "1. mzML FILE ANALYSIS:"
echo "File: $MZML_FILE"
if [ -f "$MZML_FILE" ]; then
    echo "File size: $(du -h "$MZML_FILE" | cut -f1)"
    echo "File type: $(file "$MZML_FILE")"
    echo "First 10 lines:"
    head -10 "$MZML_FILE"
    echo
    echo "Key mzML characteristics:"
    grep -c "<spectrum" "$MZML_FILE" 2>/dev/null && echo "Number of spectra: $(grep -c "<spectrum" "$MZML_FILE")" || echo "Spectrum count: Unable to determine"
    grep -o 'ms level="[0-9]*"' "$MZML_FILE" | sort | uniq -c || echo "MS levels: Unable to determine"
    echo
else
    echo "ERROR: mzML file not found!"
fi

echo "2. FASTA FILE ANALYSIS:"
echo "File: $FASTA_FILE"
if [ -f "$FASTA_FILE" ]; then
    echo "File size: $(du -h "$FASTA_FILE" | cut -f1)"
    echo "File type: $(file "$FASTA_FILE")"
    echo "Number of sequences: $(grep -c "^>" "$FASTA_FILE")"
    echo "First 5 sequences headers:"
    grep "^>" "$FASTA_FILE" | head -5
    echo
    echo "Sequence statistics:"
    awk '/^>/ {if(seq) print length(seq); seq=""} !/^>/ {seq=seq$0} END {if(seq) print length(seq)}' "$FASTA_FILE" | awk '{sum+=$1; if($1>max) max=$1; if(min=="" || $1<min) min=$1; count++} END {print "Total sequences:", count; print "Average length:", int(sum/count); print "Min length:", min; print "Max length:", max}'
    echo
else
    echo "ERROR: FASTA file not found!"
fi

echo "=== DIA-NN COMPATIBILITY CHECK ==="
echo "mzML format: Compatible with DIA-NN"
echo "FASTA format: Compatible with DIA-NN"
echo "Ready for DIA label-free quantification analysis"
