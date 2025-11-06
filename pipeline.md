# Identifying phages from metagenomes pipeline

## Getting started 
You will need the following software (downloading within conda environments is recommended):
- **Seqkit** for various fasta handling purposes (https://anaconda.org/bioconda/seqkit)
- **Chopper** for trimming and quality controlling (QC) Nanopore reads (https://github.com/wdecoster/chopper) 
- **Flye** for metagenome assembly ([https://anaconda.org/bioconda/flye](https://github.com/mikolmogorov/Flye)
- **GeNomad** for identification of mobile genetic elements, phages, prophages (https://github.com/apcamargo/genomad)
- **CheckV** for assessing viral contig completeness and contiguity (https://bitbucket.org/berkeleylab/checkv/src/master/#markdown-header-running-checkv)
- **iPHoP** for estimating phage-host pairings (https://bitbucket.org/srouxjgi/iphop/src)

`conda activate [environment_name]` is used throughout this pipeline to load software. Additionally, you will need to run run these commands in the background as they can take multiple hours/days. Running these scripts directly in the shell will most likely result in them getting killed as soon as your computer goes to sleep. You can do this using `nohup ./script.bash > script.01.out &`. This will run your script in the background and will direct all standard out to a log file named "script.01.out".

NOTICE: If you are working on a cluster that does not support `conda` (ie. SLURM job submission), your scripts will look a little different. To parallelize jobs, you would likely not be using GNU parallel as I am using here.

## Trimming and cleaning reads 
The first step is to clean our reads with **chopper**. This involves removing sequencing adapters, filtering out low-score and short reads.
`--trim-approach trim-by-quality` trims low quality bases from ends of reads using quality score `cutoff` of 20. You should consult Q-score distribution of your sequencing run to ensure not too much data is lost, but Q20 should be good. 
`--minlength 500` filter out reads less than 500bp
Adapter sequences are likely already removed during basecalling with Dorado, but if not, consult `--headcrop <HEADCROP>`

```bash
#!/bin/bash
conda activate chopper_env

# Iterates through a .txt file of your sample names. Adjust n of parallel jobs accordingly
cat /path/to/sample_names.txt | parallel -j 10 '
  # This variable stores the current sample name
  sample={} 

  # Directories
  reads_file=/path/to/reads/${sample}.fastq.gz
  output_path=/path/to/output/00_chopper

  # && will create an out file if the previous command ran and exited successfully
  chopper --trim-approach trim-by-quality --cutoff 20 --minlength 500 -i $reads_file | gzip > $output_path/${sample}_cleaned.fastq.gz && echo "done" > "${sample}.chopper.done"  
'
```

## Metagenomne assembly
Now that we have cleaned and trimmed fastq.gz reads, we can assemble our metagenome using **Flye**. 
`--meta` flag for metagenome assembly
`--nano-hq` as our input since we previously cleaned reads with minmum Q20
`-t 8` 8 threads, but adjust accordingly

```bash
#!/bin/bash
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
```

## Filter out contigs <1.5kb
Short contigs can skew taxonomic assignments, add noise that obscures abundance estimation, potentially represent lower quality contigs, or have missing genes. We can filter out contigs below 1.5kb as a decent standard of practice.

```bash
#!/bin/bash
conda activate seqkit_env

cat /path/to/sample_names.txt | parallel -j 10 '
  sample={}

  # Directories
  metagenome_file=/path/to/01_flye/$sample/${sample}_cleaned.fastq.gz
  output_path=/path/to/01_flye/$sample # We will store our filtered contigs in the same directory, but under a new name

  seqkit seq -m 1500 $metagenome_file > ${output_path}/${sample}_filtered_1.5kb.fna
'
```

## Identify viral contigs
Using our assembled and 1.5kb filtered metagenome, we can use **geNomad** to identify mobile genetic elements. This includes, plasmids, viruses + phages, and prophages. 
`end-to-end` will run the entire geNomad pipeline
`--splits 8` split resources 
`--cleanup` delete intermediate files

```bash
#!/bin/bash
conda activate genomad_env

cat /path/to/sample_names.txt | parallel -j 10 '
  sample={}

  metagenome_file=/path/to/01_flye/$sample/${sample}_cleaned.fastq.gz
  output_path=path/to/output/02_genomad/$sample
  genomad_database=/path/to/genomad_db_v

  genomad end-to-end --cleanup --splits 8 "$metagenome_file" "$output_path" "$genomad_database" && echo 'done' > $output_path/${sample}.genomad.done
'
```

## Assess quality and completeness of viral contigs
Now that we have identified our viral contigs, we can assess their quality and completeness to filter out ones with low scores. First step though, is to decide what phages we want to work with. If you only want to look at extracellular phages, those will be found in `/path/to/genomad_output/$sample/final.contigs_summary/viruses.fna`. If you also want to look at prophages, those are found in `/path/to/genomad_output/$sample/final.contigs_find_proviruses/$sample/final.contigs_provirus.fna`. If you only want to look at specific taxa of phages, you can filter by taxonomy using this .tsv file `/path/to/genomad_output/$sample/final.contigs_summary/final.contigs_virus_summary.tsv`. 

If you want to combine both extracellular phages and prophages, you can concatenate both .fna files like so: 
```bash
cat /path/to/genomad_output/$sample/final.contigs_summary/viruses.fna /path/to/genomad_output/$sample/final.contigs_find_proviruses/$sample/final.contigs_provirus.fna > /path/to/genomad_output/$sample/all_phages.fna 
```

Now that you have decided which phages you want to work with (I'll be using all phages for the rest of this tutorial), we have to assess the quality and completeness of their genomes. To do so, we will use CheckV.
`end_to_end` to execute the entire checkV pipeline
`-t 16` 16 threads for computational efficiency, adjusted as needed

```bash
#!/bin/bash
conda activate checkv_env

cat /path/to/sample_names.txt | parallel -j 10 '
  sample={}

  input_phages=/path/to/genomad_output/$sample/all_phages.fna
  output_path=/path/to/output/03_checkv/$sample
  export CHECKVDB=/path/to/checkv-db-v1.5   # CheckV requires database directory to be exported

  checkv end_to_end $input_phages $output_path -t 16 && echo 'done' > $output_path/${sample}.checkv.done
'
```

Now we have calculated the quality and completeness of all of our viral contigs. These stats can be found in the output file `quality_summary.tsv`. Here is an example output:
```
contig_id	contig_length	provirus	proviral_length	gene_count	viral_genes	host_genes	checkv_quality	miuvig_quality	completeness	completeness_method	contamination	kmer_freq	warnings
k141_93512|provirus_21938_25795	3858	No	NA	8	0	0	Low-quality	Genome-fragment	6.39	AAI-based (high-confidence)	0.0	1.0	no viral genes detected
k141_97103|provirus_92502_148357	55856	No	NA	68	9	6	Medium-quality	Genome-fragment	70.32	HMM-based (lower-bound)	0.0	1.0	
k141_111526|provirus_760_49311	48552	Yes	7888	46	3	20	Low-quality	Genome-fragment	16.04	HMM-based (lower-bound)	83.75	1.0	
k141_43345|provirus_76_8714	8639	Yes	3516	11	2	4	Low-quality	Genome-fragment	9.61	AAI-based (high-confidence)	59.3	1.0	
k141_64932|provirus_1_13101	13101	No	NA	20	5	0	Low-quality	Genome-fragment	16.25	HMM-based (lower-bound)	0.0	1.0	
```

