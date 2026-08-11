#!/bin/bash
BAM="/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-1-10/result_714/toolsgenie_20260714/data/example_tumor.bam"
OUT="/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-1-10/result_714/toolsgenie_20260714/data/average_coverage.txt"

echo "=== 1. Index BAM ==="
samtools index "$BAM"

echo ""
echo "=== 2. Compute average depth over non-zero positions ==="
samtools depth "$BAM" | awk '{sum+=$3; count++} END {printf "%.4f\n", sum/count}' > "$OUT"

echo ""
echo "=== 3. Output file contents ==="
cat "$OUT"

echo ""
echo "=== Verification: non-zero positions, sum of depths, average ==="
samtools depth "$BAM" | awk '{sum+=$3; count++} END {print "Non-zero positions:", count; print "Sum of depths:", sum; print "Average:", sum/count}'

echo ""
echo "=== 4. samtools coverage (cross-validation) ==="
samtools coverage "$BAM"
