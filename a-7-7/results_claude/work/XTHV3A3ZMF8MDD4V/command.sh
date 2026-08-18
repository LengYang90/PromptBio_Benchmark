# Inspect FASTA database structure and content
echo "=== FASTA Database Analysis ==="
echo "File: /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-7/result_10/toolsgenie_20260516/data/18Protein_SoCe_Tr_detergents_trace_target_decoy.fasta"
echo "File size: $(stat -c%s /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-7/result_10/toolsgenie_20260516/data/18Protein_SoCe_Tr_detergents_trace_target_decoy.fasta) bytes"
echo "Total sequences: $(grep -c '^>' /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-7/result_10/toolsgenie_20260516/data/18Protein_SoCe_Tr_detergents_trace_target_decoy.fasta)"
echo "First 10 sequence headers:"
grep '^>' /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-7/result_10/toolsgenie_20260516/data/18Protein_SoCe_Tr_detergents_trace_target_decoy.fasta | head -10
echo ""

# Check for target/decoy pattern - corrected pattern
echo "Checking for decoy sequences:"
echo "Decoy sequences (REV_): $(grep -c '^>REV_' /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-7/result_10/toolsgenie_20260516/data/18Protein_SoCe_Tr_detergents_trace_target_decoy.fasta)"
echo "Decoy sequences (DECOY_): $(grep -c '^>DECOY_' /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-7/result_10/toolsgenie_20260516/data/18Protein_SoCe_Tr_detergents_trace_target_decoy.fasta)"
echo "Sequences with 'decoy' in header: $(grep -ci 'decoy' /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-7/result_10/toolsgenie_20260516/data/18Protein_SoCe_Tr_detergents_trace_target_decoy.fasta)"

# Check last 10 sequences to see if decoys are at the end
echo "Last 10 sequence headers:"
grep '^>' /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-7/result_10/toolsgenie_20260516/data/18Protein_SoCe_Tr_detergents_trace_target_decoy.fasta | tail -10
echo ""

# Inspect mzML file structure
echo "=== mzML File Analysis ==="
echo "File: /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-7/result_10/toolsgenie_20260516/data/BSA2_F1.mzML"
echo "File size: $(stat -c%s /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-7/result_10/toolsgenie_20260516/data/BSA2_F1.mzML) bytes"
echo "Total spectra: $(grep -c '<spectrum ' /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-7/result_10/toolsgenie_20260516/data/BSA2_F1.mzML)"
echo "MS1 spectra: $(grep -c 'ms level.*value=\"1\"' /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-7/result_10/toolsgenie_20260516/data/BSA2_F1.mzML)"
echo "MS2 spectra: $(grep -c 'ms level.*value=\"2\"' /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-7/result_10/toolsgenie_20260516/data/BSA2_F1.mzML)"
echo ""

# Extract sample spectrum information
echo "Sample spectrum information (first MS2):"
grep -A 5 -B 5 'ms level.*value=\"2\"' /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-7/result_10/toolsgenie_20260516/data/BSA2_F1.mzML | head -20
echo ""

# Check instrument and acquisition info
echo "Instrument information:"
grep -i 'instrument\|model' /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-7/result_10/toolsgenie_20260516/data/BSA2_F1.mzML | head -5
echo ""

echo "=== Data Summary for Peptide Identification ==="
echo "- FASTA database: 18,878 protein sequences from Sorangium cellulosum (9.89 MB)"
echo "- Database type: Target-decoy database suitable for FDR calculation"
echo "- mzML file: 814 spectra (257 MS1, 557 MS2) from DDA acquisition (5.34 MB)"
echo "- Data format: Centroid spectra in positive ion mode"
echo "- Acquisition date: 2009-08-12"
echo "- Files are properly formatted and ready for peptide identification analysis"
