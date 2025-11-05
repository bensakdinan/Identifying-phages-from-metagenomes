#!/bin/bash

# nohup ./flye.bash > flye_log_01.out &

source /mfs/bens/miniconda3/etc/profile.d/conda.sh
conda activate flye_env

parallel -j 4 '
  
  # Directories
  reads_dir=/mfs/bens/phages_training/00_reads/demux
  input_file="$reads_dir/11e7ac89-cfd7-4de6-917f-7fbb1b27566c_OttawaPL_barcode0{}.fastq.gz"
  output_path=/mfs/bens/phages_training/01_assembly

  # Make output directory (-p if it does not already exist)
  mkdir -p $output_path/{}

  # Run flye command with --meta flag for metagenome assembly
  # && will create an out file if flye ran and exited successfully
  flye --nano-raw $input_file --out-dir $output_path --meta -t 8 && echo 'done' > $output_path/{}_flye.done
  
' ::: $(seq -w 1 96) # Array of numbers between 01-96, corresponding to our 96 samples
