#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// include modules from nf-core
include { DEMUX											 	 	  } from '../modules/nf_core/cutadapt/demux_main.nf'
include { NANOPLOT as NANOPLOT_PRE_TRIM					 	 	  } from '../modules/nf_core/nanoplot/main.nf'
include { PORECHOP										 	 	  } from '../modules/nf_core/porechop/main.nf'
include { TRIM_UMIS										 	 	  } from '../modules/nf_core/cutadapt/trim_umis_main.nf'
include { TRIM_ARMS										 	 	  } from '../modules/nf_core/cutadapt/trim_arms_main.nf'
include { NANOPLOT as NANOPLOT_POST_TRIM					 	  } from '../modules/nf_core/nanoplot/main.nf'
include { MINIMAP2_ALIGN as MINIMAP2_ALIGN_TO_REF  	 			  } from '../modules/nf_core/minimap2_align/main.nf'
include { SAMTOOLS_IDXSTATS 									  } from '../modules/nf_core/samtools/idxstats/main.nf'
include { BAMTOOLS_SPLIT as SPLIT_BAM_BY_TARGET              	  } from '../modules/nf_core/bamtools_split/main.nf'
// include { EXTRACT_REFERENCE              	 	 			    } from '../modules/nf_core/nanoplot/main.nf'
// include { CALL_INDIVIDUAL_CONSENSUS          	 	  			} from '../subworkflows/call_individual_consensus_nanopore.nf'
// include { REMOVE_TRAILING_FASTA_NS								} from '../modules/local/remove_trailing_fasta_ns/main.nf'
// include { MINIMAP2_ALIGN as MINIMAP2_ALIGN_CONSENSUS		   	    } from '../modules/nf_core/minimap2/align/main.nf'


workflow NANOPORE_WORKFLOW {

  ch_versions = Channel.empty()                                               

  // fastq input files

  Channel.fromFilePairs("${params.fastq_dir}/${params.nanopore_input_pattern}", size: -1, checkIfExists: true, maxDepth: 1)
  .map{ name, inputreads ->
         def matcher = name =~ /^([^.]+)/
         def meta = [:]
         if (matcher.find()) {
             meta.id = matcher.group(0)
         } else {
             meta.id = "UNKNOWN" 
         }
         [ meta, inputreads ]
     }
  .set { ch_inputreads }
  
  // refseq input files

    Channel.fromPath("${params.reference}")
    .collect()
    .map { reference ->
            def meta2 = [:]
            meta2.id = "reference"
            [meta2, reference]
        }
    .set { ch_reference }
    
    // barcode input files

    Channel.fromPath("${params.barcode}")
    .collect()
    .map { barcode ->
            def meta3 = [:]
            meta3.id = "barcode"
            [meta3, barcode]
        }
    .set { ch_barcode }
    
  // demultiplex raw Nanopore reads
  DEMUX ( ch_inputreads, ch_barcode )
  
  demux_reads = DEMUX.out.reads
    .flatMap { meta, reads ->
    reads.collect { read ->
    	def sample_id = read.baseName
        .replaceFirst(/_demux$/, '')
        def new_meta = meta + [id: sample_id]
        tuple(new_meta, read)
        }
    }
  
  // run Nanoplot on demuxed fastq files
  NANOPLOT_PRE_TRIM ( demux_reads )
  
  // trim adapters using porechop
  PORECHOP ( demux_reads )
  
  // trim UMIs using cutadapt
  TRIM_UMIS ( PORECHOP.out.reads )
  
  // trim ARMS using cutadapt
  TRIM_ARMS ( TRIM_UMIS.out.reads )
    
  // run Nanoplot on trimmed fastq files
  NANOPLOT_POST_TRIM ( TRIM_ARMS.out.reads )
  
  // align trimmed reads using minimap2
  MINIMAP2_ALIGN_TO_REF ( TRIM_ARMS.out.reads, ch_reference, "align.to.refseq" )
  
  // determine if there are samples that aligned to nothing
  SAMTOOLS_IDXSTATS ( MINIMAP2_ALIGN_TO_REF.out.bam )
  
  mapped_bams = MINIMAP2_ALIGN_TO_REF.out.bam
    .join(SAMTOOLS_IDXSTATS.out.idxstats)
    .filter { meta, bam, idxstats ->

        def mapped = idxstats.readLines()
            .findAll { !it.startsWith('*') }
            .sum { it.split('\t')[2] as Integer }

        mapped > 0
    }
    .map { meta, bam, idxstats ->
        tuple(meta, bam)
    }
  
  // separate bam file by target being aligned to
  SPLIT_BAM_BY_TARGET ( mapped_bams )
  
  // extract each target reference in alignment
  // EXTRACT_REFERENCE (  )
  
  // call individual consensus sequences for each target
  // CALL_INDIVIDUAL_CONSENSUS (  )
  
  // remove any trailing Ns
  // REMOVE_TRAILING_FASTA_NS (  )
  
  // map reads back to final consensus
  // MINIMAP2_ALIGN_CONSENSUS (  )
    
  // pull alignment statistics using samtools flagstat
  // final multiqc
  // final table with target, reads aligned, genome coverage, and an overall Y/N/suspect result

  }
  
  // specify the entry point for the workflow
workflow {
  NANOPORE_WORKFLOW()
}
