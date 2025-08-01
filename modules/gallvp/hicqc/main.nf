process HICQC {
    tag "$meta.id"
    label 'process_single'

    container "ghcr.io/gallvp/hic_qc:v1.3.1"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.pdf")  , emit: pdf
    tuple val(meta), path("*.html") , emit: html
    path "versions.yml"             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "$meta.id"
    def args = task.ext.args ?: ''
    """
    mkdir -p matplotlib/config
    mkdir -p matplotlib/cache

    export MPLCONFIGDIR=./matplotlib/config
    export XDG_CACHE_HOME=./matplotlib/cache

    hic_qc \\
        $args \\
        -b $bam \\
        --outfile_prefix "$prefix"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hic_qc.py: \$(hic_qc --version)
    END_VERSIONS
    """

    stub:
    """
    touch "${meta.id}.pdf"
    touch "${meta.id}.html"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hic_qc.py: \$(hic_qc --version)
    END_VERSIONS
    """
}
