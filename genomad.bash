#!/bin/bash

# nohup ./genomad.bash > genomad.01.out &

source /path/to/user/miniconda3/etc/profile.d/conda.sh
conda activate genomad_env

cat /path/to/sample_names.txt | parallel -j 10 '
  sample={}

  metagenome_file=/path/to/01_flye/$sample/${sample}_cleaned.fastq.gz
  output_path=path/to/output/02_genomad/$sample
  genomad_database=/path/to/genomad_db_v

  genomad end-to-end --cleanup --splits 8 "$metagenome_file" "$output_path" "$genomad_database"
'
