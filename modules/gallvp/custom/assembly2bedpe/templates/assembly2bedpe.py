#!/usr/bin/env python3

from importlib.metadata import version
from platform import python_version

NEWLINE_TOKEN = "\\n"
TAB_TOKEN = "\\t"

assembly_file_name = "$assembly"
args = "$args"  # Set -s for single scaffold 'assembly'
prefix = "$prefix"


def read_assembly_rows(assembly_file_name):
    with open(assembly_file_name) as file:
        lines = file.readlines()
    rows_of_cols = [line.replace(NEWLINE_TOKEN, "").split(" ") for line in lines]
    rows_of_three_cols = [cols for cols in rows_of_cols if len(cols) == 3]
    rows = []
    for x in rows_of_three_cols:
        rows.append({"name": x[0], "number": int(x[1]), "length": int(x[2])})
    return rows


def make_bedpe_rows(rows):
    cum_length = 0
    for i, entry in enumerate(rows):
        cum_length += entry["length"]
        entry["cum_length"] = cum_length
        entry["end_index"] = cum_length - 1
        if i == 0:
            entry["start_index"] = 0
        else:
            entry["start_index"] = rows[i - 1]["end_index"] + 1
    return rows


def write_bedpe(prefix, bed_pe_list, is_single_assembly_scaffold):
    with open(f"{prefix}.bedpe", "w") as f:
        f.write(
            f"chr1{TAB_TOKEN}x1{TAB_TOKEN}x2{TAB_TOKEN}chr2{TAB_TOKEN}y1{TAB_TOKEN}y2{TAB_TOKEN}name{TAB_TOKEN}score{TAB_TOKEN}strand1{TAB_TOKEN}strand2{TAB_TOKEN}color{NEWLINE_TOKEN}"
        )
        for row in bed_pe_list:
            scaffold_name = "assembly" if is_single_assembly_scaffold else row["name"][1:]
            f.write(
                f"{scaffold_name}{TAB_TOKEN}{row['start_index']}{TAB_TOKEN}{row['end_index']}{TAB_TOKEN}{scaffold_name}{TAB_TOKEN}{row['start_index']}{TAB_TOKEN}{row['end_index']}{TAB_TOKEN}{row['name'].replace('>', '')}{TAB_TOKEN}.{TAB_TOKEN}.{TAB_TOKEN}.{TAB_TOKEN}0,0,255{NEWLINE_TOKEN}"
            )


if __name__ == "__main__":
    rows = read_assembly_rows(assembly_file_name)
    bedpe_rows = make_bedpe_rows(rows)

    is_single_assembly_scaffold = "-s" in args

    write_bedpe(prefix, bedpe_rows, is_single_assembly_scaffold)

    with open("versions.yml", "w") as f_versions:
        f_versions.write('"${task.process}":\\n')
        f_versions.write(f"    python: {python_version()}{NEWLINE_TOKEN}")
        f_versions.write(f"    biopython: {version('biopython')}{NEWLINE_TOKEN}")
