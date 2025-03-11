#!/usr/bin/env python

import sys
from pathlib import Path
import os


if __name__ == "__main__":
    hic_file_name = os.path.basename(sys.argv[1])

    projectDir = "/".join(__file__.split("/")[0:-1])
    html_template_path = Path(
        f"{projectDir}/hic/hic_html_template.html"
    )

    with open(html_template_path) as f:
        html_file_lines = "".join(f.readlines())

    filled_template = html_file_lines.replace(
        "HIC_FILE_NAME", 
        hic_file_name
    )
    filled_template = filled_template.replace(
        "BEDPE_FILE_NAME",
        f"{hic_file_name.replace('.hic', '')}.assembly.bedpe"
    )
    filled_template = filled_template.replace(
        "YAHS_BEDPE_NAME",
        f"{hic_file_name.replace('.hic', '')}.YAHS.bedpe"
    )
    filled_template = filled_template.replace(
        "REMOVED_BEDPE_NAME",
        f"{hic_file_name.replace('.hic', '')}.removed.contigs.bedpe"
    )
    print(filled_template)
