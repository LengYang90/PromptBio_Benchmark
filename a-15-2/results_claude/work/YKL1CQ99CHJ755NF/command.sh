#!/bin/bash

# Check if mQTL_results.tsv exists in the output directory
output_file="/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_10/toolsgenie_20260516/mQTL_results.tsv"

if [ -f "$output_file" ]; then
    echo "mQTL_results.tsv found. Examining file contents:"
    echo "File size: $(stat -c%s "$output_file") bytes"
    echo "Number of lines: $(wc -l < "$output_file")"
    echo ""
    echo "First few lines:"
    head -n 10 "$output_file"
    echo ""
    echo "Column headers:"
    head -n 1 "$output_file" | tr '\t' '\n' | nl
    echo ""
    echo "Checking for required columns (term, response, celltype, estimate, statistic, p.value):"
    header=$(head -n 1 "$output_file")
    for col in "term" "response" "celltype" "estimate" "statistic" "p.value"; do
        if echo "$header" | grep -q "$col"; then
            echo "✓ $col column found"
        else
            echo "✗ $col column missing"
        fi
    done
    echo ""
    echo "Sample data rows:"
    tail -n +2 "$output_file" | head -n 5
else
    echo "mQTL_results.tsv does not exist in the output directory."
    echo "Expected location: $output_file"
    echo ""
    echo "Checking directory contents:"
    ls -la "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_10/toolsgenie_20260516/"
fi
