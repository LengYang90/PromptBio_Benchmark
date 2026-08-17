#!/bin/bash

# Create sample group files for rMATS
echo "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-5/result_2/toolsgenie_20260430/data/sample_1.bam" > /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-5/result_2/toolsgenie_20260430/group1.txt
echo "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-5/result_2/toolsgenie_20260430/data/sample_2.bam" > /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-5/result_2/toolsgenie_20260430/group2.txt

# Create temporary directory for rMATS
mkdir -p /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-5/result_2/toolsgenie_20260430/tmp

# Run rMATS analysis
rmats.py \
  --b1 /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-5/result_2/toolsgenie_20260430/group1.txt \
  --b2 /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-5/result_2/toolsgenie_20260430/group2.txt \
  --gtf /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-5/result_2/toolsgenie_20260430/data/annotation.gtf \
  --od /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-5/result_2/toolsgenie_20260430 \
  --tmp /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-5/result_2/toolsgenie_20260430/tmp \
  -t paired \
  --readLength 100 \
  --variable-read-length \
  --nthread 4

# List generated JC output files
echo "Generated rMATS JC output files:"
ls -la /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-5/result_2/toolsgenie_20260430/*.MATS.JC.txt

# Display summary of alternative splicing events
echo ""
echo "Summary of alternative splicing events detected:"
for file in /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-5/result_2/toolsgenie_20260430/*.MATS.JC.txt; do
    if [ -f "$file" ]; then
        echo "File: $(basename $file)"
        echo "Total events: $(tail -n +2 $file | wc -l)"
        echo ""
    fi
done
