<!--
title: "Running analysis with UKB WES 470k"
description: "This is an introduction to how to run per-variant and per-gene association tests using WES 470K data on UKBB RAP."
-->

## Introduction

This document provides a practical guide on running per-variant (ExWAS) and per-gene (gene-collapsing) association tests using UKB WES 470K data on the UKBB RAP for IC internal users.

**Prerequisites:** Users should be familiar with using the UKB RAP via the command line interface (CLI).

- [Tutorials for working on UKB RAP via CLI](https://dnanexus.gitbook.io/uk-biobank-rap/working-on-the-research-analysis-platform/running-analysis)
- [Tutorial for installing dxtoolkit (required for accessing CLI)](https://documentation.dnanexus.com/downloads)

## Method overview

Three customised tools on RAP are available for IC internal users with access to `project-GyZxPF8JQkyq9JVxZjQ2FvqK` to run variant-level or gene-level association tests using WES 470K data.

For association tests, we use [regenie](https://rgcgithub.github.io/regenie/).

This guide provides step-by-step instructions for different analysis scenarios using three customised tools on RAP. 
To view detailed documentation for each tool, run the following commands in your command-line interface:

```bash
dx run app-ic-epid-regenie-step1 --help                         # The app for running regenie step 1
dx run app-ic-epid-regenie-step2_per-gene-test --help           # The app for running regenie step 2, gene level association test 
dx run app-ic-epid-regenie-step2_per-variant-test --help        # The app for running regenie step 2, variant level association test 
```

**Required input:** Users must prepare a tab-delimited phenotype file as the minimum input to run the three tools above. 
Saving the phenotype file as uncompressed .txt or .tsv is recommended, as regenie may encounter parsing issues with compressed .gz format.

- If multiple phenotypes are included, the phenotype file must contain either all binary traits or all quantitative traits, as regenie cannot process mixed phenotype types in a single run.
- Please be cautious about the potential limitations in running multiple phenotypes as one job in regenie: [missing pattern](https://rgcgithub.github.io/regenie/recommendations/). 
- While the three tools can theoretically handle multiple phenotypes, current resource configurations have only been tested with up to 3 phenotypes. Including more may lead to resource allocation issues.

Below is an example of the expected phenotype file format. The first two columns are FID and IID. The third column is the first phenotype, and the fourth and fifth columns are additional phenotypes if multiple phenotypes are included.

```
FID    IID    PHENO1    PHENO2    PHENO3
123    123      1         0         0
456    456      1         1         1
789    789      0         0         0
```

Regenie's first step builds a whole-genome regression model that is computationally intensive. For initial exploratory analyses, this step can be skipped. However, for final results, predictions from step 1 should be included to adjust for population stratification and cryptic relatedness in the association tests.

For details about other optional input files and their required formats, please run:  
`dx run app-name --help`

The following sub-sections provide example codes of how to run the apps for different analysis scenarios:

1. Quickly screen for gene-phenotype associations for a short list of genes: [**quick gene screening**](#quick-gene-screening)
2. Run genome-wide gene-phenotype association test without step 1 for quick results: [**quick genome-wide gene-based test**](#quick-genome-wide-gene-based-test)
3. Run a genome-wide gene-based test with step 1 predictions for final results: [**genome-wide gene-based association test with step1 output**](#genome-wide-gene-based-association-test-with-step1-output)  
4. Run a genome-wide variant association test (ExWAS) with step 1 predictions for final results: [**genome-wide variant-level association test with step1 output**](#genome-wide-variant-level-association-test-with-step1-output)

For further details about runtime and cost, data processing, gene-based test methods, and results interpretations, please refer to [**FAQ**](FAQ.md)


**IMPORTANT:** Please do not run analysis in project `project-GyZxPF8JQkyq9JVxZjQ2FvqK`, this is the project directory where the pipeline input and intermediate files are stored.

For any files stored in this project that you want to use for your own analysis (e.g. if you want to use the QCed genotype array files for GWAS), please set up your own project, then in your script, you can access the files in this project by refering to it by either file ID: 
`project-GyZxPF8JQkyq9JVxZjQ2FvqK:file-XXXXXXXXXX`, or by defining the full path: `project-GyZxPF8JQkyq9JVxZjQ2FvqK:/FULL_PATH/FILE_NAME`.

Please do **not** attempt to `mv` or `cp` any of the files from this project.


---

#### quick gene screening

The following example shows the **minimum** input parameters to be defined by the user to run gene-based test without regenie step 1 input.

To check details about the compulsory or optional flags, and user input file formats, please run ```dx run app-name --help ```, or refer to [**FAQ**](FAQ.md)

Example code:

```bash
dx cd project-zzzzzz                               # navigate to your project directory 

dx run app-regenie-step2_per-variant-test \    
    --priority low \                               # Define priority of the job; recommend to start with low, then if multiple failures >5, switch to high                                     
    --destination project-zzzzzz:/OUTPUT_PATH/ \   # Define the destination folder for the output files; if not defined, the output will be saved in the current working directory
    --name JOBNAME \                               # Name of the job for monitoring and tracking 
    -y --brief \                                   # Run the job in the background rather than interactively in the terminal 
    -ipheno_file=project-zzzzzz:file-zzzzzz  \     # Compulsory user defined input: input phenotype file with either full file path, or file ID    
    -ipheno_binary=true \                          # Compulsory user defined input: whether the phenotype(s) is binary or quantitative
    -ipheno_colnames=PHENO \                       # Compulsory user defined input: define the column names in the phenotype file. If multiple phenotypes are provided, use comma-separated format, e.g. PHENO1,PHENO2,PHENO3
    -ioutput_file_prefix=OUTPUT_FILE_PREFIX \      # Compulsory user defined input: define the output file prefix, this will be appended in front of the phenotype name followed by the default file extension of the regenie output files, e.g. ${OUTPUT_FILE_PREFIX}.pheno1.regenie  
    -istep1_pred_included=false \                  # Compulsory user defined input: specify whether the step1 predictions are included. 
    -igene_list=GENE1,GENE2,GENE3                  # Optional user defined input: Specify the gene(s) to be included in the gene-based test in a comma-separated format. 
```

**Notes:** To define the list of gene(s), either gene names (e.g. `-igene_list=BRCA1,BRCA2`) or gene Ensembl IDs (e.g. `-igene_list=ENSG00000012048,ENSG00000139618`) can be used.

---

#### quick genome-wide gene-based test

The following example shows the **minimum** input parameters to be defined by the user to run gene-based test without regenie step 1 input.

To check details about the compulsory or optional flags, and user input file formats, please run ```dx run app-name --help ```, or refer to [**FAQ**](FAQ.md)

Example code:

```bash
dx cd project-zzzzzz                               # navigate to your project directory 

dx run app-regenie-step2_per-gene-test \    
    --priority low \                               # Define priority of the job; recommend to start with low, then if multiple failures >5, switch to high                                     
    --destination project-zzzzzz:/OUTPUT_PATH/ \   # Define the destination folder for the output files; if not defined, the output will be saved in the current working directory
    --name JOBNAME \                               # Name of the job for monitoring and tracking 
    -y --brief \                                   # Run the job in the background rather than interactively in the terminal 
    -ipheno_file=project-zzzzzz:file-zzzzzz \      # Compulsory user defined input: input phenotype file with either full file path, or file ID    
    -ipheno_binary=true \                          # Compulsory user defined input: whether the phenotype(s) is binary or quantitative
    -ipheno_colnames=PHENO \                       # Compulsory user defined input: define the column names in the phenotype file. If multiple phenotypes are provided, use comma-separated format, e.g. PHENO1,PHENO2,PHENO3
    -ioutput_file_prefix=OUTPUT_FILE_PREFIX \      # Compulsory user defined input: define the output file prefix, this will be appended in front of the phenotype name followed by the default file extension of the regenie output files, e.g. ${OUTPUT_FILE_PREFIX}.pheno1.regenie  
    -istep1_pred_included=false                    # Compulsory user defined input: specify whether the step1 predictions are included. 

```

---

#### genome-wide gene-based association test with step1 output

The following example shows the **minimum** input parameters to be defined by the user to run gene-based test without regenie step 1 input.

To check details about the compulsory or optional flags, and user input file formats, please run ```dx run app-name --help ```, or refer to [**FAQ**](FAQ.md)

Example code:

```bash
dx cd project-zzzzzz                               # navigate to your project directory 

dx run app-regenie-step1 \    
    --priority low \                               # Define priority of the job; recommend to start with low, then if multiple failures >5, switch to high                                     
    --destination project-zzzzzz:/OUTPUT_PATH/ \   # Define the destination folder for the output files; if not defined, the output will be saved in the current working directory
    --name JOBNAME \                               # Name of the job for monitoring and tracking 
    -y --brief \                                   # Run the job in the background rather than interactively in the terminal 
    -ipheno_file=project-zzzzzz:file-zzzzzz \      # Compulsory user defined input: input phenotype file with either full file path, or file ID    
    -ipheno_binary=true \                          # Compulsory user defined input: whether the phenotype(s) is binary or quantitative
    -ipheno_colnames=PHENO \                       # Compulsory user defined input: define the column names in the phenotype file. If multiple phenotypes are provided, please use comma-separated format, e.g. PHENO1,PHENO2,PHENO3
    -ioutput_file_prefix=OUTPUT_FILE_PREFIX \      # Compulsory user defined input: define the output file prefix, this will be appended in front of the phenotype name followed by the default file extension of the regenie output files, e.g. ${OUTPUT_FILE_PREFIX}.pheno1.regenie  
    -istep1_pred_included=true \                  
    -istep1_file_pred=file-zzzzzz \                # Compulsory user defined input: specify whether the step1 predictions are included.
    -istep1_file_loco_multi_pheno=file-zzzzzz      # Compulsory user defined input: specify whether the step1 predictions are included.


dx run app-regenie-step2_per-gene-test \    
    --priority low \                               # Define priority of the job; recommend to start with low, then if multiple failures >5, switch to high                                     
    --destination project-zzzzzz:/OUTPUT_PATH/ \   # Define the destination folder for the output files; if not defined, the output will be saved in the current working directory
    --name JOBNAME \                               # Name of the job for monitoring and tracking 
    -y --brief \                                   # Run the job in the background rather than interactively in the terminal 
    -ipheno_file=project-zzzzzz:file-zzzzzz \      # Compulsory user defined input: input phenotype file with either full file path, or file ID    
    -ipheno_binary=true \                          # Compulsory user defined input: whether the phenotype(s) is binary or quantitative
    -ipheno_colnames=PHENO \                       # Compulsory user defined input: define the column names in the phenotype file. If multiple phenotypes are provided, please use comma-separated format, e.g. PHENO1,PHENO2,PHENO3
    -ioutput_file_prefix=OUTPUT_FILE_PREFIX \      # Compulsory user defined input: define the output file prefix, this will be appended in front of the phenotype name followed by the default file extension of the regenie output files, e.g. ${OUTPUT_FILE_PREFIX}.pheno1.regenie  
    -istep1_pred_included=true \                  
    -istep1_file_pred=file-zzzzzz \                # Compulsory user defined input: specify whether the step1 predictions are included.
    -istep1_file_loco_multi_pheno=file-zzzzzz      # Compulsory user defined input: specify whether the step1 predictions are included.

```

**Notes:** If a single phenotype is included, the ```-istep1_file_loco_one_pheno``` needs to be used with one input file (the *_1.loco file from step1, see [**FAQ**](FAQ.md) for regenie output file nomenclatures). If *P* penotype(s) are included, the ```-istep1_file_loco_one_pheno`` flag needs to be used with one .txt file as the input, where the list of "*_1.loco, *_2.loco...*_P.loco" files are saved as a list of file IDs: 

```
file-XXXXXXXXXXX
file-XXXXXXXXXXX
file-XXXXXXXXXXX
```
---

#### genome-wide variant-level association test with step1 output

The following example shows the **minimum** input parameters to be defined by the user to run gene-based test without regenie step 1 input.

To check details about the compulsory or optional flags, and user input file formats, please run ```dx run app-name --help ```, or refer to [**FAQ**](FAQ.md)

Example code:

```bash
dx cd project-zzzzzz                               # navigate to your project directory 

dx run app-regenie-step1 \    
    --priority low \                               # Define priority of the job; recommend to start with low, then if multiple failures >5, switch to high                                     
    --destination project-zzzzzz:/OUTPUT_PATH/ \   # Define the destination folder for the output files; if not defined, the output will be saved in the current working directory
    --name JOBNAME \                               # Name of the job for monitoring and tracking 
    -y --brief \                                   # Run the job in the background rather than interactively in the terminal 
    -ipheno_file=project-zzzzzz:file-zzzzzz \      # Compulsory user defined input: input phenotype file with either full file path, or file ID    
    -ipheno_binary=true \                          # Compulsory user defined input: whether the phenotype(s) is binary or quantitative
    -ipheno_colnames=PHENO \                       # Compulsory user defined input: define the column names in the phenotype file. If multiple phenotypes are provided, please use comma-separated format, e.g. PHENO1,PHENO2,PHENO3
    -ioutput_file_prefix=OUTPUT_FILE_PREFIX \      # Compulsory user defined input: define the output file prefix, this will be appended in front of the phenotype name followed by the default file extension of the regenie output files, e.g. ${OUTPUT_FILE_PREFIX}.pheno1.regenie  
    -istep1_pred_included=true \                  
    -istep1_file_pred=file-zzzzzz \                # Compulsory user defined input: specify whether the step1 predictions are included.
    -istep1_file_loco_multi_pheno=file-zzzzzz      # Compulsory user defined input: specify whether the step1 predictions are included.


dx run app-regenie-step2_per-variant-test \    
    --priority low \                               # Define priority of the job; recommend to start with low, then if multiple failures >5, switch to high                                     
    --destination project-zzzzzz:/OUTPUT_PATH/ \   # Define the destination folder for the output files; if not defined, the output will be saved in the current working directory
    --name JOBNAME \                               # Name of the job for monitoring and tracking 
    -y --brief \                                   # Run the job in the background rather than interactively in the terminal 
    -ipheno_file=project-zzzzzz:file-zzzzzz \      # Compulsory user defined input: input phenotype file with either full file path, or file ID    
    -ipheno_binary=true \                          # Compulsory user-defined input: set to true for binary phenotypes, false for quantitative phenotypes
    -ipheno_colnames=PHENO \                       # Compulsory user defined input: define the column names in the phenotype file. If multiple phenotypes are provided, please use comma-separated format, e.g. PHENO1,PHENO2,PHENO3
    -ioutput_file_prefix=OUTPUT_FILE_PREFIX \      # Compulsory user defined input: define the output file prefix, this will be appended in front of the phenotype name followed by the default file extension of the regenie output files, e.g. ${OUTPUT_FILE_PREFIX}.pheno1.regenie  
    -istep1_pred_included=true \                  
    -istep1_file_pred=file-zzzzzz \                # Compulsory user defined input: specify whether the step1 predictions are included.
    -istep1_file_loco_multi_pheno=zzzzzz           # Compulsory user defined input: specify whether the step1 predictions are included.

```

**Notes:** If a single phenotype is included, the ```-istep1_file_loco_one_pheno``` needs to be used with one input file (the *_1.loco file from step1, see [**FAQ**](FAQ.md) for regenie output file nomenclatures). If *P* penotype(s) are included, the ```-istep1_file_loco_one_pheno`` flag needs to be used with one .txt file as the input, where the list of "*_1.loco, *_2.loco...*_P.loco" files are saved as a list of file IDs: 

```
file-XXXXXXXXXXX
file-XXXXXXXXXXX
file-XXXXXXXXXXX
```
