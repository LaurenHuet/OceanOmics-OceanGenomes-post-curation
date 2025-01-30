<h1>
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/images/nf-core-postcuration_logo_dark.png">
    <img alt="nf-core/postcuration" src="docs/images/nf-core-postcuration_logo_light.png">
  </picture>
</h1>

[![GitHub Actions CI Status](https://github.com/nf-core/postcuration/actions/workflows/ci.yml/badge.svg)](https://github.com/nf-core/postcuration/actions/workflows/ci.yml)
[![GitHub Actions Linting Status](https://github.com/nf-core/postcuration/actions/workflows/linting.yml/badge.svg)](https://github.com/nf-core/postcuration/actions/workflows/linting.yml)[![AWS CI](https://img.shields.io/badge/CI%20tests-full%20size-FF9900?labelColor=000000&logo=Amazon%20AWS)](https://nf-co.re/postcuration/results)[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.XXXXXXX-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.XXXXXXX)
[![nf-test](https://img.shields.io/badge/unit_tests-nf--test-337ab7.svg)](https://www.nf-test.com)

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A523.04.0-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![Launch on Seqera Platform](https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Seqera%20Platform-%234256e7)](https://cloud.seqera.io/launch?pipeline=https://github.com/nf-core/postcuration)

[![Get help on Slack](http://img.shields.io/badge/slack-nf--core%20%23postcuration-4A154B?labelColor=000000&logo=slack)](https://nfcore.slack.com/channels/postcuration)[![Follow on Twitter](http://img.shields.io/badge/twitter-%40nf__core-1DA1F2?labelColor=000000&logo=twitter)](https://twitter.com/nf_core)[![Follow on Mastodon](https://img.shields.io/badge/mastodon-nf__core-6364ff?labelColor=FFFFFF&logo=mastodon)](https://mstdn.science/@nf_core)[![Watch on YouTube](http://img.shields.io/badge/youtube-nf--core-FF0000?labelColor=000000&logo=youtube)](https://www.youtube.com/c/nf-core)

## Introduction

**nf-core/postcuration** is a bioinformatics pipeline designed to generate curated hap1/hap2 assemblies and QC, following manual genome curation in PretextView. This pipeline requires an AGP file generated from PretextView, the assembly you wish to make changes to and raw hic data. 



<!-- TODO nf-core: Include a figure that guides the user through the major workflow steps. Many nf-core
     workflows use the "tube map" design for that. See https://nf-co.re/docs/contributing/design_guidelines#examples for examples.   -->
<!-- TODO nf-core: Fill in short bullet-pointed list of the default steps in the pipeline -->

1. Rapid Curation ([`RapidCuration`](Nadolina Brajuka Vertebrate Genome Laboratory))
2. Mashmap ([`MashMap`](https://github.com/marbl/MashMap))
3. Update Mapping ([`Update Mapping`](Tom Mathers Darwin Tree of Life))
4. Busco ([`BUSCO`](https://busco.ezlab.org/))
5. Merqury ([`Merqury`](https://github.com/marbl/merqury))
6. Gfastats([`Gfastats`](https://github.com/vgl-hub/gfastats))
7. Align reads to curated assembly (['Omnic'](https://omni-c.readthedocs.io/en/latest/))
8. Generate Pretext Maps ([`PretextMap`](https://github.com/sanger-tol/PretextMap))
9. Generate Pretext Snapshots([`Pretext Snapshot`](https://github.com/sanger-tol/PretextSnapshot))
10. ([`MultiQC`](http://multiqc.info/))


## Usage

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline) with `-profile test` before running the workflow on actual data.


First, prepare a samplesheet with your input data that looks as follows:

`samplesheet.csv`:

```csv
sample,hic_dir,assembly,meryldb,agp,version,date,genomesize
OG47,/path/to/hic/reads/,/path/to/assembly/,/path/to/meryl/database/OG47.meryl,/path/to/agp/file,hic1,v231115,637904034
```

Each row represents sample. All fields are mandatory, the hic_dir, assembly, merlydb and agp columns must point to a directory that contains the corrosponding file(s). 

-->

Now, you can run the pipeline using:


```bash
nextflow run main.nf \
  --profile singularity \
  --input assets/samplesheet.csv \
  --buscodb /path/to/busco_db/ \
  --binddir /scratch \
  --outdir  \
  -c pawsey_profile.config \
  -resume \
  --tempdir $MYSCRATCH

```

Note, there is a nextflow_run.sh script in the repo that loads the nextflow module for running on pawsey. Fill out the feilds in this script to run the pipeline


> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_;
> see [docs](https://nf-co.re/usage/configuration#custom-configuration-files).

For more details and further functionality, please refer to the [usage documentation](https://nf-co.re/postcuration/usage) and the [parameter documentation](https://nf-co.re/postcuration/parameters).

## Pipeline output

To see the results of an example test run with a full size dataset refer to the [results](https://nf-co.re/postcuration/results) tab on the nf-core website pipeline page.
For more details about the output files and reports, please refer to the
[output documentation](https://nf-co.re/postcuration/output).

## Credits

nf-core/postcuration was originally written by Lauren Huet.

We thank the following people for their extensive assistance in the development of this pipeline:

This workflow makes use of scripts written by Tom Mathers from the Darwin Tree of Life program (hap2_hap1_ID_mapping.sh and update_mapping.rb), and the Rapid Curation pipeline written by Nadolina Brajuka from the Vertebrate Genome Laboratory.

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

For further information or help, don't hesitate to get in touch on the [Slack `#postcuration` channel](https://nfcore.slack.com/channels/postcuration) (you can join with [this invite](https://nf-co.re/join/slack)).

## Citations


An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

You can cite the `nf-core` publication as follows:

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
