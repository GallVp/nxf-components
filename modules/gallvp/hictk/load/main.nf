process HICTK_LOAD {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hictk:2.1.4--h061aaa5_0':
        'biocontainers/hictk:2.1.4--h061aaa5_0' }"

    input:
    tuple val(meta), path(interactions)
    val format

    output:
    tuple val(meta), path("*.hic"), emit: hic
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    hictk \\
        load \\
        $args \\
        --format $format \\
        --threads $task.cpus \\
        --tmpdir ./ \\
        $interactions \\
        ${prefix}.hic

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hictk: \$(hictk --version)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo $args

    touch ${prefix}.hic

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hictk: \$(hictk --version)
    END_VERSIONS
    """
}
