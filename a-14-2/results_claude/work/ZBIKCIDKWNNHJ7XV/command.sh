import math
import csv

# Parse PDB file and extract atomic coordinates
pdb_file = '/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-14-2/result_10/toolsgenie_20260516/data/protein.pdb'
output_file = '/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-14-2/result_10/toolsgenie_20260516/binding_sites.csv'

# Store coordinates for MTX atoms and protein residues
mtx_atoms = []
protein_residues = {}

with open(pdb_file, 'r') as f:
    for line in f:
        if line.startswith('ATOM') or line.startswith('HETATM'):
            chain = line[21]
            res_name = line[17:20].strip()
            res_id = int(line[22:26].strip())
            x = float(line[30:38].strip())
            y = float(line[38:46].strip())
            z = float(line[46:54].strip())
            
            if line.startswith('HETATM') and res_name == 'MTX':
                mtx_atoms.append((x, y, z))
            elif line.startswith('ATOM'):
                if (chain, res_id) not in protein_residues:
                    protein_residues[(chain, res_id)] = {'name': res_name, 'atoms': []}
                protein_residues[(chain, res_id)]['atoms'].append((x, y, z))

# Find protein residues within 4.0 Angstroms of MTX
binding_residues = []
cutoff = 4.0

for (chain, res_id), residue_data in protein_residues.items():
    res_name = residue_data['name']
    res_atoms = residue_data['atoms']
    
    # Check if any atom in this residue is within cutoff distance of any MTX atom
    is_binding = False
    for res_atom in res_atoms:
        for mtx_atom in mtx_atoms:
            distance = math.sqrt(sum((a - b)**2 for a, b in zip(res_atom, mtx_atom)))
            if distance <= cutoff:
                is_binding = True
                break
        if is_binding:
            break
    
    if is_binding:
        binding_residues.append({'Chain': chain, 'Residue_ID': res_id, 'Residue_Name': res_name})

# Sort by chain and residue ID
binding_residues.sort(key=lambda x: (x['Chain'], x['Residue_ID']))

# Write to CSV
with open(output_file, 'w', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=['Chain', 'Residue_ID', 'Residue_Name'])
    writer.writeheader()
    writer.writerows(binding_residues)

print(f"Found {len(binding_residues)} protein residues within {cutoff} Angstroms of MTX ligands")
print(f"Results saved to: {output_file}")
