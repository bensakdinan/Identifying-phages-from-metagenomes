#!/bin/bash

# nohup ./iphop.bash > iphop.01.out &

source /path/to/user/miniconda3/etc/profile.d/conda.sh
conda activate iphop_env

cat /mfs/bens/aim2/yaffe_data/day1_srs_ids.txt | parallel -j 10 '
  sample={}

  prophages=/path/to/03_checkv/${sample}/${sample}_filtered_phages.fna
  iphop_database=/path/to/iphop/database
  output_dir=/path/to/output/04_iphop/$sample
  
  iphop predict --fa_file "$prophages" --db_dir "$iphop_database" --out_dir "$output_dir"  && echo 'done' > /path/to/04_iphop/${sample}.iphop.done
'
