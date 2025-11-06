#!/bin/bash

# nohup ./filter_phages.bash > filter_phages.01.out &

source /path/to/user/miniconda3/etc/profile.d/conda.sh
conda activate seqkit_env

for input_file in /path/to/03_checkv/*/quality_summary.tsv; do
    # Gets sample name from the directory name
    sample=$(basename "$(dirname "$input_file")")

    # This is the concatenated fasta of all our phages 
    phage_fasta=/path/to/genomad_output/${sample}/all_phages.fna
    filtered_phage_names=/path/to/03_checkv/${sample}/${sample}_phages_filtered.txt
    filtered_phages=/path/to/03_checkv/${sample}/${sample}_filtered_phages.fna

    # First check that the input quality_summary.tsv file exists
    if [[ -f "$input_file" ]]; then
        echo "Filtering out phages for: $sample"

        # Filter out contigs that have Not-determined or Low-quality checkv-quality
        awk -F '\t' 'NR>1 && $8!="Not-determined" && $8!="Low-quality" {print $1}' \
            "$input_file" > "$filtered_phage_names"

        # Now filter all_phages.fna using the list of passed phage contigs
        seqkit grep -f "$filtered_phage_names" "$phage_fasta" > "$filtered_phages"
    else
        echo "quality_summary.tsv not found for sample $sample"
    fi
done
