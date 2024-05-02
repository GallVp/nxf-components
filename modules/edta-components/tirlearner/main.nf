process TIRLEARNER {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/tir-learner:3.0.1--hdfd78af_0':
        'biocontainers/tir-learner:3.0.1--hdfd78af_0' }"

    input:
    tuple val(meta), path(fasta)
    val species

    output:
    tuple val(meta), path("${prefix}.fa")           , emit: fasta
    tuple val(meta), path("${prefix}.gff3")         , emit: gff
    tuple val(meta), path("${prefix}.filtered.fa")  , emit: filtered_fasta
    tuple val(meta), path("${prefix}.filtered.gff3"), emit: filtered_gff
    path "versions.yml"                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args    = task.ext.args     ?: ''
    prefix      = task.ext.prefix   ?: "${meta.id}"
    if ( "$fasta" == "${prefix}.fa" ) error "Input and output names are the same, use \"task.ext.prefix\" to disambiguate!"
    """
    TIR-Learner \\
        -f $fasta \\
        -s $species \\
        -t $task.cpus \\
        -o $prefix \\
        $args

    mv "${prefix}/TIR-Learner-Result/TIR-Learner_FinalAnn.fa"           "${prefix}.fa"
    mv "${prefix}/TIR-Learner-Result/TIR-Learner_FinalAnn.gff3"         "${prefix}.gff3"

    mv "${prefix}/TIR-Learner-Result/TIR-Learner_FinalAnn_filter.fa"    "${prefix}.filtered.fa"
    mv "${prefix}/TIR-Learner-Result/TIR-Learner_FinalAnn_filter.gff3"  "${prefix}.filtered.gff3"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        TIR-Learner: \$(TIR-Learner -v | head -n 1 | sed 's/TIR-Learner //')
    END_VERSIONS
    """

    stub:
    def args    = task.ext.args ?: ''
    prefix      = task.ext.prefix ?: "${meta.id}"
    if ( "$fasta" == "${prefix}.fa" ) error "Input and output names are the same, use \"task.ext.prefix\" to disambiguate!"
    """
    touch "${prefix}.fa"
    touch "${prefix}.gff3"

    touch "${prefix}.filtered.fa"
    touch "${prefix}.filtered.gff3"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        TIR-Learner: \$(TIR-Learner -v | head -n 1 | sed 's/TIR-Learner //')
    END_VERSIONS
    """
}
