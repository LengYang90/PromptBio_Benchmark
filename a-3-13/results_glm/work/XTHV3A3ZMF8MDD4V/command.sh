#!/bin/bash
set -e

F1="/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-13/result_714/toolsgenie_20260714/data/SRX9161265_SRR12681119_2k_1.fastq.gz"
F2="/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-13/result_714/toolsgenie_20260714/data/SRX9161265_SRR12681119_2k_2.fastq.gz"

for F in "$F1" "$F2"; do
  echo "===== File: $F ====="
  echo "--- First 2 reads (8 lines) ---"
  zcat "$F" | head -n 8
  echo "--- Total reads ---"
  zcat "$F" | awk 'NR%4==1' | wc -l
  echo "--- Read length distribution (count length) ---"
  zcat "$F" | awk 'NR%4==2{print length($0)}' | sort -n | uniq -c
  echo ""
done
