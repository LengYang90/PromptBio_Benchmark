#!/usr/bin/env python3
"""Convert OpenMS idXML peptide-spectrum matches to a flat TSV."""
import sys
import xml.etree.ElementTree as ET

def main():
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <input.idXML> <output.tsv>", file=sys.stderr)
        sys.exit(1)

    tree = ET.parse(sys.argv[1])
    root = tree.getroot()

    # Build map from ProteinHit id → accession
    ph_to_acc = {}
    for ph in root.iter("ProteinHit"):
        ph_to_acc[ph.attrib["id"]] = ph.attrib["accession"]

    with open(sys.argv[2], "w") as out:
        out.write("spectrum_id\tpeptide_sequence\tcharge\tprotein_accession\n")
        for pi in root.iter("PeptideIdentification"):
            spectrum_id = pi.attrib.get("spectrum_reference", "")
            for hit in pi.findall("PeptideHit"):
                sequence = hit.attrib.get("sequence", "")
                charge = hit.attrib.get("charge", "")
                refs = hit.attrib.get("protein_refs", "")
                accessions = ";".join(
                    ph_to_acc.get(r, r) for r in refs.split() if r
                )
                out.write(f"{spectrum_id}\t{sequence}\t{charge}\t{accessions}\n")

if __name__ == "__main__":
    main()
