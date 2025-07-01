#!/usr/bin/env python3

from importlib.metadata import version
from platform import python_version

from Bio import SeqIO

fasta1 = "$fasta1"
fasta2 = "$fasta2"
fasta1_prefix = "$fasta1_prefix"
fasta2_prefix = "$fasta2_prefix"
fasta_output_prefix = "$prefix"
line_feed = "\\n"


def main():
    fasta1_records = list(SeqIO.parse(str(fasta1), "fasta"))
    fasta2_records = list(SeqIO.parse(str(fasta2), "fasta"))

    fasta1_ids = {rec.id for rec in fasta1_records}
    fasta2_ids = {rec.id for rec in fasta2_records}
    n_fasta1 = len(fasta1_records)
    n_fasta2 = len(fasta2_records)
    max_n = max(n_fasta1, n_fasta2)

    should_prefix = bool(fasta1_ids & fasta2_ids)
    fasta1_prefix_local = fasta1_prefix if should_prefix else ""
    fasta2_prefix_local = fasta2_prefix if should_prefix else ""

    with open(f"{fasta_output_prefix}.fasta", "w") as out:
        for i in range(max_n):
            if i < n_fasta1:
                rec = fasta1_records[i]
                rec_id = f"{fasta1_prefix_local}{rec.id}"
                out.write(f">{rec_id}{line_feed}{str(rec.seq)}{line_feed}")
            if i < n_fasta2:
                rec = fasta2_records[i]
                rec_id = f"{fasta2_prefix_local}{rec.id}"
                out.write(f">{rec_id}{line_feed}{str(rec.seq)}{line_feed}")

    # Write versions
    with open("versions.yml", "w") as f_versions:
        f_versions.write('"${task.process}":\\n')
        f_versions.write(f"    python: {python_version()}\\n")
        f_versions.write(f"    biopython: {version('biopython')}\\n")


if __name__ == "__main__":
    main()
