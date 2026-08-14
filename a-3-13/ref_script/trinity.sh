TASK_DIR="$(dirname "$(dirname "$0")")"
mkdir -p "$TASK_DIR/tmp" "$TASK_DIR/ref_answer"

Trinity \
    --seqType fq \
    --left  "$TASK_DIR/data/SRX9161265_SRR12681119_2k_1.fastq.gz" \
    --right "$TASK_DIR/data/SRX9161265_SRR12681119_2k_2.fastq.gz" \
    --CPU 16 \
    --output "$TASK_DIR/tmp/trinity_out"

cp "$TASK_DIR/tmp/trinity_out.Trinity.fasta" "$TASK_DIR/ref_answer/"
