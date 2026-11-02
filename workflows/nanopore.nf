#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// include modules from nf-core
include { DEMUX											 	 	  } from '../modules/nf_core/cutadapt/demux_main.nf'
// include { NANOPLOT as NANOPLOT_PRE_TRIM					 	 	  } from '../modules/nf_core/nanoplot/main.nf'
include { PORECHOP										 	 	  } from '../modules/nf_core/porechop/main.nf'
// include { TRIM_UMIS										 	 	  } from '../modules/nf_core/cutadapt/main.nf'
// include { TRIM_ARMS										 	 	  } from '../modules/nf_core/cutadapt/main.nf'
// include { NANOPLOT as NANOPLOT_POST_TRIM					 	  } from '../modules/nf_core/nanoplot/main.nf'
// include { MINIMAP2_ALIGN as MINIMAP2_ALIGN_TO_REF  	 				     		  } from '../modules/nf_core/minimap2/align/main.nf'
// include { CALL_INDIVIDUAL_CONSENSUS_NANOPORE              	 	  } from '../subworkflows/call_individual_consensus_nanopore.nf'
// include { RENAME_ONE_ALN									 	  } from '../modules/local/rename_one_aln/main.nf'
// include { RENAME_ONE_FASTA		 	  							  } from '../modules/local/rename_one_fasta/main.nf'
// include { CONCATENATE_FILES       	 							  } from '../modules/stenglein_lab/concatenate_files/main.nf'
// include { REMOVE_TRAILING_FASTA_NS								  } from '../modules/local/remove_trailing_fasta_ns/main.nf'
// include { MINIMAP2_ALIGN as MINIMAP2_ALIGN_CONSENSUS		   	  } from '../modules/nf_core/minimap2/align/main.nf'


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
  // NANOPLOT_PRE_TRIM ( DEMUX.out.reads )
  
  // trim adapters using porechop
  PORECHOP ( demux_reads )
  
  // trim UMIs using cutadapt
  // TRIM_UMIS ( PORECHOP.out.reads )
  
  // trim ARMS using cutadapt
  // TRIM_ARMS ( TRIM_UMIS.out.reads )
    
  // run Nanoplot on trimmed fastq files
  // NANOPLOT_POST_TRIM ( TRIM_ARMS.out.reads )
  
  // align trimmed reads using minimap2
  // MINIMAP2_ALIGN_TO_REF ( TRIM_ARMS.out.reads, ch_reference, "_refseq" )

  }
  
  // specify the entry point for the workflow
workflow {
  NANOPORE_WORKFLOW()
}
