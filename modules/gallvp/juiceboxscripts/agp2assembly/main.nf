process JUICEBOXSCRIPTS_AGP2ASSEMBLY {
    tag "$meta.id"
    label 'process_single'

    // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/juicebox_scripts:0.1.0gita7ae991--hdfd78af_0':
        'biocontainers/juicebox_scripts:0.1.0gita7ae991--hdfd78af_0' }"

    input:
    tuple val(meta), path(agp)

    output:
    tuple val(meta), path("*.assembly") , emit: assembly
    path "versions.yml"                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def VERSION = '0.1.0'
    // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.
    """
    agp2assembly.py \\
        $args \\
        $agp \\
        ${prefix}.assembly

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        juicebox_scripts: $VERSION
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def VERSION = '0.1.0'
    // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.
    """
    echo $args

    touch ${prefix}.assembly

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        juicebox_scripts: $VERSION
    END_VERSIONS
    """
}
