#!/bin/bash
# ic-epid-regenie-step2_per-variant-test


main() {
    #Set up the assest environment
if [[ "$DX_RESOURCES_ID" != "" ]]; then
  DX_ASSETS_ID="$DX_RESOURCES_ID"
else
  DX_ASSETS_ID="$DX_PROJECT_CONTEXT_ID"
fi

echo "Using DX_ASSETS_ID: $DX_ASSETS_ID"

    echo "Downloading input files..."

    echo "Downloading pheno_file: '$pheno_file'"
    dx download "$pheno_file" -o pheno_file

    echo "Value of pheno_binary: '$pheno_binary'"
    echo "Value of pheno_colnames: '$pheno_colnames'"

    if [ -z $output_file_prefix ]
    then
        echo "No output_file_prefix provided, using default 'per-variant-test' as a prefix before phenotype name(s)."
        output_file_prefix="per-variant-test"
    else
        echo "Using provided output_file_prefix: '$output_file_prefix'"
    fi
    echo "Value of output_file_prefix: '$output_file_prefix'"
    
    if [ -n "$covar_file" ]
    then
        echo "Downloading covar_file: '$covar_file'"
        dx download "$covar_file" -o covar_file
        else
        echo "Downloading covar_file: default covar file used "
        dx download $DX_ASSETS_ID:/file-J0gJ8QjJQkyz4pgyF4PyGBZy -o covar_file # base covar file (default)
    fi

    
    if [ -n "$sample_include_file" ]
    then
        echo "Downloading sample_include_file: '$sample_include_file'"
        dx download "$sample_include_file" -o sample_include_file
        else
        echo "Donwloading sample_include_file: default sample include file used "
        dx download $DX_ASSETS_ID:/file-GzG8Gf8JQkyzfP4FyFpJkkvq -o sample_include_file # EU all sample list (default)
    fi

    if [ -z "$covar_colnames_continuous" ]; then
        echo "Value of covar_colnames_continuous: default covariates used."
        covar_colnames_continuous="sex,age_at_baseline,age_sqr,PC{1:10}"
        else
        echo "Value of covar_colnames_continuous: '$covar_colnames_continuous'"
   fi

   if [ -z "$covar_colnames_categorical" ]; then
        echo "Value of covar_colnames_continuous: default covariates used."
        covar_colnames_categorical="WES_batch"
        else
        echo "Value of covar_colnames_categorical: '$covar_colnames_categorical'"
   fi

      if [ -z "$step1_pred_included" ]; then
        echo "Is step 1 predictions included: false (default)"
        else
        echo "Is step 1 predictions included: $step1_pred_included"
   fi

   if [ -n "$step1_file_pred" ]
     then
       echo "Downloading step 1 _pred.list file: '$step1_file_pred'"
        dx download "$step1_file_pred" -o  step1_file_pred
            if [ ! -f step1_file_pred ]; then
        echo "Error: step1_file_pred does not exist."
        exit 1
    else
        ls -l step1_file_pred
    fi
    fi

    if [ -n "$step1_file_loco_one_pheno" ]; then
       echo "Downloading loco file for single phenotype: '$step1_file_loco_one_pheno'"
       dx download "$step1_file_loco_one_pheno"
    # print the name of the downloaded file
    if [ ! -f *.loco ]; then
        echo "Error: No .loco files found."
        exit 1
    else
        ls -l *.loco
        fi
    fi

if [ -n "$step1_file_loco_multi_pheno" ]; then
    dx download "$step1_file_loco_multi_pheno" -o loco_files.list
    mapfile -t loco_files_array < loco_files.list
    
    for loco_file in "${loco_files_array[@]}"; do
        echo "Downloading loco file for multiple phenotypes: '$loco_file'"
        dx download "$loco_file"
        ## check pred and loco files 
    done 
        
    if [ ! -f *.loco ]; then
        echo "Error: No .loco files found."
        exit 1
    else
        ls -l *.loco
    fi
fi

if [ -z "$minMAC" ]; then
        echo "Minimum MAC included for variants: 5 (default)"
        minMAC=10
        else
        echo "Minimum MAC included for variants: $minMAC"
   fi


# Download pgen files by chromosomes
echo "Downloading genotype pgen files..."

    if [ -n "$genotype_pgen_file_tarball" ];
    then
        dx download "$genotype_pgen_file_tarball" -o WES_QCed_pgen_files.tar.gz
        tar --no-same-owner -xzvf WES_QCed_pgen_files.tar.gz
     
        if [ -z "$genotype_pgen_file_prefix" ]; then
        echo "Customised genotype pgen files are used, but --igenotype_pgen_file_prefix input is missing."
        exit 1
        else
        echo "Genotype file by chromosomes with the file prefix = $genotype_pgen_file_prefix"
        fi

        else
        dx download $DX_ASSETS_ID:/file-J0qJ9q8JPG60JqqJbxv7Yf72 -o WES_QCed_pgen_files.tar.gz # QCed and lifted (default)
        tar -xzvf WES_QCed_pgen_files.tar.gz
    fi


echo "Start running regenie..." 
export PATH=$PATH:/usr/bin/regenie_v4.1.gz_x86_64_Linux


MAX_JOBS=8
JOBS_RUNNING=0

for chr in {1..22}; do
  (
    echo "Processing chromosome $chr"

    if [ -z "$genotype_pgen_file_prefix" ]; then
        pgen_file_prefix="ukb23158_c${chr}_b0_v1_QCed"
     else
        pgen_file_prefix="${genotype_pgen_file_prefix}_chr${chr}"
    fi


    echo "Running regenie for the pgen file prefix: $pgen_file_prefix"

    # Check if step1_pred_file is set
    if [ "$step1_pred_included" = "true" ]; then
        pred_flag="--pred step1_file_pred"
    else
        pred_flag="--ignore-pred"
    fi

    # Check binary vs quantitative trait
    if [ "$pheno_binary" = "true" ]; then
        trait_flag="--bt"
    else
        trait_flag="--qt"
    fi

    # Run regenie
    regenie_v4.1.gz_x86_64_Linux \
      --step 2 \
      $pred_flag \
      $trait_flag \
      --pgen $pgen_file_prefix \
      --keep sample_include_file \
      --covarFile covar_file \
      --phenoFile pheno_file \
      --phenoColList $pheno_colnames \
      --covarColList $covar_colnames_continuous \
      --catCovarList $covar_colnames_categorical \
      --minMAC $minMAC \
      --bsize 500 \
      --firth --approx \
      --pThresh 0.01 \
      --threads 2 \
      --out chr${chr}

  rm ${pgen_file_prefix}*

  ) &  # Run in background

  ((JOBS_RUNNING+=1))

  # Control max parallel jobs
  if (( JOBS_RUNNING >= MAX_JOBS )); then
    wait
    JOBS_RUNNING=0
  fi

done

wait  # Final wait for all jobs

## Processing results by chromosomes into a combined outputcome file 

echo "All chromosomes completed; start combining regenie results by chromosomes..."

if [ -f "/usr/bin/process_regenie_output.py" ]; then
    python3 /usr/bin/process_regenie_output.py $output_file_prefix $pheno_colnames
    if [ $? -ne 0 ]; then
        echo "Warning: Python script for processing results failed."
    fi
else
    echo "Warning: Python script not found."
    # Add fallback file combining code
fi


    # Note however that this entire bash script is executed with -e
    # when running in the cloud, so any line which returns a nonzero
    # exit code will prematurely exit the script; if no error was
    # reported in the job_error.json file, then the failure reason
    # will be AppInternalError with a generic error message.


# Processing output files as arrays
    echo "results files are ready to be uploaded."

    # remove all files starting with "chr" to be uploaded
    rm chr*

# initialize arrays to hold the output file IDs    
output_regenie_file=()

# Find and upload output files 
for file in *.regenie; do
    [ -e "$file" ] || continue  # Skip if no files match
    file_id=$(dx upload "$file" --brief)
    output_regenie_file+=("$file_id")
done

# Register outputs based on the file ID arrays
for i in "${!output_regenie_file[@]}"; do
    dx-jobutil-add-output output_regenie_file "${output_regenie_file[$i]}" --class=array:file
done

echo "Uploaded regenie output file(s): ${output_regenie_file[@]}"

## upload the log and _pred.list files 
output_regenie_log_file=()

# Find and upload output files 
for file in *.log; do
    [ -e "$file" ] || continue  # Skip if no files match
    file_id=$(dx upload "$file" --brief)
    output_regenie_log_file+=("$file_id")
done

# Register outputs based on the file ID arrays
for i in "${!output_regenie_log_file[@]}"; do
    dx-jobutil-add-output output_regenie_log_file "${output_regenie_log_file[$i]}" --class=array:file
done

echo "Uploaded regenie log file: ${output_regenie_log_file[@]}"

}