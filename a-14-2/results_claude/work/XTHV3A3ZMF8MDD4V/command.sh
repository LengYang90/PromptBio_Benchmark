import sys

# Read and analyze the PDB file
pdb_file = '/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-14-2/result_10/toolsgenie_20260516/data/protein.pdb'

chains = set()
residues = {}
ligands = {}
mtx_found = False
total_atoms = 0

with open(pdb_file, 'r') as f:
    for line in f:
        if line.startswith('ATOM') or line.startswith('HETATM'):
            total_atoms += 1
            chain = line[21]
            res_name = line[17:20].strip()
            res_id = line[22:26].strip()
            
            chains.add(chain)
            
            if line.startswith('HETATM'):
                if res_name == 'MTX':
                    mtx_found = True
                    if chain not in ligands:
                        ligands[chain] = {}
                    ligands[chain][res_id] = res_name
                else:
                    if chain not in ligands:
                        ligands[chain] = {}
                    ligands[chain][res_id] = res_name
            else:
                if chain not in residues:
                    residues[chain] = {}
                residues[chain][res_id] = res_name

print("=== PDB STRUCTURE ANALYSIS ===")
print(f"File: {pdb_file}")
print(f"Total atoms: {total_atoms}")
print(f"Number of chains: {len(chains)}")
print(f"Chains present: {sorted(list(chains))}")

print("\n=== CHAIN COMPOSITION ===")
for chain in sorted(chains):
    protein_residues = residues.get(chain, {})
    chain_ligands = ligands.get(chain, {})
    
    print(f"Chain {chain}:")
    print(f"  Protein residues: {len(protein_residues)}")
    if protein_residues:
        unique_res = set(protein_residues.values())
        print(f"  Residue types: {sorted(list(unique_res))}")
    
    if chain_ligands:
        print(f"  Ligands/heteroatoms: {len(chain_ligands)}")
        for res_id, res_name in chain_ligands.items():
            print(f"    {res_name} (ID: {res_id})")

print(f"\n=== MTX LIGAND STATUS ===")
if mtx_found:
    print("MTX ligand found in structure")
    for chain in sorted(chains):
        chain_ligands = ligands.get(chain, {})
        for res_id, res_name in chain_ligands.items():
            if res_name == 'MTX':
                print(f"  MTX located in chain {chain}, residue ID {res_id}")
else:
    print("MTX ligand NOT found in structure")
    print("Available ligands:")
    for chain in sorted(chains):
        chain_ligands = ligands.get(chain, {})
        for res_id, res_name in chain_ligands.items():
            print(f"  {res_name} in chain {chain} (ID: {res_id})")

print(f"\n=== SUMMARY ===")
total_protein_residues = sum(len(residues.get(chain, {})) for chain in chains)
total_ligands = sum(len(ligands.get(chain, {})) for chain in chains)
print(f"Total protein residues: {total_protein_residues}")
print(f"Total ligands/heteroatoms: {total_ligands}")
print(f"MTX present: {'Yes' if mtx_found else 'No'}")
