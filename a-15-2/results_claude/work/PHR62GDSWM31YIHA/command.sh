find /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_10/toolsgenie_20260516 -type f \( -name "*.tsv" -o -name "*.csv" \) -print
find /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_10/toolsgenie_20260516 -type f \( -iname "*mQTL*" -o -iname "*results*" -o -iname "*ctcisQTL*" \) -print
ls -la /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_10/toolsgenie_20260516/*.tsv 2>/dev/null || echo "No TSV files found in root directory"
ls -la /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-15-2/result_10/toolsgenie_20260516/mQTL_results.tsv 2>/dev/null || echo "mQTL_results.tsv not found"
