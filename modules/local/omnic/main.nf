process OMNIC {
    tag "$meta.id"
    label 'process_medium'

    //conda "${moduleDir}/environment.yml"
    container "docker://sawtooth01/omnic:v0.01"

    input:
    tuple val(meta), path(reads), path(assembly)
    val(haplotype)
    val(tempdir)

    output:
    tuple val(meta), path("*.stats.txt"), emit: omnic_stats
    tuple val(meta), path("*.mapped.PT.bam"), emit: omnic_bam
    tuple val(meta), path("*.mapped.PT.bam.bai"), emit: omnic_bai
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
        def prefix = task.ext.prefix ?: "${meta.id}"
    
    """
    export PATH=$PATH:/opt/conda/envs/pairtools/bin
    samtools faidx ${assembly} \
    && cut -f1,2 *.fai > "${meta.id}.${haplotype}.genome" \
    && bwa index ${assembly} \
    && bwa mem -5SP -T0 -t64 ${assembly} ${reads} -o "${meta.id}.${haplotype}.aligned.sam" \
    && pairtools parse --min-mapq 40 --walks-policy 5unique --max-inter-align-gap 30 --nproc-in 32 --nproc-out 32 --chroms-path "${meta.id}.${haplotype}.genome" "${meta.id}.${haplotype}.aligned.sam" >  "${meta.id}.${haplotype}.parsed.pairsam" \
    && pairtools sort --nproc 32 --tmpdir=${tempdir} "${meta.id}.${haplotype}.parsed.pairsam" > "${meta.id}.${haplotype}.sorted.pairsam" \
    && pairtools dedup --nproc-in 32 --nproc-out 32 --mark-dups --output-stats "${meta.id}.${haplotype}.stats.txt" --output "${meta.id}.${haplotype}.dedup.pairsam" "${meta.id}.${haplotype}.sorted.pairsam" \
    && pairtools split --nproc-in 32 --nproc-out 32 --output-pairs "${meta.id}.${haplotype}.mapped.pairs" --output-sam "${meta.id}.${haplotype}.unsorted.bam" "${meta.id}.${haplotype}.dedup.pairsam" \
    && samtools sort -@32 -T  "${tempdir}/${meta.id}_temp.bam" -o "${meta.id}.${haplotype}.mapped.PT.bam" "${meta.id}.${haplotype}.unsorted.bam" \
    && samtools index "${meta.id}.${haplotype}.mapped.PT.bam"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        updatemapping: \$(samtools --version |& sed '1!d ; s/samtools //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    
    """
    touch "${meta.id}.stats.txt"
    touch "${meta.id}.mapped.PT.bam"
    touch "${meta.id}.mapped.PT.bam.bai"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        updatemapping: \$(samtools --version |& sed '1!d ; s/samtools //')
    END_VERSIONS
    """
}
