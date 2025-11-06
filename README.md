# Identifying-phages-from-metagenomes

**"What about the phages?"** is a question I often see raised by microbiologists during the question period following a seminar. It's easy to neglect the phage fraction in a given biological sample, and it's all too common to forget about these microbial parasites. Phages are uniquely difficult to study due to their lack of a single marker gene. This greatly complicates sequencing since there is no universal PCR target, nor is there an easy genetic identification for phages. The result is that phages are often ignored or forgotten about. 
**I don't want phages to be ignored.**

To overcome this obstacle, metagenomic sequencing is used to capture phage DNA from samples. A metagenome is the collective genetic material of any any all organisms within a given sample (bacteria, viruses, fungi, eukaryotes, etc). Put simply, by sequencing *everything* you *will* capture phage DNA. Metagenomic sequencing generates immense volumes of data which certainly provides immense potential, but this high-throughput output also significantly complicates analysis. I beilieve this to be a major barrier of entry to metagenomics.

Metagenomics can be daunting for microbiologists to start exploring, especially for those with little to no experience in bioinformatics. The immense volume of data in metagenomics can be intimidating and I often hear from fellow microbiologists that they don't exactly know where to begin. However, identifying phages from metagenomes does not need to be complicated. Here I want to provide a basic pipeline for extracting phage genomes from metagenomic read datasets to identifying a phage's host. There are certainly steps that can be taken to further optimize this pipeline and it is not perfect, but I aim here to present a basic foundation.

## Info before we start
- I am working under the assumption that you have basic skills for navigating in command line.
- I am also using Oxford Nanopore long reads in this pipeline. The majority of this pipeline (with the exception for metagenome assembly, where you would need to use a short read assembler such as MEGAHIT) can be applied to short read datasets, but commands would need to be adjusted to handle paired end short reads.
- I am also working under the assumption that your reads have already been trimmed (if using Oxford Nanopore, their basecaller, Dorado, automatically trims adapter sequences)
- This pipeline can also be applied to identify prophage sequences and plasmids. Although some downstream analysis does not apply for plasmids (ie. phage-host prediction)
