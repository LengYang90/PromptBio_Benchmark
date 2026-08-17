# Fix Comet parameter file compatibility issue and run database search
cd /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-7/result_10/toolsgenie_20260516

echo "=== Fixing Comet Parameter File Compatibility ==="

# Download Comet binary if not already present
if [ ! -f "comet.exe" ]; then
    echo "Downloading Comet binary..."
    if command -v wget &> /dev/null; then
        wget -O comet.exe "https://github.com/UWPR/Comet/releases/download/v2023.01.0/comet.linux.exe" 2>/dev/null
    elif command -v curl &> /dev/null; then
        curl -L -o comet.exe "https://github.com/UWPR/Comet/releases/download/v2023.01.0/comet.linux.exe" 2>/dev/null
    fi
    chmod +x comet.exe
fi

# Generate a new parameter file template compatible with Comet v2023.01
echo "Generating compatible parameter file..."
./comet.exe -p > /dev/null 2>&1

# Check if comet.params.new was created (default name for new parameter files)
if [ -f "comet.params.new" ]; then
    mv comet.params.new comet_template.params
elif [ -f "comet.params" ]; then
    # If comet.exe overwrote the existing file, use it as template
    cp comet.params comet_template.params
fi

# Create updated parameter file with our specific settings
cat > comet.params << 'EOF'
# Comet MS/MS search engine parameters file
# Compatible with Comet v2023.01

# Database
database_name = /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-7/result_10/toolsgenie_20260516/data/18Protein_SoCe_Tr_detergents_trace_target_decoy.fasta
decoy_search = 2                    # 0=no, 1=concatenated search, 2=separate search

# Masses
peptide_mass_tolerance = 20.00
peptide_mass_units = 2              # 0=amu, 1=mmu, 2=ppm
mass_type_parent = 1                # 0=average masses, 1=monoisotopic masses
mass_type_fragment = 1              # 0=average masses, 1=monoisotopic masses
precursor_tolerance_type = 1        # 0=MH+ (default), 1=precursor m/z
isotope_error = 3                   # 0=off, 1=0/1 (C13 error), 2=0/1/2, 3=0/1/2/3, 4=0/1/2/3/4

# Fragment ions
fragment_bin_tol = 1.0005
fragment_bin_offset = 0.4
theoretical_fragment_ions = 1       # 0=use flanking peaks, 1=M peak only
use_A_ions = 0
use_B_ions = 1
use_C_ions = 0
use_X_ions = 0
use_Y_ions = 1
use_Z_ions = 0
use_NL_ions = 1                     # 0=no, 1=yes to consider NH3/H2O neutral loss peaks

# Enzyme
search_enzyme_number = 1            # 1=Trypsin
num_enzyme_termini = 2              # 1=semi-enzymatic, 2=fully-enzymatic
allowed_missed_cleavage = 2

# Modifications (static)
add_Cterm_peptide = 0.0000
add_Nterm_peptide = 0.0000
add_Cterm_protein = 0.0000
add_Nterm_protein = 0.0000

add_G_glycine = 0.0000
add_A_alanine = 0.0000
add_S_serine = 0.0000
add_P_proline = 0.0000
add_V_valine = 0.0000
add_T_threonine = 0.0000
add_C_cysteine = 57.021464          # Carbamidomethyl
add_L_leucine = 0.0000
add_I_isoleucine = 0.0000
add_N_asparagine = 0.0000
add_D_aspartic_acid = 0.0000
add_Q_glutamine = 0.0000
add_K_lysine = 0.0000
add_E_glutamic_acid = 0.0000
add_M_methionine = 0.0000
add_H_histidine = 0.0000
add_F_phenylalanine = 0.0000
add_R_arginine = 0.0000
add_Y_tyrosine = 0.0000
add_W_tryptophan = 0.0000
add_B_user_amino_acid = 0.0000
add_J_user_amino_acid = 0.0000
add_O_ornithine = 0.0000
add_U_user_amino_acid = 0.0000
add_X_user_amino_acid = 0.0000
add_Z_user_amino_acid = 0.0000

# Variable modifications
variable_mod01 = 15.9949 M 0 3 -1 0 0     # Oxidation methionine
variable_mod02 = 42.0106 n 0 3 -1 0 0     # Acetylation N-terminus
variable_mod03 = 0.0000 X 0 3 -1 0 0
variable_mod04 = 0.0000 X 0 3 -1 0 0
variable_mod05 = 0.0000 X 0 3 -1 0 0
variable_mod06 = 0.0000 X 0 3 -1 0 0
variable_mod07 = 0.0000 X 0 3 -1 0 0
variable_mod08 = 0.0000 X 0 3 -1 0 0
variable_mod09 = 0.0000 X 0 3 -1 0 0

max_variable_mods_in_peptide = 5

# Fragment ions
require_variable_mod = 0

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

# Additional parameters
nucleotide_reading_frame = 0
mass_offsets = 0.0
precursor_charge = 0 0
override_charge = 0
ms_level = 2
activation_method = ALL
max_fragment_charge = 3
max_precursor_charge = 6
clip_nterm_methionine = 0
spectrum_batch_size = 0
minimum_xcorr = 0.0

# Spectral processing
max_duplicate_proteins = 20
skip_researching = 1
max_num_internal_cleavage_sites = 5
EOF

echo "Updated parameter file created successfully."

echo ""
echo "=== Verifying Input Files ==="
if [ ! -f "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-7/result_10/toolsgenie_20260516/data/BSA2_F1.mzML" ]; then
    echo "Error: Input mzML file not found!"
    exit 1
fi

if [ ! -f "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-7/result_10/toolsgenie_20260516/comet.params" ]; then
    echo "Error: Parameter file not found!"
    exit 1
fi

echo "Input files verified successfully."

echo ""
echo "=== Running Comet Database Search ==="
./comet.exe -P/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-7/result_10/toolsgenie_20260516/comet.params /mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-7-7/result_10/toolsgenie_20260516/data/BSA2_F1.mzML

if [ $? -ne 0 ]; then
    echo "Error: Comet execution failed!"
    exit 1
fi

echo ""
echo "=== Checking Generated Output Files ==="
ls -la BSA2_F1.*

echo ""
echo "=== Output File Summary ==="
output_found=false

for ext in txt pep.xml pin sqt; do
    if [ -f "BSA2_F1.$ext" ]; then
        echo "$ext file: $(wc -l < BSA2_F1.$ext) lines"
        output_found=true
    fi
done

if [ "$output_found" = false ]; then
    echo "Warning: No output files found. Checking current directory contents:"
    ls -la
else
    echo "Comet database search completed successfully with output files generated."
fi

echo ""
echo "=== Search Completion Summary ==="
echo "Comet version: 2023.01"
echo "Input spectra: BSA2_F1.mzML"
echo "Database: 18Protein_SoCe_Tr_detergents_trace_target_decoy.fasta"
echo "Search type: Target-decoy"
echo "Output files ready for PSM extraction and formatting."
