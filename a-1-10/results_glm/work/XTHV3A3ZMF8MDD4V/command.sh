#!/bin/bash
BAM="/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-1-10/result_714/toolsgenie_20260714/data/example_tumor.bam"

echo "=== 1. BAM Header (samtools view -H) ==="
samtools view -H "$BAM"

echo ""
echo "=== 2. Total Read Count (samtools view -c) ==="
samtools view -c "$BAM"

echo ""
echo "=== 3. Index File (.bai) Check ==="
if [ -f "${BAM}.bai" ]; then
    echo "FOUND: ${BAM}.bai"
elif [ -f "${BAM%.bam}.bai" ]; then
    echo "FOUND: ${BAM%.bam}.bai"
else
    echo "NOT FOUND: no .bai index file located next to the BAM"
fi

echo ""
echo "=== 4. idxstats (chromosomes and read counts) ==="
samtools idxstats "$BAM"
