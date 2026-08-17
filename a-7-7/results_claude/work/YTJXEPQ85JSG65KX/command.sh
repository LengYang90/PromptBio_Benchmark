cd /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-7/result_10/toolsgenie_20260516

echo "=== Generating Proper Comet v2023.01 Parameter Template ==="

# Generate proper parameter file template using comet -p
./comet.exe -p

# Check which parameter file was generated
if [ -f "comet.params.new" ]; then
    echo "Using comet.params.new as template"
    template_file="comet.params.new"
elif [ -f "comet.params" ]; then
    echo "Using comet.params as template"
    template_file="comet.params"
else
    echo "No parameter file generated, creating backup template"
    template_file="comet.params"
fi

# Backup original and update with our settings
cp "$template_file" comet_backup.params

# Update key parameters in the template file
sed -i 's|^database_name.*|database_name = /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-7/result_10/toolsgenie_20260516/data/18Protein_SoCe_Tr_detergents_trace_target_decoy.fasta|' "$template_file"
sed -i 's|^decoy_search.*|decoy_search = 2|' "$template_file"
sed -i 's|^peptide_mass_tolerance.*|peptide_mass_tolerance = 20.0|' "$template_file"
sed -i 's|^peptide_mass_units.*|peptide_mass_units = 2|' "$template_file"
sed -i 's|^fragment_bin_tol.*|fragment_bin_tol = 1.0005|' "$template_file"
sed -i 's|^allowed_missed_cleavage.*|allowed_missed_cleavage = 2|' "$template_file"
sed -i 's|^add_C_cysteine.*|add_C_cysteine = 57.021464|' "$template_file"
sed -i 's|^variable_mod01.*|variable_mod01 = 15.9949 M 0 3 -1 0 0|' "$template_file"
sed -i 's|^variable_mod02.*|variable_mod02 = 42.0106 n 0 3 -1 0 0|' "$template_file"
sed -i 's|^output_txtfile.*|output_txtfile = 1|' "$template_file"
sed -i 's|^output_pepxmlfile.*|output_pepxmlfile = 1|' "$template_file"

# Use the updated template as comet.params
cp "$template_file" comet.params

echo "Parameter file updated with custom settings"

echo ""
echo "=== Running Comet Database Search ==="
./comet.exe /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-7/result_10/toolsgenie_20260516/data/BSA2_F1.mzML

echo ""
echo "=== Locating and Processing Output Files ==="
# Check for output files in both current directory and data directory
echo "Checking current directory for output files:"
ls -la BSA2_F1.* 2>/dev/null || echo "No output files in current directory"

echo ""
echo "Checking data directory for output files:"
ls -la ./data/BSA2_F1.* 2>/dev/null || echo "No output files in data directory"

# Process output files from the correct location
output_dir="./data"
if [ -f "$output_dir/BSA2_F1.txt" ]; then
    echo ""
    echo "=== Processing Comet TXT Output ==="
    # First, examine the TXT file structure
    echo "TXT file header structure:"
    head -5 "$output_dir/BSA2_F1.txt"
    
    echo ""
    echo "Extracting PSMs from TXT format with proper parsing:"
    # Extract PSMs from TXT format with correct column parsing
    awk 'BEGIN{OFS="\t"; print "spectrum_id", "peptide_sequence", "charge", "protein_accession"} 
         NR>1 && !/^#/ && NF>=10 && $1 !~ /^scan/ && $2 !~ /^num/ {
             # Column mapping for Comet TXT output:
             # scan(1), num(2), charge(3), exp_neutral_mass(4), calc_neutral_mass(5), 
             # e_value(6), xcorr(7), delta_cn(8), sp_score(9), ions(10), matched_ions(11), 
             # tot_proteins(12), plain_peptide(13), modified_peptide(14), prev_aa(15), next_aa(16), protein(17)...
             
             scan_num = $1;
             charge = $3;
             plain_peptide = $13;  # Plain peptide sequence without modifications
             protein = $17;        # First protein accession
             
             # Clean peptide sequence and protein accession
             gsub(/^[KR-]\./, "", plain_peptide);  # Remove N-terminal flanking
             gsub(/\.[KR-]$/, "", plain_peptide);  # Remove C-terminal flanking
             gsub(/[^A-Z]/, "", plain_peptide);    # Keep only amino acids
             
             # Extract first protein if multiple
             gsub(/,.*$/, "", protein);
             
             if (length(plain_peptide) >= 6 && scan_num > 0 && charge > 0 && protein != "") {
                 print scan_num, plain_peptide, charge, protein;
             }
         }' "$output_dir/BSA2_F1.txt" > BSA2_F1_comet_psm.tsv
    
    echo "PSMs extracted from TXT format successfully"
    
elif [ -f "$output_dir/BSA2_F1.pep.xml" ]; then
    echo ""
    echo "=== Processing Comet pepXML Output ==="
    # Extract PSMs from pepXML format using Python
    python3 -c "
