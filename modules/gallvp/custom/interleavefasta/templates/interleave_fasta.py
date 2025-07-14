#!/usr/bin/env python3

import re
from importlib.metadata import version
from platform import python_version

from Bio import SeqIO


def main():
    fasta_files_input = "$fastas"
    prefixes_input = "$fasta_prefixes"
    fasta_output_prefix = "$prefix"

    fasta_files = [f for f in re.split(r"[ ,;]", fasta_files_input) if f]
    prefixes = [p for p in re.split(r"[ ,;]", prefixes_input) if p]
    line_feed = "\\n"

    all_records = []
    all_ids = []
    for fasta in fasta_files:
        records = list(SeqIO.parse(str(fasta), "fasta"))
        all_records.append(records)
        all_ids.extend([rec.id for rec in records])

    n_records_per_fasta = [len(records) for records in all_records]
    max_n = max(n_records_per_fasta) if n_records_per_fasta else 0

    should_prefix = len(set(all_ids)) != len(all_ids)

    if should_prefix and (len(fasta_files) != len(prefixes)):
        raise ValueError(
            f"The number of prefixes ({len(prefixes)}) is not equal to the number of fasta files ({len(fasta_files)})!"
        )

    local_prefixes = prefixes if should_prefix else ["" for _ in range(0, len(fasta_files))]

    with open(f"{fasta_output_prefix}.fasta", "w") as out:
        for record_idx in range(max_n):
            for fasta_idx, fasta_records in enumerate(all_records):
                if record_idx < len(fasta_records):
                    rec = fasta_records[record_idx]
                    rec_id = f"{local_prefixes[fasta_idx]}{rec.id}"
                    out.write(f">{rec_id}{line_feed}{str(rec.seq)}{line_feed}")

    # Write versions
    with open("versions.yml", "w") as f_versions:
        f_versions.write('"${task.process}":\\n')
        f_versions.write(f"    python: {python_version()}{line_feed}")
        f_versions.write(f"    biopython: {version('biopython')}{line_feed}")


if __name__ == "__main__":
    main()
