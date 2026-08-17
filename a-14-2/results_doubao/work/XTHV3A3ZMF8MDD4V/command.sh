from Bio.PDB import PDBParser, NeighborSearch
from Bio.PDB.Polypeptide import is_aa
import csv

# Define paths
PDB_FILE = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-14-2/result_11/toolsgenie_20260623/data/protein.pdb"
OUTPUT_FILE = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-14-2/result_11/toolsgenie_20260623/binding_sites.csv"

# Parse PDB structure
parser = PDBParser()
structure = parser.get_structure("target_protein", PDB_FILE)

# Collect MTX ligand atoms and standard amino acid atoms
mtx_atoms = []
protein_atoms = []
for model in structure:
    for chain in model:
        for residue in chain:
            res_name = residue.get_resname().strip()
            if res_name == "MTX":
                mtx_atoms.extend(residue.get_atoms())
            elif is_aa(residue, standard=True):
                protein_atoms.extend(residue.get_atoms())

# Find contact residues within 4.0 angstroms
neighbor_search = NeighborSearch(protein_atoms)
contact_res_set = set()

for atom in mtx_atoms:
    nearby_residues = neighbor_search.search(atom.get_coord(), 4.0, level="R")
    for res in nearby_residues:
        chain_id = res.get_parent().get_id()
        res_seq_num = str(res.get_id()[1])
        insert_code = res.get_id()[2].strip()
        res_id = f"{res_seq_num}{insert_code}" if insert_code else res_seq_num
        contact_res_set.add((chain_id, res_id, res.get_resname().strip()))

# Write to output CSV
with open(OUTPUT_FILE, "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["Chain", "Residue_ID", "Residue_Name"])
    for entry in sorted(contact_res_set):
        writer.writerow(entry)
