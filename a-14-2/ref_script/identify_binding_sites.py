import os
from Bio.PDB import PDBParser, NeighborSearch
from Bio.PDB.Polypeptide import PPBuilder
import io
import csv

task_dir = os.path.dirname(os.path.dirname(__file__))


def identify_binding_sites(pdb_content, ligand_resname="MTX", cutoff=4.0):
    """
    Identify protein residues involved in ligand binding from a PDB structure.

    This function parses a PDB file/content, identifies the ligand by its residue name,
    and finds all protein residues within a specified cutoff distance (in Angstroms)
    to any atom in the ligand.

    Args:
        pdb_content (str): The content of the PDB file as a string.
        ligand_resname (str): The three-letter code for the ligand residue (default 'MTX').
        cutoff (float): Distance cutoff for binding site residues (default 4.0 Å).

    Returns:
        list: List of tuples (chain_id, res_id, res_name) for binding site residues.
    """
    # Parse the PDB content
    parser = PDBParser(QUIET=True)
    structure = parser.get_structure("protein", io.StringIO(pdb_content))

    # Collect all ligand atoms
    ligand_atoms = []
    for model in structure:
        for chain in model:
            for residue in chain:
                if residue.get_resname() == ligand_resname:
                    ligand_atoms.extend(residue.get_atoms())

    if not ligand_atoms:
        raise ValueError(
            f"No ligand with resname '{ligand_resname}' found in the structure."
        )

    # Collect all protein atoms (excluding hetero atoms except the ligand)
    protein_atoms = []
    for model in structure:
        for chain in model:
            for residue in chain:
                if (
                    residue.get_id()[0] == " "
                    and residue.get_resname() != ligand_resname
                ):  # Standard residues
                    protein_atoms.extend(residue.get_atoms())

    # Use NeighborSearch to find close residues
    ns = NeighborSearch(protein_atoms)
    binding_residues = set()

    for lig_atom in ligand_atoms:
        nearby_atoms = ns.search(lig_atom.coord, cutoff)
        for atom in nearby_atoms:
            res = atom.get_parent()
            chain_id = res.get_parent().id
            res_id = res.get_id()[1]
            res_name = res.get_resname()
            binding_residues.add((chain_id, res_id, res_name))

    # Sort by chain and residue ID
    binding_residues = sorted(binding_residues, key=lambda x: (x[0], x[1]))

    return binding_residues


if __name__ == "__main__":
    with open(os.path.join(task_dir, "data", "protein.pdb"), "r") as f:
        pdb_content = f.read()

    try:
        binding_sites = identify_binding_sites(
            pdb_content, ligand_resname="MTX", cutoff=4.0
        )
        with open(os.path.join(task_dir, "ref_answer", "binding_sites.csv"), "w", newline="") as f:
            writer = csv.writer(f)
            writer.writerow(["Chain", "Residue_ID", "Residue_Name"])
            for chain, res_id, res_name in binding_sites:
                writer.writerow([chain, res_id, res_name])

    except ValueError as e:
        print(e)
