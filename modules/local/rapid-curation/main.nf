process RAPID_CURATION {
    tag "$meta.id"
    label 'process_medium'

    //conda "${moduleDir}/environment.yml"
    container  "docker://sawtooth01/og_curation_agp:v0.1" // Container with Python, Biopython, pandas, and gfastats
    //container  "docker.io/sawtooth01/og_curation_agp:v0.1"

    input:
    tuple val(meta), path(fasta), path(agp)

    output:
    tuple val(meta), path("Hap_1"), emit: hap1_dir
    tuple val(meta), path("Hap_2"), emit: hap2_dir
    tuple val(meta), path("Hap_1/${meta.id}_hap1.chr_level.fa"), emit: hap1, optional: true
    tuple val(meta), path("Hap_2/${meta.id}_hap2.chr_level.fa"), emit: hap2, optional: true

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo hello > test.txt
    bash ${moduleDir}/curation_2.0_pipe.sh -f ${fasta}/* -a ${agp}/* -d ${moduleDir}

    # Rename the chr_level.fa files
    if [ -f Hap_1/hap.chr_level.fa ]; then
        mv Hap_1/hap.chr_level.fa Hap_1/${meta.id}_hap1.chr_level.fa
    fi
    if [ -f Hap_2/hap.chr_level.fa ]; then
        mv Hap_2/hap.chr_level.fa Hap_2/${meta.id}_hap2.chr_level.fa
    fi

    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p Hap_1 Hap_2 logs
    touch Hap_1/hap.agp Hap_1/hap.sorted.fa Hap_1/hap.unlocs.no_hapdups.agp Hap_1/hap.unlocs.no_hapdups.fa
    touch Hap_2/hap.agp Hap_2/hap.sorted.fa Hap_2/hap.unlocs.no_hapdups.agp Hap_2/hap.unlocs.no_hapdups.fa
    touch Hap_1/${meta.id}_hap1.chr_level.fa
    touch Hap_2/${meta.id}_hap2.chr_level.fa
    touch logs/std.0.out

    """
}