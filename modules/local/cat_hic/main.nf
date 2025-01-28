process CAT_HIC {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/fastqc:0.12.1--hdfd78af_0' :
        'biocontainers/fastqc:0.12.1--hdfd78af_0' }"

    input:
    tuple val(meta), path(files)

    output:
    tuple val(meta), path("cat_files/*fastq.gz"), emit: cat_files
    path  "versions.yml"                        , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir cat_files
    cp $files/* .

    if [ "\$(ls *R1*fastq.gz 2>/dev/null | wc -l)" -gt 1 ]; then
        cat \\
            $args \\
            *R1*fastq.gz \\
            > cat_files/${prefix}.hic.R1.fastq.gz

        cat \\
            $args \\
            *R2*fastq.gz \\
            > cat_files/${prefix}.hic.R2.fastq.gz

    else
        mv *fastq.gz cat_files
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastqc: \$( fastqc --version | sed '/FastQC v/!d; s/.*v//' )
    END_VERSIONS
    """
}
