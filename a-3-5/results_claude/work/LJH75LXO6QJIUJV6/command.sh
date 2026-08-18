# Examine SE.MATS.JC.txt content and format
echo "=== SE.MATS.JC.txt Content and Format ==="
cat /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-5/result_2/toolsgenie_20260430/SE.MATS.JC.txt

echo ""
echo "=== Headers and Format Verification for All *.MATS.JC.txt Files ==="

# Check headers of all MATS.JC.txt files
for file in /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-5/result_2/toolsgenie_20260430/*.MATS.JC.txt; do
    echo "File: $(basename $file)"
    echo "Header line:"
    head -n 1 "$file"
    echo "Number of columns: $(head -n 1 "$file" | tr '\t' '\n' | wc -l)"
    echo "File size: $(wc -c < "$file") bytes"
    echo "Total lines: $(wc -l < "$file")"
    echo ""
done

# Display detailed column information for SE.MATS.JC.txt
echo "=== Detailed SE.MATS.JC.txt Column Information ==="
head -n 1 /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-5/result_2/toolsgenie_20260430/SE.MATS.JC.txt | tr '\t' '\n' | nl

echo ""
echo "=== SE.MATS.JC.txt Data Values ==="
tail -n +2 /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-3-5/result_2/toolsgenie_20260430/SE.MATS.JC.txt
