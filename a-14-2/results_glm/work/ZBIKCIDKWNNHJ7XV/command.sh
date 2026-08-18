from Bio.PDB import PDBParser, NeighborSearch
import csv

pdb_path = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-14-2/result_714/toolsgenie_20260714/data/protein.pdb"
out_path = "/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-14-2/result_714/toolsgenie_20260714/data/binding_sites.csv"

parser = PDBParser(QUIET=True)
structure = parser.get_structure("protein", pdb_path)

results = []

for chain in structure.get_chains():
    mtx_atoms = []
    protein_atoms = []
    for res in chain.get_residues():
        resname = res.resname.strip()
        if resname == "MTX":
            mtx_atoms.extend(list(res.get_atoms()))
        elif res.id[0] == " " and resname != "HOH":
            protein_atoms.extend(list(res.get_atoms()))

    if not mtx_atoms or not protein_atoms:
        continue

    ns = NeighborSearch(protein_atoms)
    contacted = set()
    for atom in mtx_atoms:
        for r in ns.search(atom.get_coord(), 4.0, level="R"):
            rid = r.id[1]
            if r.id[2] != " ":
                rid = f"{r.id[1]}{r.id[2]}"
            contacted.add((chain.id, rid, r.resname.strip()))

    results.extend(sorted(contacted, key=lambda x: (x[0], str(x[1]))))

print("Chain,Residue_ID,Residue_Name")
for r in results:
    print(f"{r[0]},{r[1]},{r[2]}")

with open(out_path, "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["Chain", "Residue_ID", "Residue_Name"])
    for r in results:
        writer.writerow([r[0], r[1], r[2]])

print(f"\nTotal contacting residues: {len(results)}")
print(f"Results written to: {out_path}")
