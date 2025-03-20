process MATLOCK_BAM2JUICER {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/matlock:20181227--h665f8ca_8':
        'biocontainers/matlock:20181227--h665f8ca_8' }"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.links.txt")    , emit: links_txt
    path "versions.yml"                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def VERSION = '20181227'
    """
    matlock \\
        bam2 \\
        juicer \\
        $bam \\
        ${prefix}.links.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        matlock: $VERSION
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def VERSION = '20181227'
    """
    touch ${prefix}.links.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        matlock: $VERSION
    END_VERSIONS
    """
}
