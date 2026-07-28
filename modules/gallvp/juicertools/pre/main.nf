process JUICERTOOLS_PRE {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/juicertools:2.20.00--hdfd78af_0':
        'quay.io/biocontainers/juicertools:2.20.00--hdfd78af_0' }"

    input:
    tuple val(meta), path(txt)
    path(index)
    path(sizes)

    output:
    tuple val(meta), path("*.hic"), emit: hic
    tuple val("${task.process}"), val('juicertools'), eval("juicer_tools --version |& sed -n 's|Juicer Tools Version\\(.*\\)|\\1|p'"), topic: versions, emit: versions_juicertools

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def index_arg = index ? "-i $index" : ''
    def avail_mem = (task.memory.giga*0.8).intValue()
    """
    mkdir user_home
    export _JAVA_OPTIONS="-Djava.util.prefs.userRoot=user_prefs -Duser.home=user_home -Xms${avail_mem}g -Xmx${avail_mem}g"

    juicer_tools \\
        pre \\
        $args \\
        --threads $task.cpus \\
        $index_arg \\
        $txt \\
        ${prefix}.hic \\
        $sizes
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """

    touch ${prefix}.hic
    """
}
