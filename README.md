# ![tdunham19/CSU_ML_Respiratory_Panel](docs/images/CSU_ML_Nanopore_Pipeline_Subway_no_tsv.png)

[![Nextflow](https://img.shields.io/badge/Nextflow-0DC09D?logo=nextflow&logoColor=fff&style=flat-square)](https://www.nextflow.io/)
[![Singularity](https://img.shields.io/badge/Singularity-1d355c.svg?labelColor=9966ff)](https://sylabs.io/docs/)

# Colorado State University Molecular Loop Respiratory Pathogen Panel Pipeline
The CSU_ML_Respiratory_Panel Nextflow pipeline is meant to analyze long read sequences produced by the 'CSU Molecular Loop Nanopore Workflow'. 
This workflow screens for 12 different respiratory pathogens covering 20 different gene targets. 

## Contents
- [CSU Molecular Loop Nanopore Workflow](#CSU-Molecular-Loop-Nanopore-Workflow)
- [Assay Targets](#Assay-Targets)
- [Pipeline Overview](#Pipeline-Overview)
- [Input Files](#Input-Files)
- [Output Files](#Output-Files)
- [Workflow Steps](#Workflow-Steps)
- [Running the Pipeline](#Running-the-Pipeline)
- [Stopping and Resuming](#Stopping-and-Resuming)
- [Software Versions](#Software-Versions)
- [Dependencies](#Dependencies)

## CSU Molecular Loop Nanopore Workflow

- [Molecular Loop Protocol](https://molecularloop.com/wp-content/uploads/2026/09/Multiplex-Viral-RNA-Target-Capture-Protocol_ONT_v1.0.pdf)
- [Molecular Loop Index Primer Kit for Nanopore Technologies](https://molecularloop.com/wp-content/uploads/2025/05/ML2100-ON_Product-Data-Sheet_v1.pdf)
- [Nanopore Sequencing Protocol](https://nanoporetech.com/document/genomic-dna-by-ligation-sqk-lsk114)


## Assay Targets 
### CSU Custom Respiratory Pathogen Panel

1. Mycobacterium tuberculosis variant bovis 
	- Chromosome RvD1Rv2031c
	- Insertion Element IS6110 DNA
2. Cervid alphaherpesvirus 4
3. Influenza D virus
	- Segment 5 NP Gene
	- Segment 4 HE gene
4. Mycoplasma bovis
5. Mule deer alphaherpesvirus
6. Deerpox virus W-848-83
	- DNA polymerase CDS
	- Variola virus B22R-like protein CDS
7. Deer Mastadenovirus B
8. Odocoileus adenovirus 1
9. Type 2 ruminant rhadinovirus of mule deer
10. While-tailed deer coronavirus US/OH-WD470/1994
	- Spike protein CDS
	- ORF1a polyprotein CDS
11. BVDV2 (bovine viral diarrhea virus)
12. New Kent County Virus


## Pipeline Overview
The CSU_ML_Respiratory_Panel is a nextflow pipeline that will perform demultiplexing, trimming, alignment, and consensus generation of Nanopore sequence data generated using the [CSU Molecular Loop Nanopore Workflow](#CSU-Molecular-Loop-Nanopore-Workflow). 
- Demultiplexing is necessary in this workflow as there is no way to demultiplex the custom ML2100 indexes during Nanopore sequencing.
- Preprocessing via trimming of the Nanopore adapters (porechop), molecular loop UMIs (cutadapt), and molecular loop arms (cuadapt) is also necessary. Final trimmed reads are provided for any further analysis.
- Alignment is performed against 20 different gene targets (See [Assay Targets](#Assay-Targets)) and consensus sequences are generated from each individual target alignments. 
	- The pipeline generates consensus sequences using the following thresholds: minimum quality score of 5, depth of 2, and frequency of 0.25. Users can modify these settings in the nextflow.config file.


## Input Files
Nanopore long reads generated using the [CSU Molecular Loop Nanopore Workflow](#CSU-Molecular-Loop-Nanopore-Workflow)

IMPORTANT
- One input *.fastq.gz should be used at a time unless unique ML2100 indexes are used across runs. Demultiplexing cannot identify re-used barcodes across runs.
- Input files must be contained in a directory where it is the ONLY *.fastq.gz (it is recommended to create a new directory for the input raw reads).


## Output Files
- aligned_to_ref
	- *.bam containing reads aligned to each gene target (refseq)
- consensus_sequences
	- *.fa containing consensus sequence generated for each gene target
- final_trimmed_reads
	- *.fastq.gz containing preprocessed reads (demultiplexed & trimmed adapters, UMIs, and arms)
- individual_references
	- *.fa containing individual reference sequences used for each gene target
- quality_control
	- *.html containing NanoPlot reports (pre and post trimming)
- final_summary.tsv
# ![tdunham19/CSU_ML_Respiratory_Panel](docs/images/CSU_ML_Nanopore_Pipelipeline_TSV_Output.png)


## Workflow Steps
1. Demultiplex reads into individual barcode files: cutadapt
2. Quality assessment of demultiplexed input reads: NanoPlot
3. Trimming of Nanopore adapters: porechop
4. Trimming of Molecular Loop UMIs and arms: cutadapt
5. Quality assessment of trimmed reads: NanoPlot
6. Alignment against all gene targets (n=20): Minimap2
7. Filter out empty alignments & separate into one alignment per barcode and target: samtools
8. Call consensus sequences for each individual target: ViralConsensus
9. Calculate genome coverage and collate results table: samtools


## Running the Pipeline
1. Clone the pipeline from GitHub
```
git clone https://github.com/tdunham19/CSU_ML_Respiratory_Panel.git
```

2. Run the pipeline: The user MUST specify which reference and barcode files to use and where the input fastq files are located. The user has the option to specify the output directory.
```
nextflow run main.nf --fastq_dir --barcode --reference --outdir
```


## Stopping and Resuming 
- To stop the run
```
control(^) C
```

- To resume the run add the -resume option
```
nextflow run main.nf --fastq_dir --barcode --reference -resume
```

## Software Versions
| Software  | Version |
| ------------- | ------------- |
| NanoPlot  | 1.48.0  |
| Porechop  | 0.2.4  |
| Cutadapt  | 5.2  |
| Minimap2  | 2.30-r1287  |
| Samtools  | 1.25  |
| Bamtools  |2.5.2  |
| ViralConsensus  | 0.0.6  |


## Dependencies
To run the pipeline the user will need to be working on a computer that has nextflow and singularity installed. It is recommended to install nextflow and singularity in a conda environment. 
- There is no specified version of Nextflow for this pipeline. The pipeline has been tested with Nextflow v24.10.6 [Installation - Nextflow Documentation](https://www.nextflow.io/docs/latest/install.html). 
- The pipeline requires singularity v3.8.6 or newer [Installation - conda-forge/singularity](https://anaconda.org/channels/conda-forge/packages/singularity/overview). 
