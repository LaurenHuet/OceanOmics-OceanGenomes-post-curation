process CALCULATE_STATS {
    tag "$meta.id"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://quay.io/biocontainers/seqkit:2.8.2--h9ee0642_1' :
        'quay.io/biocontainers/seqkit:2.8.2--h9ee0642_1' }"

    input:
    tuple val(meta), path(hap1)
    tuple val(meta), path(hap2_new)

    output:
    tuple val(meta), path("*stats_output.txt"), emit: stats_output
    tuple val(meta), path ("*.percentage_stats_output.txt"), emit: percentage_stats
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    seqkit grep -r -p "SUPER" ${hap1} > ${prefix}.hap1_super.fa
    seqkit grep -r -v -p "SUPER" ${hap1} > ${prefix}.hap1.no_super.fa
    seqkit grep -r -p "SUPER" ${hap2_new} > ${prefix}.hap2_super.fa
    seqkit grep -r -v -p "SUPER" ${hap2_new} > ${prefix}.hap2.no_super.fa
    seqkit stats ${prefix}.hap1_super.fa ${prefix}.hap1.no_super.fa ${hap1} ${prefix}.hap2_super.fa ${prefix}.hap2.no_super.fa ${hap2_new} > ${prefix}.stats_output.txt

    bash ${moduleDir}/calculate_stats.sh "${prefix}.stats_output.txt" "${hap1}" "${hap2_new}"

    mv percentage_stats_output.txt ${prefix}.percentage_stats_output.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        seqkit: \$(seqkit version | sed 's/seqkit v//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch "${prefix}.stats_output.txt"
    touch "percentage_stats_output.txt"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        seqkit: \$(seqkit version | sed 's/seqkit v//')
    END_VERSIONS
    """
}