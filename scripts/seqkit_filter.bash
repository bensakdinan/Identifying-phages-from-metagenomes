#!/bin/bash

# nohup ./seqkit_filter.bash > seqkit_filter.01.out &

source /path/to/user/miniconda3/etc/profile.d/conda.sh
conda activate seqkit_env

cat /path/to/sample_names.txt | parallel -j 10 '
  sample={}

  # Directories
  metagenome_file=/path/to/01_flye/$sample/${sample}_cleaned.fastq.gz
  output_path=/path/to/01_flye/$sample # We will store our filtered contigs in the same directory, but under a new name

  seqkit seq -m 1500 $metagenome_file > ${output_path}/${sample}_filtered_1.5kb.fna
'
