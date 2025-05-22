process YAHS_JUICERPRE {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/yahs:1.2.2--h577a1d6_1':
        'biocontainers/yahs:1.2.2--h577a1d6_1' }"

    input:
    tuple val(meta), path(bam_or_bin)
    path(agp)
    path(fai)

    output:
    tuple val(meta), path("*.txt")          , emit: txt
    tuple val(meta), path("*.assembly")     , emit: assembly        , optional: true
    tuple val(meta), path("*.assembly.agp") , emit: assembly_agp    , optional: true
    tuple val(meta), path("*.liftover.agp") , emit: liftover_agp    , optional: true
    path "versions.yml"                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    juicer pre \\
        $args \\
        $bam_or_bin \\
        $agp \\
        $fai \\
        -o ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        yahs: \$(yahs --version)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """

    touch ${prefix}.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        yahs: \$(yahs --version)
    END_VERSIONS
    """
}
