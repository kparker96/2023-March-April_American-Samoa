# *Montipora grisea* Host Genotyping Notebook  
Samples from Fagatele Bay collected in 2023  

## 2025-12-22  

Samples copied from Jason's folder of fastqs copied into my directory on the cluster.  

    [kpark049@turing1 fastqs]$ pwd
    /cm/shared/courses/dbarshis/barshislab/KatieP/taxons/Montipora_grisea/2023-Mgri-NMSAS/fastqs
    [kpark049@turing1 fastqs]$ ls
    23313Brs_2023-ASGWAS-S08deep-Mgri-01_R24069_R1.fastq.gz
    23313Brs_2023-ASGWAS-S08deep-Mgri-01_R24069_R2.fastq.gz
    23313Brs_2023-ASGWAS-S08deep-Mgri-01_R24073_R1.fastq.gz
    23313Brs_2023-ASGWAS-S08deep-Mgri-01_R24073_R2.fastq.gz
    23313Brs_2023-ASGWAS-S08deep-Mgri-01_R24074_R1.fastq.gz
    23313Brs_2023-ASGWAS-S08deep-Mgri-01_R24074_R2.fastq.gz
    23313Brs_2023-ASGWAS-S08deep-Mgri-02_R24069_R1.fastq.gz
    23313Brs_2023-ASGWAS-S08deep-Mgri-02_R24069_R2.fastq.gz
    23313Brs_2023-ASGWAS-S08deep-Mgri-02_R24073_R1.fastq.gz
    23313Brs_2023-ASGWAS-S08deep-Mgri-02_R24073_R2.fastq.gz
    23313Brs_2023-ASGWAS-S08deep-Mgri-02_R24074_R1.fastq.gz
    23313Brs_2023-ASGWAS-S08deep-Mgri-02_R24074_R2.fastq.gz
    23313Brs_2023-ASGWAS-S08deep-Mgri-03_R24069_R1.fastq.gz
    23313Brs_2023-ASGWAS-S08deep-Mgri-03_R24069_R2.fastq.gz
    23313Brs_2023-ASGWAS-S08deep-Mgri-03_R24073_R1.fastq.gz
    23313Brs_2023-ASGWAS-S08deep-Mgri-03_R24073_R2.fastq.gz
    23313Brs_2023-ASGWAS-S08deep-Mgri-03_R24074_R1.fastq.gz
    23313Brs_2023-ASGWAS-S08deep-Mgri-03_R24074_R2.fastq.gz
    23313Brs_2023-ASGWAS-S08deep-Mgri-04_R24069_R1.fastq.gz
    23313Brs_2023-ASGWAS-S08deep-Mgri-04_R24069_R2.fastq.gz
    23313Brs_2023-ASGWAS-S08deep-Mgri-04_R24073_R1.fastq.gz
    23313Brs_2023-ASGWAS-S08deep-Mgri-04_R24073_R2.fastq.gz
    23313Brs_2023-ASGWAS-S08deep-Mgri-04_R24074_R1.fastq.gz
    23313Brs_2023-ASGWAS-S08deep-Mgri-04_R24074_R2.fastq.gz
    23313Brs_2023-ASGWAS-S08deep-Mgri-05_R24069_R1.fastq.gz
    23313Brs_2023-ASGWAS-S08deep-Mgri-05_R24069_R2.fastq.gz
    23313Brs_2023-ASGWAS-S08deep-Mgri-05_R24073_R1.fastq.gz
    23313Brs_2023-ASGWAS-S08deep-Mgri-05_R24073_R2.fastq.gz
    23313Brs_2023-ASGWAS-S08deep-Mgri-05_R24074_R1.fastq.gz
    23313Brs_2023-ASGWAS-S08deep-Mgri-05_R24074_R2.fastq.gz
    23313Brs_2023-ASGWAS-S08deep-Mgri-07_R24069_R1.fastq.gz
    23313Brs_2023-ASGWAS-S08deep-Mgri-07_R24069_R2.fastq.gz
    23313Brs_2023-ASGWAS-S08deep-Mgri-07_R24073_R1.fastq.gz
    23313Brs_2023-ASGWAS-S08deep-Mgri-07_R24073_R2.fastq.gz
    23313Brs_2023-ASGWAS-S08deep-Mgri-07_R24074_R1.fastq.gz
    23313Brs_2023-ASGWAS-S08deep-Mgri-07_R24074_R2.fastq.gz
    23313Brs_2023-ASGWAS-S08midd-Mgri-02_R24069_R1.fastq.gz
    23313Brs_2023-ASGWAS-S08midd-Mgri-02_R24069_R2.fastq.gz
    23313Brs_2023-ASGWAS-S08midd-Mgri-02_R24073_R1.fastq.gz
    23313Brs_2023-ASGWAS-S08midd-Mgri-02_R24073_R2.fastq.gz
    23313Brs_2023-ASGWAS-S08midd-Mgri-02_R24074_R1.fastq.gz
    23313Brs_2023-ASGWAS-S08midd-Mgri-02_R24074_R2.fastq.gz
    23313Brs_2023-ASGWAS-S08midd-Mgri-05_R24069_R1.fastq.gz
    23313Brs_2023-ASGWAS-S08midd-Mgri-05_R24069_R2.fastq.gz
    23313Brs_2023-ASGWAS-S08midd-Mgri-05_R24073_R1.fastq.gz
    23313Brs_2023-ASGWAS-S08midd-Mgri-05_R24073_R2.fastq.gz
    23313Brs_2023-ASGWAS-S08midd-Mgri-05_R24074_R1.fastq.gz
    23313Brs_2023-ASGWAS-S08midd-Mgri-05_R24074_R2.fastq.gz
    23313Brs_2023-ASGWAS-S08shall-Mgri-01_R24069_R1.fastq.gz
    23313Brs_2023-ASGWAS-S08shall-Mgri-01_R24069_R2.fastq.gz
    23313Brs_2023-ASGWAS-S08shall-Mgri-01_R24073_R1.fastq.gz
    23313Brs_2023-ASGWAS-S08shall-Mgri-01_R24073_R2.fastq.gz
    23313Brs_2023-ASGWAS-S08shall-Mgri-01_R24074_R1.fastq.gz
    23313Brs_2023-ASGWAS-S08shall-Mgri-01_R24074_R2.fastq.gz
    23313Brs_2023-ASGWAS-S08shall-Mgri-02_R24069_R1.fastq.gz
    23313Brs_2023-ASGWAS-S08shall-Mgri-02_R24069_R2.fastq.gz
    23313Brs_2023-ASGWAS-S08shall-Mgri-02_R24073_R1.fastq.gz
    23313Brs_2023-ASGWAS-S08shall-Mgri-02_R24073_R2.fastq.gz
    23313Brs_2023-ASGWAS-S08shall-Mgri-02_R24074_R1.fastq.gz
    23313Brs_2023-ASGWAS-S08shall-Mgri-02_R24074_R2.fastq.gz
    23313Brs_2023-ASGWAS-S08shall-Mgri-06_R24069_R1.fastq.gz
    23313Brs_2023-ASGWAS-S08shall-Mgri-06_R24069_R2.fastq.gz
    23313Brs_2023-ASGWAS-S08shall-Mgri-06_R24073_R1.fastq.gz
    23313Brs_2023-ASGWAS-S08shall-Mgri-06_R24073_R2.fastq.gz
    23313Brs_2023-ASGWAS-S08shall-Mgri-06_R24074_R1.fastq.gz
    23313Brs_2023-ASGWAS-S08shall-Mgri-06_R24074_R2.fastq.gz  

**Check MD5SUM**  

	md5sum *.fastq.gz > MD5SUMS_23313Brs.txt
    
## 2025-12-23

**Check MD5SUM**  

    
    [kpark049@coreV3-23-027 fastqs]$ md5sum -c MD5SUMS_23313Brs.txt | tee md5checks.txt


    
