# FAQ

<details>
<summary>1. <strong>What are the expected cost and runtime for step 1 and step 2?</strong></summary>

The estimated cost for the default setting using ~400K white European ancestry are as the follows: 

- For regenie_step1 using the followings:
  High priority job: £1.8-£2.5, ~7.5 hours 
  Low priority job: £0.5-£1.5, >8 hours (risk of spot instance interruptions)
  **Recommendations**: Start with high priority to avoid spot instance interruptions since the job is long.  

- For step 2 genome-wide gene-based test:
  
- For step 2 genome-wide per-variant test:
  High priority: £1.8-£2.5, ~4.5 hours
  Low priority:£0.5-£1.5, >4.5 hours (risk of spot interruptions)
  **Recommendation**: Start with low priority, switch to high priority if job is interrupted with more than 3 tries. 

Factors that will affect run time and cost:
  i. ***Definition for "job priority" will affect cost:***
    - Low priority is recommended for gene-based tests as a start.
    - High priority is recommended for step 1 and step 2, unless the job is ran a sample <100K.

  ii. ***Sample size will affect runtime and cost:***
    - Smaller samples will run quicker.

  iii. ***Number of phenotypes included in one job***
    - Regenie allows mutliple phenotypes to be included in one job as a means to improve computation efficiency, however, increasing the phenotypes will non-linearly affect the runtime, especitally for regenie step 1. Please note that the current app resource configuration has not been tested in a job with more than 3 phenotypes. 
  
  iv. ***For gene-based test, gene-specific jobs will be quick to run***
    - If a list of genes are provided, the step2 gene-based test will be quicker to run 

</details>

<details>
<summary>2. <strong>What quality checkes has been done for the raw seuqencing data? </strong></summary> 
  Please refer to the method documentation file [method.dox link to be added] (access for IC internal users only).
</details>

<details>
  <summary>3. <strong> In the gene-based tests, how are the gene "masks" been defined?</strong></summary>
  Please refer to the method documentation file in Word [method.dox link to be added] (access for IC internal users only).
</details>

<details>
  <summary>4. <strong>How do I know what are the default input files used in the app and whether I can change them?</strong></summary>

For regenie step 1 genotype file input, the default genotype input file can optionally be changed to user-defined genotype files in BGEN format, using the following options:

  ```
    -igenotype_bgen_file
    -igenotype_sample_file
  ```

For regenie step 2 genotype file input, the default genotype file in PGEN format is hardcoded into the app. File IDs can be viewed in the app script in the `scripts/` folder in this repository. Only authorised users will be able to view/use these files.

For both regenie step 1 and 2, the following files can also be optionally modified:
    - Covariate file
    - Sample inclusion file (**Note:** the default is to use the white EU ancestry only)

For detailed information, please see:

  ```bash
    dx run app-name --help
  ```
</details>

<details>
  <summary>5. <strong>What output files should I expect to get from each tool?</strong></summary>

The output files from each tool follow the formats below:

regenie_step1

  | File Name         | Description               |
  |-------------------|---------------------------|
  | _pred.list  | *[Description 1]*         |
  | *[example2.txt]*  | *[Description 2]*         |


regenie_step2 per-variant or per-gene tests

  | File Name                                                        | Description                                         |
  |------------------------------------------------------------------|-----------------------------------------------------|
  | `${output_file_prefix}_${phenotype_colnames}_autosomes.regenie`  | Association test results                            |
  | `${output_file_prefix}_autosomes.log`                            | Log file for the association test run               |
  | `${output_file_prefix}_autosomes_masks.snplist`                  | List of variants in each defined mask for downstream analysis |

**Notes**: If multiple phenotypes are included, each phenotype will have a separate '.regenie' file. Each job will only have 1 .log file and one .snplist file. 

</details>

<details>
<summary>6. <strong>How do you interpret the columns from the gene-based test output?</strong></summary>

  The output columns can be interpreted as follows. Note that the user needs to decide which mask, MAF threshold, and test methods to focus on based on their own study context and objectives.

   | Column Name         | Description                |
   |---------------------|---------------------------|
   | *[example1.txt]*    | *[Description 1]*         |
   | *[example2.txt]*    | *[Description 2]*         |

</details>
