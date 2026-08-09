nextflow.enable.dsl=2

process HIC2HTML {
    label 'process_single'
    container "docker.io/gallvp/python3npkgs:v0.7"

    input:
    path(hic_file)

    output:
    path "*.html"           , emit: html

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    file_name="$hic_file"
    hic2html.py "$hic_file" > "\${file_name%.*}.html"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | tr -d 'Python[:space:]')
    END_VERSIONS
    
    """
}
