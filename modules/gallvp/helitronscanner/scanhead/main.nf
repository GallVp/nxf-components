process HELITRONSCANNER_SCANHEAD {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/helitronscanner:1.0--hdfd78af_0':
        'biocontainers/helitronscanner:1.0--hdfd78af_0' }"

    input:
    tuple val(meta), path(fasta)
    path lcv_filepath
    val buffer_size

    output:
    tuple val(meta), path("*.head") , emit: head
    path "versions.yml"             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args        = task.ext.args     ?: ''
    def prefix      = task.ext.prefix   ?: "${meta.id}"
    def lcv_arg     = lcv_filepath      ? "-lcv_filepath $lcv_filepath" : '-lcv_filepath $HELITRONSCANNER_TRAININGSET_PATH/head.lcvs'
    if ( !task.memory ) { error '[HELITRONSCANNER_SCANHEAD] Available memory not known. Specify process memory requirements to fix this.' }
    def avail_mem   = (task.memory.giga*0.8).intValue()
    """
    # Nextflow changes the container --entrypoint to /bin/bash (container default entrypoint: /usr/local/env-execute)
    # Check for container variable initialisation script and source it.
    if [ -f "/usr/local/env-activate.sh" ]; then
        set +u  # Otherwise, errors out because of various unbound variables
        . "/usr/local/env-activate.sh"
        set -u
    fi

    HelitronScanner \\
        scanHead \\
        -Xmx${avail_mem}g \\
        $lcv_arg \\
        -genome $fasta \\
        -buffer_size $buffer_size \\
        -threads_LCV $task.cpus \\
        $args \\
        -output ${prefix}.head

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        helitronscanner: \$(HelitronScanner |& sed -n 's/HelitronScanner V\\(.*\\)/V\\1/p')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.head

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        helitronscanner: \$(HelitronScanner |& sed -n 's/HelitronScanner V\\(.*\\)/V\\1/p')
    END_VERSIONS
    """
}
