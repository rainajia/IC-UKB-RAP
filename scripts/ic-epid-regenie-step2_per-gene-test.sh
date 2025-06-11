#!/bin/bash
# ic-epid-regenie-step2_per-gene-test

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
        echo "No output_file_prefix provided, using default 'per-gene-test' as the output file prefix before the attachment of phenotype name(s)."
        output_file_prefix="per-gene-test"
    else
        echo "Using provided output_file_prefix: '$output_file_prefix'"
    fi
    echo "Value of output_file_prefix: '$output_file_prefix'"


    
    if [ -n "$sample_include_file" ]
    then
        echo "Downloading sample_include_file: '$sample_include_file'"
        dx download "$sample_include_file" -o sample_include_file
        else
        echo "Donwloading sample_include_file: default sample include file used "
        dx download $DX_ASSETS_ID:/file-GzG8Gf8JQkyzfP4FyFpJkkvq -o sample_include_file # EU all sample list  -o sample_include
    fi

        if [ -n "$covar_file" ]
    then
        echo "Downloading covar_file: '$covar_file'"
        dx download "$covar_file" -o covar_file
        else
        echo "Downloading covar_file: default covar file used "
        dx download $DX_ASSETS_ID:/file-J0gJ8QjJQkyz4pgyF4PyGBZy -o covar_file # base covar file (default)
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


## Load the hardedcoded files from app assets
echo "Downloading QCed WES pgen files ..."
dx download $DX_ASSETS_ID:/file-J0qJ9q8JPG60JqqJbxv7Yf72 -o WES_QCed_pgen_files.tar.gz
tar -xzvf WES_QCed_pgen_files.tar.gz

# file format:
# ukb23158_c${chr}_b0_v1_QCed.pgen
# ukb23158_c${chr}_b0_v1_QCed.pvar
# ukb23158_c${chr}_b0_v1_QCed.psam


echo "Downloading all regenie mask files ..."
dx download $DX_ASSETS_ID:/file-J1409qQJQkybKg0Fvb37Z4bG -o regenie_mask_files_autosomes.tar.gz
tar -xzvf regenie_mask_files_autosomes.tar.gz

# file format:
# chr${chr}_set_list_file.tsv
# chr${chr}_annotation_file.tsv
# chr${chr}_mask_file.tsv


# Define model inputs based on optional flags 
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

    if [ -z "$binary_trait_bias_correction_method" ]; then
        binary_trait_bias_correction_method="--firth --approx"
        elif [ "$binary_trait_bias_correction_method" = "firth" ]; then
            binary_trait_bias_correction_method="--firth --approx"
        elif [ "$binary_trait_bias_correction_method" = "spa" ]; then
            binary_trait_bias_correction_method="--spa"
        else
        echo "Invalid binary_trait_bias_correction_method: $binary_trait_bias_correction_method"
        exit 1
   fi


echo "Start running regenie by chromosomes..." 
export PATH=$PATH:/usr/bin/regenie_v4.1.gz_x86_64_Linux

# Condition on the existence of a gene list

if [ -z "$gene_list" ]; then
    echo "Start genome-wide gene-based analysis..."

    MAX_JOBS=16
    JOBS_RUNNING=0

    for chr in {1..22}; do
        (
            echo "Start downloading QCed WES for chromosome $chr"

            pgen_file_prefix="ukb23158_c${chr}_b0_v1_QCed"

            echo "Running regenie for QCed pgen file prefix: $pgen_file_prefix"

            # Check mask files are correct (make these bundleDepends)
            echo "Mask file: chr${chr}_mask_file.tsv; set_list_file: chr${chr}_set_list_file.tsv; annotation_file: chr${chr}_annotation_file.tsv"

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
                --set-list chr${chr}_set_list_file.tsv \
                --anno-file chr${chr}_annotation_file.tsv \
                --mask-def chr${chr}_mask_file.tsv \
                --aaf-bins 0.001,0.01 \
                --build-mask max \
                --vc-maxAAF 0.001 \
                --vc-tests skato \
                --vc-MACthr 10 \
                $binary_trait_bias_correction_method \
                --pThresh 0.01 \
                --bsize 500 \
                --threads 1 \
                --write-mask-snplist \
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

else
    echo "Start gene-based analysis for the gene list provided..."

    python3 /usr/bin/parse_gene_list.py $gene_list

    chromosome_list=$(awk -F'\t' '{print $1}' parsed_gene_list.txt | paste -sd,)

    MAX_JOBS=16
    JOBS_RUNNING=0

    for chr in ${chromosome_list//,/ }; do
        (
            echo "Start downloading QCed WES for chromosome $chr"
            
            pgen_file_prefix="ukb23158_c${chr}_b0_v1_QCed"

            echo "Running regenie for QCed pgen file prefix: $pgen_file_prefix"

            # Check mask files are correct (make these bundleDepends)
            echo "Mask file: chr${chr}_mask_file.tsv; set_list_file: chr${chr}_set_list_file.tsv; annotation_file: chr${chr}_annotation_file.tsv"

            # Extract the gene list for the current chromosome
            gene_list_formatted=$(awk -F'\t' -v chr="$chr" '$1 == chr {print $2}' parsed_gene_list.txt)
            
            echo "Running for the following genes: $gene_list_formatted"

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
                --set-list chr${chr}_set_list_file.tsv \
                --anno-file chr${chr}_annotation_file.tsv \
                --mask-def chr${chr}_mask_file.tsv \
                --aaf-bins 0.001,0.01 \
                --build-mask max \
                --vc-maxAAF 0.001 \
                --vc-tests skato \
                --vc-MACthr 10 \
                $binary_trait_bias_correction_method \
                --pThresh 0.01 \
                --bsize 500 \
                --threads 1 \
                --write-mask-snplist \
                --extract-setlist $gene_list_formatted \
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

fi

## Processing results by chromosomes into a combined outputcome file 

echo "All chromosomes completed; start combining regenie results by chromosomes..."

if [ -f "/usr/bin/process_regenie_output_gene-test.py" ]; then
    python3 /usr/bin/process_regenie_output_gene-test.py $output_file_prefix $pheno_colnames
    if [ $? -ne 0 ]; then
        echo "Warning: Python script for processing results failed."
    fi
else
    echo "Warning: Python script not found."
fi

# Processing output files 
  echo "results files are ready to be uploaded."

# remove all files starting with "chr" to be uploaded; including .regene nad _masks.snplst files by chromosomes
  rm chr*

# print what's left in the directory as a sanity check
   echo "Files left in the directory after cleanup:"
   ls -l

# initialize arrays to hold the output file IDs    
output_regenie_file=()

# Find and upload regnie output file(s) 
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

## upload the log file
log_file_name=$(ls *.log)
output_regenie_log_file=$(dx upload $log_file_name --brief)
dx-jobutil-add-output output_regenie_log_file "$output_regenie_log_file" --class=file
echo "Uploaded regenie log file: $output_regenie_log_file"


# upload the mask_list file; 
mask_snplist_file_name=$(ls *.snplist)
output_mask_snplist=$(dx upload $mask_snplist_file_name --brief)
dx-jobutil-add-output output_mask_snplist "$output_mask_snplist" --class=file
echo "Uploaded mask.snplist file: $output_mask_snplist"

}