process CUT {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/fastqc:0.12.1--hdfd78af_0' :
        'biocontainers/fastqc:0.12.1--hdfd78af_0' }"

    input:
    tuple val(meta), path(files)
    val(suffix)

    output:
    tuple val(meta), path("cut_file/*"), emit: cut_file
    path  "versions.yml"               , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir cut_file
    cut \\
        $args \\
        $files \\
        > cut_file/${prefix}.${suffix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cut: \$( cut --version | head -n 1 | sed 's/cut (GNU coreutils)//g' )
    END_VERSIONS
    """
}
