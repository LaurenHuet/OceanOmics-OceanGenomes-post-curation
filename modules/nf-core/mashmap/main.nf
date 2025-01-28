process MASHMAP {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mashmap:3.1.3--h07ea13f_0':
        'biocontainers/mashmap:3.1.3--h07ea13f_0' }"

    input:
    tuple val(meta), path(hap1), path(hap2)

    output:
    tuple val(meta), path("*mashmap.out"), emit: mashmap_out
    tuple val(meta), path("*.hap2_hap1.tsv"), emit: hap2_hap1_ID
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mashmap -r ${hap1} \\
    -q ${hap2} \\
    -f one-to-one \\
    -t ${task.cpus} \\
    -s 50000 \\
    --legacy \\
    -o ${prefix}.mashmap.out \\

    cut -d " " -f1 ${prefix}.mashmap.out | grep -v SCAFFOLD | grep -v unloc | uniq > tmp;
    while read id; do
        awk -v val=\$id '\$1==val' ${prefix}.mashmap.out | awk '{print \$0 "\t" \$9 - \$8}' | sort -nrk11,11 | head -n1 ;
    done < tmp | awk '{print \$1 "\t" \$6}' > ${prefix}.hap2_hap1.tsv
    rm tmp

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mashmap: \$(mashmap --version 2>&1)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.mashmap.out
    touch ${prefix}.hap2_hap1.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mashmap: \$(mashmap --version 2>&1)
    END_VERSIONS
    """
}
