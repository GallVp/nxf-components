process CUSTOM_ASSEMBLY2BEDPE {
    tag "${meta.id}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/biopython:1.75':
        'biocontainers/biopython:1.75' }"

    input:
    tuple val(meta), path(assembly)

    output:
    tuple val(meta), path("*.bedpe"), emit: bedpe
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    template('assembly2bedpe.py')

    stub:
    args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo ${args}

    touch ${prefix}.bedpe

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | cut -d' ' -f2)
        biopython: \$(pip list | grep "biopython" | cut -d' ' -f3)
    END_VERSIONS
    """
}
