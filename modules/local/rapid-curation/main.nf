process RAPID_CURATION {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "docker://sawtooth01/og_curation_agp:v0.1" // Container with Python, Biopython, pandas, and gfastats

    input:
    tuple val(meta), path(fasta), path(agp)

    output:
    tuple val(meta), path("Hap_1"), emit: hap1_dir
    tuple val(meta), path("Hap_2"), emit: hap2_dir
    tuple val(meta), path("Hap_1/hap.chr_level.fa"), emit: hap1_chr_level_fa, optional: true
    tuple val(meta), path("Hap_2/hap.chr_level.fa"), emit: hap2_chr_level_fa, optional: true
    tuple val(meta), path("Hap_1/hap.agp"), emit: hap1_agp
    tuple val(meta), path("Hap_2/hap.agp"), emit: hap2_agp
    tuple val(meta), path("Hap_1/haplotigs.agp"), emit: hap1_haplotigs_agp, optional: true
    tuple val(meta), path("Hap_2/haplotigs.agp"), emit: hap2_haplotigs_agp, optional: true
    tuple val(meta), path("Hap_1/hap.sorted.fa"), emit: hap1_sorted_fa
    tuple val(meta), path("Hap_2/hap.sorted.fa"), emit: hap2_sorted_fa
    tuple val(meta), path("Hap_1/hap.unlocs.no_hapdups.agp"), emit: hap1_unlocs_no_hapdups_agp
    tuple val(meta), path("Hap_2/hap.unlocs.no_hapdups.agp"), emit: hap2_unlocs_no_hapdups_agp
    tuple val(meta), path("Hap_1/hap.unlocs.no_hapdups.fa"), emit: hap1_unlocs_no_hapdups_fa
    tuple val(meta), path("Hap_2/hap.unlocs.no_hapdups.fa"), emit: hap2_unlocs_no_hapdups_fa
    tuple val(meta), path("Hap_1/inter_chr.tsv"), emit: hap1_inter_chr_tsv, optional: true
    tuple val(meta), path("Hap_2/inter_chr.tsv"), emit: hap2_inter_chr_tsv, optional: true
    path "logs/std.*.out", emit: logs
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    export SING="${task.container}"
    bash ${moduleDir}/curation_2.0_pipe.sh -f ${fasta} -a ${agp}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        biopython: \$(python -c "import Bio; print(Bio.__version__)")
        pandas: \$(python -c "import pandas; print(pandas.__version__)")
        gfastats: \$(gfastats --version | sed 's/gfastats v//g')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p Hap_1 Hap_2 logs
    touch Hap_1/hap.agp Hap_1/hap.sorted.fa Hap_1/hap.unlocs.no_hapdups.agp Hap_1/hap.unlocs.no_hapdups.fa
    touch Hap_2/hap.agp Hap_2/hap.sorted.fa Hap_2/hap.unlocs.no_hapdups.agp Hap_2/hap.unlocs.no_hapdups.fa
    touch logs/std.0.out

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        biopython: \$(python -c "import Bio; print(Bio.__version__)")
        pandas: \$(python -c "import pandas; print(pandas.__version__)")
        gfastats: \$(gfastats --version | sed 's/gfastats v//g')
    END_VERSIONS
    """
}