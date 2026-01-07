#!/bin/bash -l

#SBATCH --job-name=fastp_array_2025-12-23
#SBATCH --output=%A_%a_%x.out
#SBATCH --error=%A_%a_%x.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=kpark049@odu.edu
#SBATCH --partition=main
#SBATCH --array=1-66
#SBATCH --ntasks=1
#SBATCH --mem=30G
#SBATCH --time=7-00:00:00

## Load modules
module load container_env
module load fastp

## Define some variables
BASEDIR=/cm/shared/courses/dbarshis/barshislab/KatieP/taxons/Montipora_grisea/2023-Mgri-NMSAS/
RAWDATA=$BASEDIR/fastqs #path to raw fq.gz files
OUTDIR=$BASEDIR/fastqs/trimmed_fastq
SAMPLELIST=$BASEDIR/fastqs/sample_data/sample_list.txt # Path to a list of prefixes of the raw fastq files. It can be a subset of the the 1st column of the sample table (without the header line).
SAMPLETABLE=$BASEDIR/fastqs/sample_data/sample_table.txt # Path to a sample table where the 1st column is the prefix of the raw fastq files. The 4th column is the sample ID, the 2nd column is the lane number, and the 3rd column is sequence ID. The combination of these three columns have to be unique. The 6th column should be data type, which is either pe or se.
RAW_R1=_R1.fastq.gz # Suffix to raw fastq files. Use forward reads with paired-end data.
RAW_R2=_R2.fastq.gz # Suffix to raw fastq files. Use reverse reads with paired-end data.

## Keep a record of the Job ID
echo $SLURM_JOB_ID

## Select the SAMPLE from the SAMPLELIST
SAMPLEFILE=`head $SAMPLELIST -n $SLURM_ARRAY_TASK_ID | tail -n 1`

## Keep record of sample file
echo $SAMPLEFILE

## Extract relevant values from a table of sample, sequencing, and lane ID (here in columns 4, 3, 2, respectively) for each sequenced library. This is for the naming of trimmed/processed files
SAMPLE_ID=`grep -P "${SAMPLEFILE}\t" $SAMPLETABLE | cut -f 4`
POP_ID=`grep -P "${SAMPLEFILE}\t" $SAMPLETABLE | cut -f 5`
SEQ_ID=`grep -P "${SAMPLEFILE}\t" $SAMPLETABLE | cut -f 3`
LANE_ID=`grep -P "${SAMPLEFILE}\t" $SAMPLETABLE | cut -f 2`
PREP_ID=`grep -P "${SAMPLEFILE}\t" $SAMPLETABLE | cut -f 13`
SAMPLE_UNIQ_ID=$SAMPLE_ID'_'$SEQ_ID'_'$PREP_ID'_'$LANE_ID  # When a sample has been sequenced in multiple lanes, we need to be able to identify the files from each run uniquely

echo $SAMPLE_UNIQ_ID

## Define the output path and file prefix
SAMPLETRIM=$OUTDIR/$SAMPLE_UNIQ_ID

## Run fastp
crun.fastp fastp -i $RAWDATA/$SAMPLEFILE$RAW_R1 \
    -I $RAWDATA/$SAMPLEFILE$RAW_R2 \
    -o ${SAMPLETRIM}_f_paired_trim.fastq.gz \
    -O ${SAMPLETRIM}_r_paired_trim.fastq.gz \
    --adapter_fasta /archive/barshis/barshislab/jtoy/pver_gwas/pver_gwas_batch3/adapters.fa \
    --cut_tail \
    --trim_poly_g \
    -l 40 \
    -h $BASEDIR/fastqs/fastp_reports/${SAMPLE_UNIQ_ID}_fastp.html \
    -j $BASEDIR/fastqs/fastp_reports/${SAMPLE_UNIQ_ID}_fastp.json \
    --thread 16