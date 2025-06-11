#!/bin/bash
# This script runs regenie step 1
# Developed as the app ic-epid-regenie-step1

main() {

    #Set up the assest environment
if [[ "$DX_RESOURCES_ID" != "" ]]; then
  DX_ASSETS_ID="$DX_RESOURCES_ID"
else
  DX_ASSETS_ID="$DX_PROJECT_CONTEXT_ID"
fic

echo "Using DX_ASSETS_ID: $DX_ASSETS_ID"

        # Validate required inputs
    if [ -z "$pheno_file" ] || [ -z "$output_file_prefix" ] || [ -z "$pheno_colnames" ]; then
        dx-jobutil-report-error "Required inputs are missing"
        exit 1
    fi

    echo "Downloading input files..."

    dx download "$pheno_file" -o pheno_file
    
    echo "Value of pheno_binary: '$pheno_binary'"
    echo "Value of pheno_colnames: '$pheno_colnames'"
    echo "Value of output_file_prefix: '$output_file_prefix'"

    if [ -n "$covar_file" ]
    then
        dx download "$covar_file" -o covar_file
        else
        dx download $DX_ASSETS_ID:/file-J0gJ8QjJQkyz4pgyF4PyGBZy -o covar_file # base covar file (default)
    fi
    echo "Value of covar_file: '$covar_file'"
    
    if [ -n "$sample_include_file" ]
    then
        dx download "$sample_include_file" -o sample_include_file
        else
        dx download $DX_ASSETS_ID:/file-GzG8Gf8JQkyzfP4FyFpJkkvq -o sample_include_file # EU all sample list  -o sample_include
    fi
        echo "Value of sample_include_file: '$sample_include_file'"

    # Set default values for covariate column names if not provided
    if [ -z "$covar_colnames_continuous" ]; then
        covar_colnames_continuous="sex,age_at_baseline,age_sqr,PC{1:10}"
   fi

   if [ -z "$covar_colnames_categorical" ]; then
        covar_colnames_categorical="WES_batch"
   fi

    echo "Downloading the genotype bgen and files (recommended to use the default)..."

     if [ -n "$genotype_bgen_file" ]
    then
        dx download "$genotype_bgen_file" -o genotype_bgen_file.bgen
        else
        dx download $DX_ASSETS_ID:/file-J03y7P8JV2F1gfxXb52PP4vk -o genotype_bgen_file.bgen # QCed and lifted (default)
    fi

     if [ -n "$genotype_sample_file" ]
    then
        dx download "$genotype_sample_file" -o genotype_sample_file.sample
        else
        dx download $DX_ASSETS_ID:/file-J03y7P8JV2F28F50kjq1j5jV -o genotype_sample_file.sample  #(default)
    fi


   echo "Start loading regenie" 
   export PATH=$PATH:/usr/bin/regenie_v4.1.gz_x86_64_Linux


   echo "Start running regenie step 1"
    

    # Check binary vs quantitative trait
    if [ "$pheno_binary" = "true" ]; then
        trait_flag="--bt"
    else
        trait_flag="--qt"
    fi

    regenie_v4.1.gz_x86_64_Linux \
    --step 1 \
    $trait_flag \
    --bgen genotype_bgen_file.bgen \
    --sample genotype_sample_file.sample \
    --keep sample_include_file \
    --covarFile covar_file \
    --phenoFile pheno_file \
    --phenoColList $pheno_colnames \
    --covarColList $covar_colnames_continuous \
    --catCovarList $covar_colnames_categorical \
    --bsize 1000 \
    --threads 8 \
    --lowmem \
    --out $output_file_prefix
    
    echo "Regenie step1 completed. Uploading output files."

    # Check if regenie completed successfully
if [ $? -ne 0 ]; then
    dx-jobutil-report-error "Regenie step 1 failed"
    exit 1
fi

# Add file existence checks
if ! ls *.loco &>/dev/null; then
    dx-jobutil-report-error "No .loco files found after regenie completed"
    exit 1
fi

    # Note that this entire bash script is executed with -e
    # when running in the cloud, so any line which returns a nonzero
    # exit code will prematurely exit the script; if no error was
    # reported in the job_error.json file, then the failure reason
    # will be AppInternalError with a generic error message.

# Upload output files 

# initialize arrays to hold the output file IDs    
output_file_loco=()

# Find and upload output files 
for file in *.loco; do
    [ -e "$file" ] || continue  # Skip if no files match
    file_id=$(dx upload "$file" --brief)
    output_file_loco+=("$file_id")
done

# Register outputs based on the file ID arrays
for i in "${!output_file_loco[@]}"; do
    dx-jobutil-add-output output_file_loco "${output_file_loco[$i]}" --class=array:file
done

## upload the log and _pred.list files 

log_file=$(ls *.log)
pred_list_file=$(ls *_pred.list)

output_file_log=$(dx upload $log_file --brief)
output_file_pred_list=$(dx upload $pred_list_file --brief)

dx-jobutil-add-output output_file_log "$output_file_log" --class=file
dx-jobutil-add-output output_file_pred_list "$output_file_pred_list" --class=file

echo "Uploaded .loco file(s): ${output_file_loco[@]}"
echo "Uploaded .log file: $output_file_log"
echo "Uploaded pred.list file: $output_file_pred_list"

}