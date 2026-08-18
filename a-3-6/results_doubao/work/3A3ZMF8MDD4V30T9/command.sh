STAR --genomeDir /mnt/data/ims/genome/references/wts/STARIndex/ \
--sjdbGTFfile /mnt/data/ims/genome/references/wts/Annotation/ref_annot.gtf \
--readFilesIn /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-6/result_11/toolsgenie_20260623/data/K562f_1.fq.gz /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-6/result_11/toolsgenie_20260623/data/K562f_2.fq.gz \
--readFilesCommand zcat \
--outFileNamePrefix /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-6/result_11/toolsgenie_20260623/K562_ \
--chimSegmentMin 12 \
--chimJunctionOverhangMin 12 \
--chimOutType Junctions \
--outSAMtype None
