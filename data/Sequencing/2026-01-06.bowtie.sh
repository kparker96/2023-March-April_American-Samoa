#!/bin/bash -l

#SBATCH --job-name=hologenome_mapping_2026-01-06
#SBATCH --output=%A_%a_%x.out
#SBATCH --error=%A_%a_%x.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=kpark049@odu.edu
#SBATCH --partition=main
#SBATCH --array=1-33      # One array task per sample
#SBATCH --ntasks=1
#SBATCH --mem=30G
#SBATCH --time=7-00:00:00

## Load modules
module load container_env
module load bowtie2

## Define directories and files
BASEDIR=/cm/shared/courses/dbarshis/barshislab/KatieP/taxons/Montipora_grisea/2023-Mgri-NMSAS
FASTQDIR=$BASEDIR/fastqs/trimmed_fastqs           # path to trimmed fastq.gz files
OUTDIR=$BASEDIR/bam                                # output directory for BAM files
SAMPLELIST=$BASEDIR/fastqs/sample_data/sample_list.txt    # list of sample prefixes

## Keep a record of the SLURM job
echo "SLURM_JOB_ID: $SLURM_JOB_ID"

## Select the sample for this array task
SAMPLEFILE=$(head -n $SLURM_ARRAY_TASK_ID $SAMPLELIST | tail -n 1)
echo "Processing sample: $SAMPLEFILE"

## Define output BAM prefix
SAMPLEOUT=$OUTDIR/$SAMPLEFILE

## Run Bowtie2 mapping (paired-end)
crun.bowtie2 bowtie2 -q --phred33 --very-sensitive -p 16 \
    -I 0 -X 1500 --fr \
    -x /cm/shared/courses/dbarshis/barshislab/KatieP/taxons/Montipora_grisea/2023-Mgri-NMSAS/mgris_genome/full_genome_scaffolds_Mgri_0.1.fasta \
    -1 $FASTQDIR/${SAMPLEFILE}_R1_trimmed.fastq.gz \
    -2 $FASTQDIR/${SAMPLEFILE}_R2_trimmed.fastq.gz \
    -S $SAMPLEOUT.sam

# Unload Bowtie2, load GATK
module unload bowtie2
module load gatk

GATK='crun.gatk gatk'

# Sort by queryname
$GATK --java-options "-Xmx30G" SortSam \
  --INPUT $SAMPLEOUT.sam \
  --OUTPUT $SAMPLEOUT.qsorted.bam \
  --SORT_ORDER queryname

# Remove SAM to save space
rm $SAMPLEOUT.sam

# Mark duplicates and remove them
$GATK --java-options "-Xmx30G" MarkDuplicates \
  -I $SAMPLEOUT.qsorted.bam \
  -O $SAMPLEOUT.qsorted_dedup.bam \
  --REMOVE_DUPLICATES true \
  --METRICS_FILE $SAMPLEOUT.dupmetrics.txt

# Sort by coordinate for downstream analysis
$GATK --java-options "-Xmx30G" SortSam \
  --INPUT $SAMPLEOUT.qsorted_dedup.bam \
  --OUTPUT $SAMPLEOUT.qsorted_dedup_coordsorted.bam \
  --SORT_ORDER coordinate

# Cleanup intermediate files
rm $SAMPLEOUT.qsorted.bam $SAMPLEOUT.qsorted_dedup.bam

# Optional: validate final BAM
$GATK --java-options "-Xmx30G" ValidateSamFile \
  -I $SAMPLEOUT.qsorted_dedup_coordsorted.bam \
  -O $SAMPLEOUT.val.txt \
  -M VERBOSE

echo "Finished processing $SAMPLEFILE"
