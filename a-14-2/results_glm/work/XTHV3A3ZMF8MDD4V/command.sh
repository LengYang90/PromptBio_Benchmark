from Bio.PDB import PDBParser

pdb_path = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-14-2/result_714/toolsgenie_20260714/data/protein.pdb"

parser = PDBParser(QUIET=True)
structure = parser.get_structure("protein", pdb_path)

chains = list(structure.get_chains())
chain_ids = [c.id for c in chains]
n_chains = len(chains)

residues_per_chain = {}
mtx_chains = []
total_atoms = 0

for chain in chains:
    residues = list(chain.get_residues())
    residues_per_chain[chain.id] = len(residues)
    for res in residues:
        if res.resname.strip() == "MTX":
            mtx_chains.append(chain.id)
    total_atoms += len(list(chain.get_atoms()))

mtx_chains = sorted(set(mtx_chains))
mtx_exists = len(mtx_chains) > 0

print("=== PDB Summary ===")
print(f"File: {pdb_path}")
print(f"Total chains: {n_chains}")
print(f"Chain IDs: {chain_ids}")
print("Residues per chain:")
for cid, n in residues_per_chain.items():
    print(f"  Chain {cid}: {n} residues")
print(f"MTX ligand exists: {mtx_exists}")
if mtx_exists:
    print(f"MTX in chain(s): {mtx_chains}")
print(f"Total atom count: {total_atoms}")
