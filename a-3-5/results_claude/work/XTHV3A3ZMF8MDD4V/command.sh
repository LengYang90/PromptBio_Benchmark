# Inspect BAM files using samtools
echo "=== BAM File Inspection ==="
echo "Sample 1 BAM file:"
samtools view -H /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-5/result_2/toolsgenie_20260430/data/sample_1.bam | head -20
echo ""
samtools flagstat /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-5/result_2/toolsgenie_20260430/data/sample_1.bam
echo ""
samtools idxstats /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-5/result_2/toolsgenie_20260430/data/sample_1.bam | head -10

echo ""
echo "Sample 2 BAM file:"
samtools view -H /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-5/result_2/toolsgenie_20260430/data/sample_2.bam | head -20
echo ""
samtools flagstat /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-5/result_2/toolsgenie_20260430/data/sample_2.bam
echo ""
samtools idxstats /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-5/result_2/toolsgenie_20260430/data/sample_2.bam | head -10

echo ""
echo "=== GTF Annotation File Inspection ==="
echo "First 20 lines of GTF file:"
head -20 /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-5/result_2/toolsgenie_20260430/data/annotation.gtf
echo ""
echo "GTF file structure summary:"
echo "Total lines:"
wc -l /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-5/result_2/toolsgenie_20260430/data/annotation.gtf
echo ""
echo "Feature types in GTF:"
awk '{print $3}' /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-5/result_2/toolsgenie_20260430/data/annotation.gtf | sort | uniq -c | sort -nr
echo ""
echo "Chromosomes/contigs in GTF:"
awk '{print $1}' /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-5/result_2/toolsgenie_20260430/data/annotation.gtf | sort | uniq -c | sort -nr | head -10
