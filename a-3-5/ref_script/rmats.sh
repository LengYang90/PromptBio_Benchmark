#!/usr/bin/env bash
set -euo pipefail
TASK_DIR="$(dirname "$(dirname "$0")")"
mkdir -p "$TASK_DIR/tmp"

echo "$TASK_DIR/data/sample_1.bam" > "$TASK_DIR/tmp/b1.txt"
echo "$TASK_DIR/data/sample_2.bam" > "$TASK_DIR/tmp/b2.txt"

python /rmats/rmats.py \
    --b1 "$TASK_DIR/tmp/b1.txt" \
    --b2 "$TASK_DIR/tmp/b2.txt" \
    --gtf "$TASK_DIR/data/annotation.gtf" \
    --od "$TASK_DIR/tmp/rmats_output" \
    --tmp "$TASK_DIR/tmp/rmats_temp" \
    -t paired --readLength 75 --nthread 8

cp "$TASK_DIR/tmp/rmats_output/A3SS.MATS.JC.txt" "$TASK_DIR/ref_answer/"
cp "$TASK_DIR/tmp/rmats_output/A5SS.MATS.JC.txt" "$TASK_DIR/ref_answer/"
cp "$TASK_DIR/tmp/rmats_output/SE.MATS.JC.txt" "$TASK_DIR/ref_answer/"
