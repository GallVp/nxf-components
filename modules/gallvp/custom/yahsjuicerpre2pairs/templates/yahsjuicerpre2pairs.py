#!/usr/bin/env python3

import sys
from datetime import datetime
from importlib.metadata import version
from platform import python_version

SIZES_FILE = "$sizes"
DATA_FILE = "$tsv"
OUTPUT_PREFIX = "$prefix"
TAB_DELIMITER = "\\t"
NEWLINE_DELIMITER = "\\n"


def parse_sizes_file(sizes_path):
    chromsizes = []
    with open(sizes_path) as f:
        for line in f:
            if line.strip():
                chrom, size = line.strip().split()
                chromsizes.append(f"#chromsize: {chrom} {size}")
    return chromsizes


def build_header(chromsize_lines):
    header = [
        "## pairs format v1.0",
        "#sorted: none",
    ]
    header.extend(chromsize_lines)
    header.append("#columns: readID chr1 pos1 chr2 pos2 strand1 strand2")
    return f"{NEWLINE_DELIMITER}".join(header)


def process_data_and_write(data_path, output_path):
    with open(data_path) as f_in, open(output_path, "a") as f_out:
        sys.stdout.write(f"[INFO][{datetime.now()}] Started processing input lines")
        for idx, line in enumerate(f_in, 1):
            if not line.strip():
                continue

            if idx % 10_000 == 0:
                sys.stdout.write(f"[INFO][{datetime.now()}] Processing line {idx}{NEWLINE_DELIMITER}")

            fields = line.strip().split(f"{TAB_DELIMITER}")
            if len(fields) != 8:
                sys.stderr.write(f"[Error][{datetime.now()}] Line {idx} does not have 8 fields{NEWLINE_DELIMITER}")
                sys.exit(1)
            read_id = f"read{idx}"
            # The field selection is based on https://github.com/c-zhou/yahs/blob/6c46061ea1665073068cccbed81c6707e3bd07bf/juicer.c#L419-L422 and https://github.com/aidenlab/juicer/wiki/Pre#short-with-score-format
            frag1 = fields[3]
            if frag1 == "0":
                chr1 = fields[1]
                pos1 = fields[2]
                chr2 = fields[5]
                pos2 = fields[6]
            else:
                chr2 = fields[1]
                pos2 = fields[2]
                chr1 = fields[5]
                pos1 = fields[6]
            strand1 = "+"
            strand2 = "-"
            f_out.write(
                f"{read_id}{TAB_DELIMITER}{chr1}{TAB_DELIMITER}{pos1}{TAB_DELIMITER}{chr2}{TAB_DELIMITER}{pos2}{TAB_DELIMITER}{strand1}{TAB_DELIMITER}{strand2}{NEWLINE_DELIMITER}"
            )


def main():
    chromsize_lines = parse_sizes_file(SIZES_FILE)
    header = build_header(chromsize_lines)
    output_path = f"{OUTPUT_PREFIX}.pairs"

    with open(output_path, "w") as f:
        f.write(f"{header}{NEWLINE_DELIMITER}")

    process_data_and_write(DATA_FILE, output_path)

    # Write versions
    with open("versions.yml", "w") as f_versions:
        f_versions.write('"${{task.process}}":' + f"{NEWLINE_DELIMITER}")
        f_versions.write(f"    python: {python_version()}{NEWLINE_DELIMITER}")
        f_versions.write(f"    biopython: {version('biopython')}{NEWLINE_DELIMITER}")


if __name__ == "__main__":
    main()
