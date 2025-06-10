# FAQ

<details>
<summary><strong>1. What are the expected cost and runtime for step 1 and step 2?</strong></summary>

The estimated cost for genome-wide jobs in ~400K white European ancestry samples using the default setting are as the follows: 

- For regenie_step1: <br><br>
  High priority job: £1.8-£2.5, 7.5 hours <br><br>
  Low priority job: £0.5-£1.5, >7.5 hours of elapsed time (risk of spot instance interruptions)<br><br>
  **Recommendations**: Start with high priority to avoid spot instance interruptions.  

- For step 2 genome-wide gene-based test: <br><br>
  High priority job: £2-3, 4.5 hours <br><br>
  Low priority job: £0.5-£1, >4 hours of elapsed time (risk of spot instance interruptions)<br><br>
  **Recommendations**: Start with low priority, switch to high priority if job is interrupted with more than 3 tries. Use low priority if only a list of genes are tested (e.g. a list of 10 gene takes less than 20 mins).  

- For step 2 genome-wide per-variant test: <br><br>
  High priority: £1.5-£2.5, 4.5 hours <br><br>
  Low priority:£0.5-£1.5, >4.5 hours (risk of spot interruptions)<br><br>
  **Recommendation**: Start with low priority, switch to high priority if job is interrupted with more than 3 tries. <br><br>


Factors that will affect run time and cost:

***Definition for "job priority"***
  - High priority is recommended for step 1 and step 2 for genome-wide jobs unless a smaller cohort <50K is included.
  - Low priroity is recommended for gene-based jobs if only a small list of genes are included. 

***Sample size***
  - Smaller samples will run quicker.

***Number of phenotypes included in one job***
  - Regenie allows mutliple phenotypes to be included in one job as a means to improve computation efficiency, however, increasing the phenotypes will non-linearly affect the runtime, especitally for regenie step 1. Please note that the current app resource configuration has not been tested in a job with more than 3 phenotypes. 
  
***For gene-based test, gene-specific jobs with a defined list of genes will be significantly quicker to run than genome-wide jobs***
  - If a list of genes are provided, the step2 gene-based test will be quicker to run <br><br>


</details>


<details>
<summary><strong>2. What quality checkes has been done for the raw seuqencing data? </strong></summary> 

