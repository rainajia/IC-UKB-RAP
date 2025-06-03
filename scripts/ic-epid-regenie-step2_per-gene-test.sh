#!/bin/bash
# ic-epid-regenie-step2_per-variant-test


main() {

    echo "Downloading input files..."

    echo "Downloading pheno_file: '$pheno_file'"
    dx download "$pheno_file" -o pheno_file

    echo "Value of pheno_binary: '$pheno_binary'"
    echo "Value of pheno_colnames: '$pheno_colnames'"

    if [ -z $output_file_prefix ]; then
        echo "No output_file_prefix provided, using default 'per-gene-test'."
        output_file_prefix="per-gene-test"
    else
        echo "Using provided output_file_prefix: '$output_file_prefix'"
    fi
    echo "Value of output_file_prefix: '$output_file_prefix'"
    
    if [ -n "$covar_file" ]; then
        echo "Downloading covar_file: '$covar_file'"
        dx download "$covar_file" -o covar_file
    else
        echo "Downloading default covar file"
        dx download project-GyZxPF8JQkyq9JVxZjQ2FvqK:file-J0gJ8QjJQkyz4pgyF4PyGBZy -o covar_file
    fi

    if [ -n "$sample_include_file" ]; then
        echo "Downloading sample_include_file: '$sample_include_file'"
        dx download "$sample_include_file" -o sample_include_file
    else
        echo "Downloading default sample include file"
        dx download project-GyZxPF8JQkyq9JVxZjQ2FvqK:file-GzG8Gf8JQkyzfP4FyFpJkkvq -o sample_include_file
    fi

    if [ -z "$covar_colnames_continuous" ]; then
        echo "Using default continuous covariates."
        covar_colnames_continuous="sex,age_at_baseline,age_sqr,PC{1:10}"
    else
        echo "Value of covar_colnames_continuous: '$covar_colnames_continuous'"
    fi

    if [ -z "$covar_colnames_categorical" ]; then
        echo "Using default categorical covariates."
        covar_colnames_categorical="WES_batch"
    else
        echo "Value of covar_colnames_categorical: '$covar_colnames_categorical'"
    fi

    if [ -z "$step1_pred_included" ]; then
        echo "Is step 1 predictions included: false (default)"
    else
        echo "Is step 1 predictions included: $step1_pred_included"
    fi

    if [ -n "$step1_file_pred" ]; then
        echo "Downloading step 1 _pred.list file: '$step1_file_pred'"
        dx download "$step1_file_pred" -o step1_file_pred
    fi

    if [ -n "$step1_file_loco_one_pheno" ]; then
        echo "Downloading loco file for single phenotype: '$step1_file_loco_one_pheno'"
        dx download "$step1_file_loco_one_pheno"
    fi

    if [ -n "$step1_file_loco_multi_pheno" ]; then
        dx download "$step1_file_loco_multi_pheno" -o loco_files.list
        mapfile -t loco_files_array < loco_files.list
        for loco_file in "${loco_files_array[@]}"; do
            echo "Downloading loco file for multiple phenotypes: '$loco_file'"
            dx download "$loco_file"
        done
    fi

    ls -l step1_file_pred
    ls -l *.loco

    echo "Downloading QCed WES pgen files ..."
    dx download file-J0qJ9q8JPG60JqqJbxv7Yf72 -o WES_QCed_pgen_files.tar.gz
    tar -xzvf WES_QCed_pgen_files.tar.gz

    echo "Downloading all regenie mask files ..."
    dx download file-J0zB0FjJQkyy8ZV1XQ5JgZ3x -o regenie_mask_files_autosomes.tar.gz
    tar -xzvf regenie_mask_files_autosomes.tar.gz

    if [ "$step1_pred_included" = "true" ]; then
        pred_flag="--pred step1_file_pred"
    else
        pred_flag="--ignore-pred"
    fi

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

    if [ -z "$gene_list" ]; then
        echo "Start genome-wide gene-based analysis..."

        MAX_JOBS=8
        JOBS_RUNNING=0

        for chr in {1..22}; do
            (
                echo "Processing chromosome $chr"
                pgen_file_prefix="ukb23158_c${chr}_b0_v1_QCed"

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
                    --aaf-bins 0.001 \
                    --build-mask max \
                    --vc-maxAAF 0.001 \
                    --vc-tests skato \
                    --vc-MACthr 10 \
                    $binary_trait_bias_correction_method \
                    --pThresh 0.01 \
                    --bsize 200 \
                    --threads 1 \
                    --write-mask-snplist \
                    --out chr${chr}

                rm ${pgen_file_prefix}*
            ) &

            ((JOBS_RUNNING+=1))
            if (( JOBS_RUNNING >= MAX_JOBS )); then
                wait
                JOBS_RUNNING=0
            fi
        done
        wait

    else
        echo "Start gene-based analysis for the gene list provided..."

        python3 /usr/bin/parse_gene_list.py $gene_list
        chromosome_list=$(awk -F'\t' '{print $1}' parsed_gene_list.txt | paste -sd,)

        MAX_JOBS=8
        JOBS_RUNNING=0

        for chr in ${chromosome_list//,/ }; do
            (
                echo "Processing chromosome $chr"
                pgen_file_prefix="ukb23158_c${chr}_b0_v1_QCed"
                gene_list_formatted=$(awk -F'\t' -v chr="$chr" '$1 == chr {print $2}' parsed_gene_list.txt)

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
                    --aaf-bins 0.001 \
                    --build-mask max \
                    --vc-maxAAF 0.001 \
                    --vc-tests skato \
                    --vc-MACthr 10 \
                    $binary_trait_bias_correction_method \
                    --pThresh 0.01 \
                    --bsize 200 \
                    --threads 1 \
                    --write-mask-snplist \
                    --extract-setlist $gene_list_formatted \
                    --out chr${chr}

                rm ${pgen_file_prefix}*
            ) &

            ((JOBS_RUNNING+=1))
            if (( JOBS_RUNNING >= MAX_JOBS )); then
                wait
                JOBS_RUNNING=0
            fi
        done
        wait
    fi

    echo "All chromosomes completed; start combining regenie results..."

    if [ -f "/usr/bin/process_regenie_output_gene-test.py" ]; then
        python3 /usr/bin/process_regenie_output_gene-test.py $output_file_prefix $pheno_colnames
        if [ $? -ne 0 ]; then
            echo "Warning: Python script for processing results failed."
        fi
    else
        echo "Warning: Python script not found."
    fi

    echo "Results files are ready to be uploaded."

    rm chr*
    echo "Files left in the directory after cleanup:"
    ls -l

    output_regenie_file=()
    for file in *.regenie; do
        [ -e "$file" ] || continue
        file_id=$(dx upload "$file" --brief)
        output_regenie_file+=("$file_id")
    done

    for i in "${!output_regenie_file[@]}"; do
        dx-jobutil-add-output output_regenie_file "${output_regenie_file[$i]}" --class=array:file
    done

    echo "Uploaded regenie output file(s): ${output_regenie_file[@]}"

    log_file_name=$(ls *.log)
    output_regenie_log_file=$(dx upload $log_file_name --brief)
    dx-jobutil-add-output output_regenie_log_file "$output_regenie_log_file" --class=file
    echo "Uploaded regenie log file: $output_regenie_log_file"

    mask_snplist_file_name=$(ls *.snplist)
    output_mask_snplist=$(dx upload $mask_snplist_file_name --brief)
    dx-jobutil-add-output output_mask_snplist "$output_mask_snplist" --class=file
    echo "Uploaded mask.snplist file: $output_mask_snplist"
}