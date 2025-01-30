/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { RAPID_CURATION            } from '../modules/local/rapid-curation/'
include { MASHMAP                   } from '../modules/nf-core/mashmap/main'
include { UPDATE_MAPPING            } from '../modules/local/update-mapping'
include { BUSCO_BUSCO               } from '../modules/nf-core/busco/busco/main'
include { MERQURY_MERQURY           } from '../modules/nf-core/merqury/merqury/main'
include { GFASTATS as GFASTATS_HAP1 } from '../modules/nf-core/gfastats/main'
include { GFASTATS as GFASTATS_HAP2 } from '../modules/nf-core/gfastats/main'
include { CALCULATE_STATS           } from '../modules/local/calculate_stats/main'
include { CAT_HIC                   } from '../modules/local/cat_hic/main'
include { OMNIC as OMNIC_HAP1       } from '../modules/local/omnic/main'
include { OMNIC as OMNIC_HAP2       } from '../modules/local/omnic/main'
include { PRETEXTMAP as PRETEXTMAP_HAP_1  } from '../modules/nf-core/pretextmap/main'
include { PRETEXTMAP as PRETEXTMAP_HAP_2   } from '../modules/nf-core/pretextmap/main'
include { PRETEXTSNAPSHOT as PRETEXTSNAPSHOT_HAP1  } from '../modules/nf-core/pretextsnapshot/main' 
include { PRETEXTSNAPSHOT as PRETEXTSNAPSHOT_HAP2  } from '../modules/nf-core/pretextsnapshot/main' 
include { MULTIQC                   } from '../modules/nf-core/multiqc/main'
include { paramsSummaryMap          } from 'plugin/nf-validation'
include { paramsSummaryMultiqc      } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML    } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText    } from '../subworkflows/local/utils_nfcore_postcuration_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow POSTCURATION {

    take:
    ch_samplesheet // channel: samplesheet read in from --input

    main:

    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()

    ///
    /// Create input channels
    ///
    ch_hic = ch_samplesheet
    .map {
        meta ->
            meta = meta[0]
            meta.id = meta.sample + "_" + meta.date + "." + meta.version
            return [ meta, meta.hic_dir ]
    }

    ch_assembly = ch_samplesheet
    .map {
        meta ->
            meta = meta[0]
            meta.id = meta.sample + "_" + meta.date + "." + meta.version
            return [ meta, meta.assembly ]
    }

    ch_agp = ch_samplesheet
    .map {
        meta -> 
            meta = meta[0]
            meta.id = meta.sample + "_" + meta.date + "." + meta.version
            return [ meta, meta.agp]
    }


    ch_meryldb = ch_samplesheet
    .map {
        meta -> 
            meta = meta[0]
            meta.id = meta.sample + "_" + meta.date + "." + meta.version
            return [ meta, meta.meryldb]
    }

    ch_genomesize = ch_samplesheet
        .map {
        meta -> 
            meta = meta[0]
            meta.id = meta.sample + "_" + meta.date + "." + meta.version
            return [ meta, meta.genomesize]
    }

    //
    // MODULE: Run curation_pipe
    //
    // Create a channel with AGP and assembly files

    agp_assembly_ch = ch_assembly.join(ch_agp)
    .map {
        meta, assembly, agp -> 
        return [meta, assembly, agp]
    }

    RAPID_CURATION (agp_assembly_ch)

    //
    // MODULE: Run mashmap 
    //

    // Combine hap1 and hap2 outputs into a single channel
    ch_haplotypes = RAPID_CURATION.out.hap1.join(RAPID_CURATION.out.hap2)

    // Feed the combined channel into MASHMAP
    MASHMAP(ch_haplotypes)
    ch_versions = ch_versions.mix(MASHMAP.out.versions.first())

    //
    //MODULE: Run update mapping 
    //

    ch_mapping = RAPID_CURATION.out.hap2.join(MASHMAP.out.hap2_hap1_ID)

    UPDATE_MAPPING(ch_mapping)
    ch_versions = ch_versions.mix(MASHMAP.out.versions.first())


    ch_busco = RAPID_CURATION.out.hap1.join(UPDATE_MAPPING.out.hap2_new)
            .map {
                meta, hap1, hap2_new ->
                    return [meta, [ hap1, hap2_new] ]
            }

    BUSCO_BUSCO (
        ch_busco,
        "genome",
        params.buscodb,
        []
    )

    //
    //MODULE: Run Merqury
    //

    ch_assemblies = RAPID_CURATION.out.hap1.join(UPDATE_MAPPING.out.hap2_new) 
                .map {
                meta, hap1, hap2_new ->
                    return [meta, [ hap1, hap2_new] ]
            }

    ch_merqury = ch_meryldb.join(ch_assemblies)

    MERQURY_MERQURY (
        ch_merqury,
        "3.curated"
    )


    //
    // MODULE: run gfastsats
    //

    ch_gfastats_hap1_in = RAPID_CURATION.out.hap1.join(ch_genomesize)
    ch_gfastats_hap2_in = UPDATE_MAPPING.out.hap2_new.join(ch_genomesize)

    GFASTATS_HAP1 (
        ch_gfastats_hap1_in,
        "fasta",
        "",
        "hap1",
        "3.curated",
        [],
        [],
        [],
        []
    )
    ch_versions = ch_versions.mix(GFASTATS_HAP1.out.versions.first())

        GFASTATS_HAP2 (
        ch_gfastats_hap2_in,
        "fasta",
        "",
        "hap2",
        "3.curated",
        [],
        [],
        [],
        []
    )
    ch_versions = ch_versions.mix(GFASTATS_HAP2.out.versions.first())

    //
    // MODULE: Cat hic reads
    //

    CAT_HIC (
        ch_hic
    )

    ///
    ///MODULE: Calculate stats
    //
    

    CALCULATE_STATS (
        RAPID_CURATION.out.hap1,
        UPDATE_MAPPING.out.hap2_new
    )

    
    //
    // MODULE: Run Omnic
    //


    ch_omnic_hap1_in = CAT_HIC.out.cat_files.join(RAPID_CURATION.out.hap1)
        .map {
            meta, reads, assembly ->
                return [ meta, reads, assembly ]
        }
    
    
    ch_omnic_hap2_in = CAT_HIC.out.cat_files.join(UPDATE_MAPPING.out.hap2_new)
        .map {
            meta, reads, assembly ->
                return [ meta, reads, assembly ]
        }

    OMNIC_HAP1 (
        ch_omnic_hap1_in,
        "hap1",
        params.tempdir
    )
    ch_versions = ch_versions.mix(OMNIC_HAP1.out.versions.first())

    OMNIC_HAP2 (
        ch_omnic_hap2_in,
        "hap2",
        params.tempdir
    )
    ch_versions = ch_versions.mix(OMNIC_HAP2.out.versions.first())


    //
    // MODULE: Run Pretext Map
    ///

    PRETEXTMAP_HAP_1 (OMNIC_HAP1.out.omnic_bam,
                        "hap1",
                        "3.curated.")
    
    ch_versions = ch_versions.mix(PRETEXTMAP_HAP_1.out.versions.first())
    
    PRETEXTMAP_HAP_2 (OMNIC_HAP2.out.omnic_bam,
                    "hap2",
                    "3.curated")
    
    ch_versions = ch_versions.mix(PRETEXTMAP_HAP_1.out.versions.first())

    
    //
    // MODULE: Run Pretext snapshot
    //

    PRETEXTSNAPSHOT_HAP1 (PRETEXTMAP_HAP_1.out.pretext_map,
                        "hap1",
                        "3.curated")  
    
    ch_versions = ch_versions.mix(PRETEXTSNAPSHOT_HAP1.out.versions.first())

    PRETEXTSNAPSHOT_HAP2 (PRETEXTMAP_HAP_2.out.pretext_map,
                    "hap2",
                    "3.curated")
    
    ch_versions = ch_versions.mix(PRETEXTSNAPSHOT_HAP2.out.versions.first())

    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'nf_core_pipeline_software_mqc_versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }

    //
    // MODULE: MultiQC
    //
    ch_multiqc_config        = Channel.fromPath(
        "$projectDir/assets/multiqc_config.yml", checkIfExists: true)
    ch_multiqc_custom_config = params.multiqc_config ?
        Channel.fromPath(params.multiqc_config, checkIfExists: true) :
        Channel.empty()
    ch_multiqc_logo          = params.multiqc_logo ?
        Channel.fromPath(params.multiqc_logo, checkIfExists: true) :
        Channel.empty()

    summary_params      = paramsSummaryMap(
        workflow, parameters_schema: "nextflow_schema.json")
    ch_workflow_summary = Channel.value(paramsSummaryMultiqc(summary_params))

    ch_multiqc_custom_methods_description = params.multiqc_methods_description ?
        file(params.multiqc_methods_description, checkIfExists: true) :
        file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
    ch_methods_description                = Channel.value(
        methodsDescriptionText(ch_multiqc_custom_methods_description))

    ch_multiqc_files = ch_multiqc_files.mix(
        ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_methods_description.collectFile(
            name: 'methods_description_mqc.yaml',
            sort: true
        )
    )

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList()
    )

    emit:
    multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
