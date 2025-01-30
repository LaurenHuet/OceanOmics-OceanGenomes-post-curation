process BUSCO_BUSCO {
    tag "$meta.id"
    label 'process_medium'
    scratch true

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://ezlabgva/busco:v5.7.1_cv1':
        'biocontainers/busco:5.8.2--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(fasta, stageAs:'tmp_input/*')
    val mode                              // Required:    One of genome, proteins, or transcriptome
    path busco_lineages_path              // Recommended: busco lineages file - downloads if not set
    path config_file                      // Optional:    busco configuration file

    output:
    tuple val(meta), path("*-busco.batch_summary.txt")                , emit: batch_summary
    tuple val(meta), path("short_summary.*.txt")                      , emit: short_summaries_txt   , optional: true
    tuple val(meta), path("short_summary.*.json")                     , emit: short_summaries_json  , optional: true
    tuple val(meta), path("*-busco/*/run_*/full_table.tsv")           , emit: full_table            , optional: true
    tuple val(meta), path("*-busco/*/run_*/missing_busco_list.tsv")   , emit: missing_busco_list    , optional: true
    tuple val(meta), path("busco_downloads/lineages/*")               , emit: downloaded_lineages   , optional: true

    path "versions.yml"                                               , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    if ( mode !in [ 'genome', 'proteins', 'transcriptome' ] ) {
        error "Mode must be one of 'genome', 'proteins', or 'transcriptome'."
    }
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def busco_config = config_file ? "--config $config_file" : ''

    """
    # Nextflow changes the container --entrypoint to /bin/bash (container default entrypoint: /usr/local/env-execute)
    # Check for container variable initialisation script and source it.
    if [ -f "/usr/local/env-activate.sh" ]; then
        set +u  # Otherwise, errors out because of various unbound variables
        . "/usr/local/env-activate.sh"
        set -u
    fi

    # If the augustus config directory is not writable, then copy to writeable area
    if [ ! -w "\${AUGUSTUS_CONFIG_PATH}" ]; then
        # Create writable tmp directory for augustus
        AUG_CONF_DIR=\$( mktemp -d -p \$PWD )
        cp -r \$AUGUSTUS_CONFIG_PATH/* \$AUG_CONF_DIR
        export AUGUSTUS_CONFIG_PATH=\$AUG_CONF_DIR
        echo "New AUGUSTUS_CONFIG_PATH=\${AUGUSTUS_CONFIG_PATH}"
    fi

    # Ensure the input is uncompressed
    INPUT_SEQS=input_seqs
    mkdir "\$INPUT_SEQS"
    cd "\$INPUT_SEQS"
    for FASTA in ../tmp_input/*; do
        if [ "\${FASTA##*.}" == 'gz' ]; then
            gzip -cdf "\$FASTA" > \$( basename "\$FASTA" .gz )
        else
            ln -s "\$FASTA" .
        fi
    done
    cd ..

    busco \\
        --cpu $task.cpus \\
        --in "\$INPUT_SEQS" \\
        --out ${prefix}-busco \\
        --mode $mode \\
        --lineage_dataset ./$busco_lineages_path \\
        $busco_config \\
        $args

    # clean up
    rm -rf "\$INPUT_SEQS"

    # Move files to avoid staging/publishing issues
    mv ${prefix}-busco/batch_summary.txt ${prefix}-busco.batch_summary.txt
    mv ${prefix}-busco/*/short_summary.*.{json,txt} . || echo "Short summaries were not available: No genes were found."

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        busco: \$( busco --version 2>&1 | sed 's/^BUSCO //' )
    END_VERSIONS
    """

    stub:
    def prefix      = task.ext.prefix ?: "${meta.id}-${lineage}"
    def fasta_name  = files(fasta).first().name - '.gz'
    """
    touch ${prefix}-busco.batch_summary.txt
    mkdir -p ${prefix}-busco/$fasta_name/run_${lineage}/busco_sequences

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        busco: \$( busco --version 2>&1 | sed 's/^BUSCO //' )
    END_VERSIONS
    """
}
