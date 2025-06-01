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
    
2.  **How are the raw data quality checked?**  
    Please refer to the method documentation file in Word ([link to wiki page; gene_based_test_method.doc]) (access for IC internal users only).

3. **What are the definitions of gene "masks" used in the gene-based test?**  
    Please refer to the method documentation file in Word ([link to wiki page; gene_based_test_method.doc]) (access for IC internal users only).

4. **How do I know what are the default input files used in the app and whether I can change them?**  
    For regenie step 1 genotype file input, the default genotype input file can be optionally changed to user-defined genotype files in BGEN format, using `-igenotype_bgen_file` and `-igenotype_sample_file`.
    For regenie step 1 genotype file input, the default genotype input file can optionally be changed to user-defined genotype files in BGEN format, using the `-igenotype_bgen_file` and `-igenotype_sample_file` options.
    For regenie step 2 genotype file input, the default genotype file in PGEN format is hardcoded into the app. File IDs can be viewed in the app script in the `scripts/` folder in this repository. Only authorised users will be able to view these files.

    For both regenie step 1 and 2, the following files can also be optionally modified:
    - Covariate file
    - Sample inclusion file (**Note:** the default is to use the white EU ancestry only)

    For detailed information, please see:  
    ```
    dx run app-name --help
    ```

5. **What output files should I expect to get from each tool?**  
    The output files from each tool follow the formats below:

    #### regenie_step1

    | File Name         | Description                |
    |-------------------|---------------------------|
    | *[example1.txt]*  | *[Description 1]*         |
    | *[example2.txt]*  | *[Description 2]*         |

    *(Replace with actual file names and descriptions)*

6. **How do you interpret the columns from the gene-based test output?**  
    **** The output columns can be interpreted as the followings. Notes that the user needs to decide which mask, MAF threshold and test methods they want to focus on based on their own study context and objectives. 
    | Column name       | Description                |
    |-------------------|---------------------------|
    | *[example1.txt]*  | *[Description 1]*         |
    | *[example2.txt]*  | *[Description 2]*         |

