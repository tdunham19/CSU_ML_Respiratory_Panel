[![Nextflow](https://img.shields.io/badge/Nextflow-0DC09D?logo=nextflow&logoColor=fff&style=flat-square)](https://www.nextflow.io/)
[![Singularity](https://img.shields.io/badge/Singularity-1d355c.svg?labelColor=9966ff)](https://sylabs.io/docs/)

# Colorado State University Molecular Loop Respiratory Pathogen Panel Pipeline
The CSU_ML_Respiratory_Panel Nextflow pipeline is meant to analyze long read sequences produced by the 'CSU Molecular Loop Nanopore Workflow'.  

[Molecular Loop Workflow](https://molecularloop.com/wp-content/uploads/2026/09/Multiplex-Viral-RNA-Target-Capture-Protocol_ONT_v1.0.pdf)
[Molecular Loop Index Primer Kit for Nanopore Technologies](https://molecularloop.com/wp-content/uploads/2025/05/ML2100-ON_Product-Data-Sheet_v1.pdf)

## Contents
- [Assay Targets](#Assay-Targets)
- [Pipeline Overview](#Pipeline-Overview)
- [Input Files](#Input-Files)
- [Output Files](#Output-Files)
- [Workflow Steps](#Workflow-Steps)
- [Running the Pipeline](#Running-the-Pipeline)
- [Stopping and Resuming](#Stopping-and-Resuming)
- [Dependencies](#Dependencies)

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


## Input Files


## Output Files


## Workflow Steps


## Running the Pipeline


## Stopping and Resuming 
- To stop the run
```
control(^) C
```

- To resume the run add the -resume option
```
nextflow run main.nf --platform --fastq_dir --reference --profile -resume
```


## Dependencies
To run the pipeline the user will need to be working on a computer that has nextflow and singularity installed. It is recommended to install nextflow and singularity in a conda environment. 
- There is no specified version of Nextflow for this pipeline. The pipeline has been tested with Nextflow v24.10.6 [Installation - Nextflow Documentation](https://www.nextflow.io/docs/latest/install.html). 
- The pipeline requires singularity v3.8.6 or newer [Installation - conda-forge/singularity](https://anaconda.org/channels/conda-forge/packages/singularity/overview). 