TASK_DIR="$(dirname "$(dirname "$0")")"
mkdir -p "$TASK_DIR/tmp" "$TASK_DIR/ref_answer"

STAR \
    --runThreadN 8 \
    --genomeDir "$TASK_DIR/data/STARIndex" \
    --readFilesIn "$TASK_DIR/data/K562f_1.fq.gz" "$TASK_DIR/data/K562f_2.fq.gz" \
    --readFilesCommand zcat \
    --chimSegmentMin 15 \
    --chimOutType Junctions \
    --outSAMtype BAM SortedByCoordinate \
    --outFileNamePrefix "$TASK_DIR/tmp/K562_"

cp "$TASK_DIR/tmp/K562_Chimeric.out.junction" "$TASK_DIR/ref_answer/"

awk 'BEGIN {FS="\t"; OFS=","; print "chr1,base1,strand1,chr2,base2,strand2,junction_type,read_name"} \
     {print $1,$2,$3,$4,$5,$6,$7,$9}' \
    "$TASK_DIR/ref_answer/K562_Chimeric.out.junction" \
    > "$TASK_DIR/ref_answer/K562_candidate_fusions.csv"
