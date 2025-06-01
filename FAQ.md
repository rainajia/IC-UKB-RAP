# FAQ

<details>
<summary>1. <strong>What are the expected cost and runtime for step 1 and step 2?</strong></summary>

- For step 1 job in white EU ancestry (the default setting) with at most 3 traits on a high priority job: **7.5 hr, £1.7**
- For step 2 genome-wide gene-based test, in ~400k white EU ancestry (the default setting) with at most 3 phenotypes on a high priority job: **xxx hr, £xxx**
- For step 2 genome-wide per-variant test, in ~400k white EU ancestry (the default setting) with at most 3 phenotypes on a high priority job: **4.5 hr, £0.6**

Factors that will affect run time and cost:
  i. **Definition for "job priority" will affect cost:**
    - Low priority is recommended for gene-based tests.
    - High priority is recommended for step 1, unless the job is run in a smaller sub-sample (<100K).
    - High priority is recommended for step 2 per-variant test, unless the job is run in a subsample (<100K).

  ii. **Sample size will affect runtime and cost:**
    - Smaller samples will run quicker.

  iii. **Number of phenotypes included in one job will non-linearly affect the runtime for regenie step 1.**

</details>
    
<details>
<summary>2. <strong>How has the raw data been quality checked</strong></summary>

    Please refer to the method documentation file in Word ([link to wiki page; gene_based_test_method.doc]) (access for IC internal users only).
    Quality control steps include checks for sample and variant missingness, Hardy-Weinberg equilibrium, sex discrepancies, and relatedness. Additional filters may be applied as described in the method documentation.
</details>

<details>
<summary>3. <strong>For the gene-based test, how has the variants been annotated, and what are the definitions used for gene "masks"?</strong></summary>
    
    Please refer to the method documentation file in Word ([link to wiki page; gene_based_test_method.doc]) (access for IC internal users only).
    
</details>
    
<details>
<summary>4. <strong>How do I know what are the default input files used in the app and whether I can change them?</strong></summary>
    
    For regenie step 1 genotype file input, the default genotype input file can optionally be changed to user-defined genotype files in BGEN format, using the `-igenotype_bgen_file` and `-igenotype_sample_file` options.  
    For regenie step 2 genotype file input, the default genotype file in PGEN format is hardcoded into the app. File IDs can be viewed in the app script in the `scripts/` folder in this repository. Only authorised users will be able to view these files.
    
    For both regenie step 1 and 2, the following files can also be optionally modified:
    - Covariate file
    - Sample inclusion file (**Note:** the default is to use the white EU ancestry only)
    
    For detailed information, please see:  
</details>

<details>
<summary>5. <strong>What output files should I expect to get from each tool?</strong></summary>

    The output files from each tool follow the formats below:

    regenie_step1

    | File Name         | Description                |
    |-------------------|---------------------------|
    | *[example1.txt]*  | *[Description 1]*         |
    | *[example2.txt]*  | *[Description 2]*         |

    *(Replace with actual file names and descriptions)*
</details>

<details>
<summary>6. <strong>How do you interpret the columns from the gene-based test output?</strong></summary>

   The output columns can be interpreted as follows. Note that the user needs to decide which mask, MAF threshold, and test methods to focus on based on their own study context and objectives.

   | Column Name         | Description                |
   |---------------------|---------------------------|
   | *[example1.txt]*    | *[Description 1]*         |
   | *[example2.txt]*    | *[Description 2]*         |

   *(Replace with actual column names and descriptions)*
</details>