Please refer to the method documentation [Method.doc](https://imperiallondon-my.sharepoint.com/:w:/g/personal/yjia2_ic_ac_uk/ESCl98tv1oBJoQu2-3aSYSABEB-V5octWrN16b5EdyKJjA?e=SFReYr) (access for internal users only).

</details>

<details>
  <summary><strong>3. In the gene-based tests, how are the gene "masks" defined?</strong></summary>

Please refer to the method documentation [Method.doc](https://imperiallondon-my.sharepoint.com/:w:/g/personal/yjia2_ic_ac_uk/ESCl98tv1oBJoQu2-3aSYSABEB-V5octWrN16b5EdyKJjA?e=SFReYr) (access for internal users only).


</details>


<details>
   <summary><strong>4. How do I know what are the default input files that has been used in the app, and whether I can change them?</strong></summary>

For detailed information about the full list of optional parameters and the required input format in the three apps, please see:

  ```bash
    dx run app-name --help
  ```

Breifly, for regenie step 1 and 2, covariates and individual list for inclusion can be optionally modified when running the apps:
    - Covariate file  (**Note:** the default is to adjust for sex, age, age2, PC1-10 and WES batches)
    - Sample inclusion file (**Note:** the default is to use the white EU ancestry only)

For step1, the default genotype file (UKB genotype array in GRCh38) can be optionally changed to user-defined genotype files in BGEN format with the following options:

  ```
    -igenotype_bgen_file
    -igenotype_sample_file
  ```

For step 2 per-variant test, the default genotype file (UKB WES in GRCh38) can be optionally changed to user-defined genotype files in PGEN format with the following options:

  ```
    -igenotype_pgen_file_tarball
    -igenotype_pgen_file_prefix
  ```

For step 2 per-gene-test, the genotype file input (QCed WES data in GRCh38) is hard-coded into the app and cannot be changed. <br><br>

All the default files used can be found either in the app --help descriptionso r in the `scripts/` folder in this repository. Only authorised users will be able to view these files. <br><br>

</details>


<details>
  <summary><strong>5. What output files should I expect to get from each tool?</strong></summary>

The output files from each tool follow the format demonstrated below. For more information regarding regenie output files, please refer to the regenie documentation. 

regenie_step1

  | File Name                        | Description                                         |
  |----------------------------------|-----------------------------------------------------|
  | `${output_file_prefix}_pred.list` | Contains a list of the `.loco` files to use for step 2 |
  | `${output_file_prefix}_1.loco`    | Contains the phenotype predictions                  |
  | `${output_file_prefix}.log`       | Log file for the job                            |

**Notes**:
  - If multiple phenotypes are included, each phenotype will be saved as a separate '.loco' file in the format: for ***P*** phenotypes, there will be `${output_file_prefix}_1.loco,${output_file_prefix}_2.loco, ${output_file_prefix}_3.loco, ${output_file_prefix}_P.loco` output files.


regenie_step2 per-variant or per-gene tests

  | File Name                                                        | Description                                         |
  |------------------------------------------------------------------|-----------------------------------------------------|
  | `${output_file_prefix}_${phenotype_colnames}_autosomes.regenie`  | Association test results                            |
  | `${output_file_prefix}_autosomes.log`                            | Log file for the association test run               |
  | `${output_file_prefix}_autosomes_masks.snplist`                  | List of variants in each defined mask for each gene |

**Notes**:
  - If multiple phenotypes are included, each phenotype will be saved as a separate '.regenie' file. Each job will only have one ".log" file and one ".snplist" file. 
  - If a list of genes are provided for the gene-based test, the output file name will be the same with the association test results for only the genes defined. 


</details>


<details>
<summary><strong>6. For the gene-based test, how do I interpret the columns from the regenie output?</strong></summary>

  The output columns can be interpreted as the following. User needs to decide which mask, MAF threshold, and test methods to focus on based on their own study context and objectives.

   | Column Name         | Description                |
   |---------------------|---------------------------|
   | SYMBOL  | gene name         |
   | GENE    | Ensembl  gene ID         |
   | CHROM   | chromosome of the gene   |
   | GENPOS  | here regenie outputs the POS for the first variant included in the mask for the gene |
   | MASK    | the pre-defined masks for collapsing variants   |
   | MAF     | the pre-defined minor allele frequency threshold: singletons, 0.1%, 1% |
   | TEST    | the collapsing methods used: burden, SKAT, SKTA-O |
   | N       | total sample size |
   | BETA    | coeffient estimate; note that this is log(odd) if binary trait |
   | SE      | standard error |
   | CHISQ   | Chi-squared test |
   | LOG10P  | -log10(P)        |
   | P | p-value |

</details>


<details>
<summary><strong>7. For the gene-based test, how can I know the total number of carriers/the number of homozygous carriers/the number of heterozygous carriers for the variants included in a gene mask?</strong></summary>

We currently do not have a dedicated tool for obtaining this information. However, you can extract it by following the general steps below on RAP, using either SwissArmyKnife or CloudWorkStation (recommended if you only have a short list of variants):

1. For your gene mask of interest, extract the list of variants included in the mask from the `_masks.snplist` file in the regenie output.
2. Extract these variants from the QCed WES data in PGEN format and save as VCF format. The QCed WES files are located in: `project-GyZxPF8JQkyq9JVxZjQ2FvqK:/filtered/`. 
3. Use `bcftools +fill-tags` to annotate the VCF file with relevant information. For example:`bcftools +fill-tags input.vcf.gz -Oz -o output.vcf.gz -- -t AC,AF,MAF,AC_Hom,AC_Het,AC_Hemi`. 
   This will add annotations such as allele count (AC), allele frequency (AF), minor allele frequency (MAF), homozygous allele count (AC_Hom), heterozygous allele count (AC_Het), and hemizygous allele count (AC_Hemi) for each variant in the VCF file.
4. For easier further analysis, you could extract the relevant fields from the annotated VCF and save them as a text file using `bcftools query -f`.

Carrier number for the variant = AC_HET + AC_HOM/2


</details>
