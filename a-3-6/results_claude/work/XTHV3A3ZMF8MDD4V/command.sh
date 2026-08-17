#!/bin/bash

# Inspect FASTQ files format, size, and basic statistics
echo "=== RNA-Seq FASTQ Files Inspection ==="
echo

# File paths
FILE1="/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-6/result_2/toolsgenie_20260430/data/K562f_1.fq.gz"
FILE2="/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-6/result_2/toolsgenie_20260430/data/K562f_2.fq.gz"

# Check if files exist and get basic info
echo "File Information:"
echo "=================="
ls -lh "$FILE1" "$FILE2"
echo

# Check file format and compression
echo "File Format Check:"
echo "=================="
file "$FILE1" "$FILE2"
echo

# Check if paired-end by examining file names
echo "Paired-end Status:"
echo "=================="
if [[ -f "$FILE1" && -f "$FILE2" ]]; then
    echo "✓ Paired-end FASTQ files detected (K562f_1.fq.gz and K562f_2.fq.gz)"
else
    echo "✗ Missing paired files"
fi
echo

# Get read counts and basic statistics
echo "Read Count Analysis:"
echo "==================="
echo "Forward reads (R1):"
READ_COUNT_1=$(zcat "$FILE1" | wc -l)
READS_1=$((READ_COUNT_1 / 4))
echo "  Total lines: $READ_COUNT_1"
echo "  Total reads: $READS_1"

echo "Reverse reads (R2):"
READ_COUNT_2=$(zcat "$FILE2" | wc -l)
READS_2=$((READ_COUNT_2 / 4))
echo "  Total lines: $READ_COUNT_2"
echo "  Total reads: $READS_2"
echo

# Sample first few reads to check format and quality
echo "Sample Read Format (First 2 reads from R1):"
echo "==========================================="
zcat "$FILE1" | head -8
echo

echo "Sample Read Format (First 2 reads from R2):"
echo "==========================================="
zcat "$FILE2" | head -8
echo

# Basic quality statistics
echo "Read Length Analysis:"
echo "===================="
echo "R1 read lengths (first 1000 reads):"
zcat "$FILE1" | awk 'NR%4==2 {print length($0)}' | head -1000 | sort -n | uniq -c | head -5

echo "R2 read lengths (first 1000 reads):"
zcat "$FILE2" | awk 'NR%4==2 {print length($0)}' | head -1000 | sort -n | uniq -c | head -5
echo

# Quality score preview
echo "Quality Score Preview (first read R1):"
echo "====================================="
zcat "$FILE1" | sed -n '4p' | head -1
echo

echo "Quality Score Preview (first read R2):"
echo "====================================="
zcat "$FILE2" | sed -n '4p' | head -1
echo

echo "=== Inspection Complete ==="
