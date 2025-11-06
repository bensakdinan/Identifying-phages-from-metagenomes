## Getting started 
You will need the following software (downloading within conda environments is recommended):
- **Seqkit** for various fasta handling purposes (https://anaconda.org/bioconda/seqkit)
- **NanoFilt** for trimming and quality controlling (QC) Nanopore reads ([https://anaconda.org/bioconda/nanofilt](https://github.com/wdecoster/nanofilt))
- **Flye** for metagenome assembly ([https://anaconda.org/bioconda/flye](https://github.com/mikolmogorov/Flye)
- **GeNomad** for identification of mobile genetic elements, phages, prophages (https://github.com/apcamargo/genomad)
- **CheckV** for assessing viral contig completeness and contiguity (https://bitbucket.org/berkeleylab/checkv/src/master/#markdown-header-running-checkv) 

## Trimming and cleaning reads 
The first step is to clean our reads. This involves removing sequencing adapters, 
