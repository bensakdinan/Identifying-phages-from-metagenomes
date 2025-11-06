# Identifying phages from metagenomes pipeline

## Getting started 
You will need the following software (downloading within conda environments is recommended):
- **Seqkit** for various fasta handling purposes (https://anaconda.org/bioconda/seqkit)
- **Chopper** for trimming and quality controlling (QC) Nanopore reads (https://github.com/wdecoster/chopper) 
- **Flye** for metagenome assembly ([https://anaconda.org/bioconda/flye](https://github.com/mikolmogorov/Flye)
- **GeNomad** for identification of mobile genetic elements, phages, prophages (https://github.com/apcamargo/genomad)
- **CheckV** for assessing viral contig completeness and contiguity (https://bitbucket.org/berkeleylab/checkv/src/master/#markdown-header-running-checkv)
- **iPHoP** for estimating phage-host pairings (https://bitbucket.org/srouxjgi/iphop/src) 

## Trimming and cleaning reads 
The first step is to clean our reads. This involves removing sequencing adapters, filtering out low-score and short reads.
`--trim-approach trim-by-quality` trims low quality bases from ends of reads using quality score `cutoff` of 20. You should consult Q-score distribution of your sequencing run to ensure not too much data is lost, but Q20 should be good. 
`--minlength 500` filter out reads less than 500bp
Adapter sequences are likely already removed during basecalling with Dorado, but if not, consult `--headcrop <HEADCROP>`

```bash
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
Now that we have cleaned and trimmed fastq.gz reads, we can assemble our metagenome using Flye. 
`--meta` flag for metagenome assembly
`--nano-hq` as our input since we previously cleaned reads with minmum Q20
`t 8` 8 threads, but adjust accordingly

```bash
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

## 