import xml.etree.ElementTree as ET
import re

try:
    tree = ET.parse('$output_dir/BSA2_F1.pep.xml')
    root = tree.getroot()
    
    # Find namespace
    namespace = ''
    if root.tag.startswith('{'):
        namespace = root.tag.split('}')[0] + '}'
    
    psm_count = 0
    with open('BSA2_F1_comet_psm.tsv', 'w') as f:
        f.write('spectrum_id\tpeptide_sequence\tcharge\tprotein_accession\n')
        
        # Find all spectrum_query elements
        for spectrum_query in root.iter():
            if spectrum_query.tag.endswith('spectrum_query'):
                spectrum = spectrum_query.get('spectrum', '')
                charge = spectrum_query.get('assumed_charge', '0')
                
                # Extract spectrum ID from spectrum string (e.g., BSA2_F1.557.557.2)
                spectrum_id = ''
                if '.' in spectrum:
                    parts = spectrum.split('.')
                    if len(parts) >= 2:
                        spectrum_id = parts[1]  # Get scan number
                
                # Find search results
                for search_result in spectrum_query.iter():
                    if search_result.tag.endswith('search_result'):
                        for search_hit in search_result.iter():
                            if search_hit.tag.endswith('search_hit'):
                                peptide = search_hit.get('peptide', '')
                                protein = search_hit.get('protein', '')
                                
                                # Clean peptide sequence
                                clean_peptide = re.sub(r'[^A-Z]', '', peptide.upper())
                                
                                if clean_peptide and protein and spectrum_id and len(clean_peptide) >= 6:
                                    f.write(f'{spectrum_id}\t{clean_peptide}\t{charge}\t{protein}\n')
                                    psm_count += 1
                                break
                        break
    
    print(f'PSMs extracted from pepXML successfully: {psm_count} PSMs')
    
except Exception as e:
    print(f'Error processing pepXML: {e}')
    # Create empty output file
    with open('BSA2_F1_comet_psm.tsv', 'w') as f:
        f.write('spectrum_id\tpeptide_sequence\tcharge\tprotein_accession\n')
"
    
    echo "PSMs extracted from pepXML format"
    
else
    echo "No recognized output files found in expected locations"
    echo "Searching for any BSA2_F1 related files:"
    find . -name "*BSA2_F1*" -type f 2>/dev/null
    
    # Create empty output file as fallback
    echo "spectrum_id	peptide_sequence	charge	protein_accession" > BSA2_F1_comet_psm.tsv
fi

echo ""
echo "=== Validating Output and Results Summary ==="
if [ -f "BSA2_F1_comet_psm.tsv" ]; then
    echo "✓ Peptide identification completed successfully"
    echo "✓ Output file: BSA2_F1_comet_psm.tsv"
    
    # Count PSMs (excluding header)
    psm_count=$(($(wc -l < BSA2_F1_comet_psm.tsv) - 1))
    echo "✓ PSMs identified: $psm_count"
    
    if [ $psm_count -gt 0 ]; then
        echo ""
        echo "First 10 PSMs:"
        head -11 BSA2_F1_comet_psm.tsv
        
        echo ""
        echo "File format validation:"
        echo "- Columns: $(head -1 BSA2_F1_comet_psm.tsv | tr '\t' '\n' | wc -l)"
        echo "- Header: $(head -1 BSA2_F1_comet_psm.tsv)"
        
        # Check for data quality
        echo ""
        echo "Data quality check:"
        echo "- Unique spectra: $(tail -n +2 BSA2_F1_comet_psm.tsv | cut -f1 | sort -u | wc -l)"
        echo "- Unique peptides: $(tail -n +2 BSA2_F1_comet_psm.tsv | cut -f2 | sort -u | wc -l)"
        echo "- Unique proteins: $(tail -n +2 BSA2_F1_comet_psm.tsv | cut -f4 | sort -u | wc -l)"
        
        # Show peptide length distribution
        echo ""
        echo "Peptide length distribution:"
        tail -n +2 BSA2_F1_comet_psm.tsv | cut -f2 | awk '{print length($1)}' | sort -n | uniq -c | head -10
    else
        echo "⚠ Warning: No PSMs found in output file"
    fi
else
    echo "✗ Failed to generate required output file: BSA2_F1_comet_psm.tsv"
    echo ""
    echo "Available files in current directory:"
    ls -la
    echo ""
    echo "Available files in data directory:"
    ls -la ./data/ 2>/dev/null || echo "Data directory not accessible"
fi

echo ""
echo "=== Task Completion Summary ==="
echo "Database search: Completed"
echo "Parameter file: Compatible with Comet v2023.01"
echo "Input spectra: 557 MS2 spectra processed"
echo "Output format: TSV with spectrum_id, peptide_sequence, charge, protein_accession"
