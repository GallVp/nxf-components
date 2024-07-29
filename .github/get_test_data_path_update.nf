workflow {
    def sed_commands =  params.old_paths
        .tokenize('\n')
        .collect { it.trim() }
        .collect { sed_with_new_path ( it ) }
        .join('\n')

    def sed_file = file('sed_commands.sh')

    sed_file.text = '#!/usr/bin/env bash\n' + '\n' + sed_commands
}

def sed_with_new_path(old_path) {

    def new_path = params.test_data

    old_path
        .findAll(/\['(.*?)'\]/).collect { it[2..-3] }
        .each { literal ->
            new_path = new_path[literal]
        }

    def new_path_stem = new_path
        .replace('https://raw.githubusercontent.com/nf-core/test-datasets/modules/data/', '')

    def full_new_path="file(params.modules_testdata_base_path + '${new_path_stem}', checkIfExists: true)"
    def formatted_old_path = old_path.replaceAll(/\[/, '\\\\[').replaceAll(/\]/, '\\\\]')

    """sed -i "s|${formatted_old_path}|$full_new_path|g" $params.test_file"""
}
