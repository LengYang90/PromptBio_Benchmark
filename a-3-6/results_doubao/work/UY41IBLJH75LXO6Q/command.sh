awk 'BEGIN {
    print "chr1,base1,strand1,chr2,base2,strand2,junction_type,read_name"
}
{
    print $1","$2","$3","$4","$5","$6","$7","$10
}' /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-6/result_11/toolsgenie_20260623/K562_Chimeric.out.junction > /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-6/result_11/toolsgenie_20260623/K562_candidate_fusions.csv
