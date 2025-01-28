process UPDATE_MAPPING {
    tag "$meta.id"
    label 'process_single'

    //conda "${moduleDir}/environment.yml"
    container "docker://ruby:3.3.7-slim-bookworm"

    input:
    tuple val(meta), path(hap2), path(hap2_hap1_ID)

    output:
    tuple val(meta), path("*hap2.chr_level_new.fa"), emit : hap2_new
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
        def prefix = task.ext.prefix ?: "${meta.id}"
    
    """
    echo "ModuleDir: ${moduleDir}" > moduledir.log
    ruby ${moduleDir}/update_mapping.rb -f ${hap2} -t ${hap2_hap1_ID} -dir ${moduleDir} > ${prefix}.hap2.chr_level_new.fa 

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        updatemapping: \$(samtools --version |& sed '1!d ; s/samtools //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    
    """
    touch ${prefix}.hap2.chr_level_new.fa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        updatemapping: \$(samtools --version |& sed '1!d ; s/samtools //')
    END_VERSIONS
    """
}
