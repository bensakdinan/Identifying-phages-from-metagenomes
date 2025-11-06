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
  output_path=/path/to/01_flye/$sample/ # We will store our filtered contigs in the same directory, but under a new name

  seqkit seq -m 1500 $metagenome_file > ${output_path}/${sample}_filtered_1.5kb.fna
'
```

## Identify viral contigs
Using our assembled and 1.5kb filtered metagenome, we can use **geNomad** to identify mobile genetic elements. This includes, plasmids, viruses + phages, and prophages. 

```bash
#!/bin/bash
```

## Assess quality and completeness of viral contigs
Now that we have identified our viral contigs, we can assess their quality and completeness to filter out ones with low scores. 
