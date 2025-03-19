process GNUSORT {
    tag "$meta.id"
    label 'process_low'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:20.04':
        'nf-core/ubuntu:20.04' }"

    input:
    tuple val(meta), path(input_file)

    output:
    tuple val(meta), path("*.${extension}")                   , emit: sorted
    path "versions.yml"                                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    extension = input_file.extension
    """
    sort --parallel=${task.cpus} \\
        $args \\
        $txt_file \\
        > ${prefix}.${extension}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sort: \$(sort --version | sed -n '/sort (GNU coreutils) / s/sort (GNU coreutils) //p')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    
    touch ${prefix}_sorted.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sort: \$(sort --version | sed -n '/sort (GNU coreutils) / s/sort (GNU coreutils) //p')
    END_VERSIONS
    """
}
