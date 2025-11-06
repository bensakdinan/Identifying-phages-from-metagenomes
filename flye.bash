#!/bin/bash

# nohup ./flye.bash > flye.01.out &

source /mfs/bens/miniconda3/etc/profile.d/conda.sh
conda activate flye_env

cat /path/to/sample_names.txt | parallel -j 10 '
  sample={}

  # Directories
  reads_file=/path/to/00_chopper/${sample}_cleaned.fastq.gz
  output_path=/path/to/output/01_flye/$sample

  # Make output directory for each sample (-p if it does not already exist)
  mkdir -p $output_path

  flye --nano-hq $input_file --out-dir $output_path --meta -t 8 && echo 'done' > $output_path/${sample}.flye.done
'
