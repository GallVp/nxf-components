#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

params.main_nf = null

workflow {

    if ( ! params.main_nf ) {
        error "param main_nf is null"
    }

    if ( ! params.test_data ) {
        error "param test_data is null"
    }

    def main_nf_file = file(params.main_nf, checkIfExists: true)
    def main_nf_text = main_nf_file.text

    def old_paths = main_nf_text
    .findAll(/file\s*\([^\)]*\)/)
    .collect { it.trim() }
    .findAll{ it.contains ('params.test_data') }

    old_paths.each {
        def updated_path = get_new_path ( it )
        main_nf_text = main_nf_text.replace(it, updated_path)
    }

    main_nf_file.text = main_nf_text
}

def get_new_path(old_path) {

    def old_path_literals = old_path.findAll(/\['(.*?)'\]/).collect { it[2..-3] }

    log.info("[INFO] Old path ${old_path}")
    log.info("[INFO] Old path literals: ${old_path_literals}")

    def new_path = params.test_data

    old_path_literals
        .each { literal ->
            new_path = new_path[literal]
        }

    def new_path_stem = new_path
        .replace('https://raw.githubusercontent.com/nf-core/test-datasets/modules/data/', '')

    def formatted_new_path = "file(params.modules_testdata_base_path + '${new_path_stem}', checkIfExists: true)"

    log.info("[INFO] New path ${formatted_new_path}")

    formatted_new_path
}
