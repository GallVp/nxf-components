#!/usr/bin/env python3

from importlib.metadata import version
from platform import python_version

LIFTOVER_AGP = "$liftover_agp"
PREFIX = "$prefix"

TAB_TOKEN = "\\t"
NEWLINE_TOKEN = "\\n"


def parse_agp(agp_file):
    rows = []
    with open(agp_file) as f:
        for line in f:
            if line.startswith("#") or not line.strip():
                continue
            parts = line.strip().split(f"{TAB_TOKEN}")
            if len(parts) < 9:
                continue

            obj = parts[0]
            obj_start = int(parts[1])
            obj_end = int(parts[2])
            name = parts[5]
            rows.append(
                {
                    "name": name,
                    "obj": obj,
                    "start": obj_start,
                    "end": obj_end,
                    "length": obj_end - obj_start + 1,  # AGP is a 1-based end-inclusive system
                }
            )
    return rows


def write_assembly(prefix, rows):
    with open(f"{prefix}.assembly", "w") as f:
        for row in rows:
            f.write(f">{row['name']} {row['start']} {row['end']}{NEWLINE_TOKEN}")

        for i, _ in enumerate(rows):
            f.write(f"{i + 1}{NEWLINE_TOKEN}")


def make_bedpe_rows(rows):
    cum_length = 0
    for i, entry in enumerate(rows):
        cum_length += entry["length"]
        entry["cum_length"] = cum_length
        entry["end_index"] = cum_length  # The bed system is 0-based, end-exclusive
        if i == 0:
            entry["start_index"] = 0
        else:
            entry["start_index"] = rows[i - 1]["end_index"]
    return rows


def write_bedpe(prefix, bed_pe_list):
    with open(f"{prefix}.bedpe", "w") as f:
        f.write(
            f"chr1{TAB_TOKEN}x1{TAB_TOKEN}x2{TAB_TOKEN}chr2{TAB_TOKEN}y1{TAB_TOKEN}y2{TAB_TOKEN}name{TAB_TOKEN}score{TAB_TOKEN}strand1{TAB_TOKEN}strand2{TAB_TOKEN}color{NEWLINE_TOKEN}"
        )
        for row in bed_pe_list:
            scaffold_name = "assembly"
            f.write(
                f"{scaffold_name}{TAB_TOKEN}{row['start_index']}{TAB_TOKEN}{row['end_index']}{TAB_TOKEN}{scaffold_name}{TAB_TOKEN}{row['start_index']}{TAB_TOKEN}{row['end_index']}{TAB_TOKEN}{row['name'][1:]}{TAB_TOKEN}.{TAB_TOKEN}.{TAB_TOKEN}.{TAB_TOKEN}0,0,255{NEWLINE_TOKEN}"
            )


def write_bed(prefix, bed_pe_list):
    with open(f"{prefix}.bed", "w") as f:
        f.write(f"chrom{TAB_TOKEN}chromStart{TAB_TOKEN}chromEnd{TAB_TOKEN}name{NEWLINE_TOKEN}")
        for row in bed_pe_list:
            scaffold_name = "assembly"
            f.write(
                f"{scaffold_name}{TAB_TOKEN}{row['start_index']}{TAB_TOKEN}{row['end_index']}{TAB_TOKEN}{row['name'][1:]}{NEWLINE_TOKEN}"
            )


def main():
    rows = parse_agp(f"{LIFTOVER_AGP}")
    write_assembly(f"{PREFIX}", rows)

    bedpe_rows = make_bedpe_rows(rows)

    write_bedpe(f"{PREFIX}", bedpe_rows)
    write_bed(f"{PREFIX}", bedpe_rows)

    # Write versions
    with open("versions.yml", "w") as f_versions:
        f_versions.write('"${{task.process}}":' + f"{NEWLINE_TOKEN}")
        f_versions.write(f"    python: {python_version()}{NEWLINE_TOKEN}")
        f_versions.write(f"    biopython: {version('biopython')}{NEWLINE_TOKEN}")


if __name__ == "__main__":
    main()
