process HICTK_ZOOMIFY {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hictk:2.1.4--h061aaa5_0':
        'biocontainers/hictk:2.1.4--h061aaa5_0' }"

    input:
    tuple val(meta), path(hic)

    output:
    tuple val(meta), path("*.hic"), emit: hic
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}.zoomify"
    if( "$hic" == "${prefix}.hic" ) error "Input and output names are the same, use \"task.ext.prefix\" to disambiguate!"
    """
    hictk \\
        zoomify \\
        $args \\
        --threads $task.cpus \\
        --tmpdir ./ \\
        $hic \\
        ${prefix}.hic

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hictk: \$(hictk --version)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}.zoomify"
    if( "$hic" == "${prefix}.hic" ) error "Input and output names are the same, use \"task.ext.prefix\" to disambiguate!"
    """
    echo $args

    touch ${prefix}.hic

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hictk: \$(hictk --version)
    END_VERSIONS
    """
}
