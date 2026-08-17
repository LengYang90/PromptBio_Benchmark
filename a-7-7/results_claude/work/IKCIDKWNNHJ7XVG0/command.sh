# Create Comet parameter file for DDA peptide identification
cat > /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-7/result_10/toolsgenie_20260516/comet.params << 'EOF'
# Comet MS/MS search engine parameters file

# Database
database_name = /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-7/result_10/toolsgenie_20260516/data/18Protein_SoCe_Tr_detergents_trace_target_decoy.fasta
decoy_search = 2

# Masses
peptide_mass_tolerance = 20.00
peptide_mass_units = 2
mass_type_parent = 1
mass_type_fragment = 1
precursor_tolerance_type = 1
isotope_error = 1

# Fragment ions
fragment_bin_tol = 1.0005
fragment_bin_offset = 0.4
theoretical_fragment_ions = 1
use_A_ions = 0
use_B_ions = 1
use_C_ions = 0
use_X_ions = 0
use_Y_ions = 1
use_Z_ions = 0
use_NL_ions = 1

# Enzyme
search_enzyme_number = 1
num_enzyme_termini = 2
allowed_missed_cleavage = 2

# Modifications
variable_mod01 = 15.9949 M 0 3 -1 0 0
variable_mod02 = 42.0106 n 0 3 -1 0 0
static_mod01 = 57.021464 C 0 3 -1 0 0

# Output
output_sqtstream = 0
output_sqtfile = 0
output_txtfile = 1
output_pepxmlfile = 1
output_percolatorfile = 1
output_outfiles = 0
print_expect_score = 1
num_output_lines = 5

# Spectrum processing
minimum_peaks = 10
minimum_intensity = 0.0
remove_precursor_peak = 0
remove_precursor_tolerance = 1.5
clear_mz_range = 0.0 0.0

# Protein database
nucleotide_reading_frame = 0
mass_offsets = 0.0
precursor_charge = 0 0
override_charge = 0
ms_level = 2
activation_method = ALL

# Scoring
max_fragment_charge = 3
max_precursor_charge = 6
clip_nterm_methionine = 0
spectrum_batch_size = 0
minimum_xcorr = 0.0
EOF

echo "Comet parameter file created: /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-7/result_10/toolsgenie_20260516/comet.params"
echo ""
echo "=== Parameter Configuration Summary ==="
echo "Database: Target-decoy search enabled"
echo "Precursor tolerance: ±20 ppm"
echo "Fragment tolerance: 1.0005 Da"
echo "Enzyme: Trypsin with up to 2 missed cleavages"
echo "Static modifications: Carbamidomethyl cysteine (+57.021464)"
echo "Variable modifications: Oxidation methionine (+15.9949), Acetylation N-term (+42.0106)"
echo "Output formats: TXT, pepXML, Percolator"
echo ""
echo "Parameter file is ready for Comet search execution."
