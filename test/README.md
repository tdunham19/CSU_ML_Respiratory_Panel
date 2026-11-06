## Test datasets

This directory contains a small test dataset created from a control run containing BVDV2 and HVC-1 controls. 

These datasets include:

| Barcode | Expected Agent |
| ------- | -------- |
| barcode1 | BVDV2 |
| barcode9 | BVDV2 |
| barcode2 | Mule Deer Herpes (HVC-1) |
| barcode33 | Mule Deer Herpes (HVC-1) |
| barcode89 | Mule Deer Herpes (HVC-1) |

These datasets were created using seqtk and subseting for 8000 reads. 

These datasets are used as input when using the test profile:

```
nextflow run main.nf -profile test -resume 
```

This should take ~1 minute to run to completion.

Expected output from test dataset:
| Sample | Target | RefSeq_Length | Consensus_Length | Reads_Aligned | Genome_Coverage | Conclusion |
| ------- | -------- | ------- | -------- | ------- | -------- | ------- |
| ML2100ON_barcode1_demux.fastq | PV541660_BVDV2_OV853 | 12273 | 11330 | 102 | 94.16 | Yes |
| ML2100ON_barcode9_demux.fastq | PV541660_BVDV2_OV853 | 12273 | 11655 | 278 | 264.00 | Yes |
| ML2100ON_barcode2_demux.fastq | KY748207_Mule_deer_alphaherpesvirus_B_gene | 2820 | 906 | 6 | 1.93 | Suspect |
| ML2100ON_barcode33_demux.fastq | KY748207_Mule_deer_alphaherpesvirus_B_gene | 2820 | 2186 | 16 | 12.40 | Suspect |
| ML2100ON_barcode89_demux.fastq | KY748207_Mule_deer_alphaherpesvirus_B_gene | 2820 | 799 | 4 | 1.13 | Suspect |
| ML2100ON_barcode89_demux.fastq | PV541660_BVDV2_OV853 | 12273 | 702 | 2 | 0.11 | Suspect |

