<!--
    title: "Running analysis with UKB WES 470k"
    description: "This is an introduction to how to run per-variant and per-gene association tests using WES 470K data on UKBB RAP."
-->

<h2>Introduction</h2>
<p>
    This document provides a practical guide on running per-variant (ExWAS) and per-gene (gene-collapsing) association tests using UKB WES 470K data on the UKBB RAP for IC internal users.<br><br>
    <strong>Prerequisites:</strong> Users should be familiar with using the UKB RAP via the command line interface (CLI).
</p>
<ul>
    <li><a href="https://dnanexus.gitbook.io/uk-biobank-rap/working-on-the-research-analysis-platform/running-analysis">Tutorials for working on UKB RAP via CLI</a></li>
    <li><a href="https://documentation.dnanexus.com/downloads">Tutorial for installing dxtoolkit (required for accessing CLI)</a></li>
</ul>

<h2>Method Overview</h2>
<p>
    Three customised tools on RAP are available for IC internal users with access to <code>project-GyZxPF8JQkyq9JVxZjQ2FvqK</code> to run variant-level or gene-level association tests using WES 470K data.
    For association test, we use <a href="https://rgcgithub.github.io/regenie/">regenie</a>.<br><br>
    This guide provides step-by-step instructions for different analysis scenarios.<br>
    To view detailed documentation for each tool, run the following commands in your command-line interface:<br><br>
</p>
<pre><code>
dx run app-ic-epid-regenie-step1 --help                         # The app for running regenie step 1
dx run app-ic-epid-regenie-step2_per-gene-test --help           # The app for running regenie step 2, gene level association test 
dx run app-ic-epid-regenie-step2_per-variant-test --help        # The app for running regenie step 2, variant level association test 
</code></pre>

<p>
    <strong>Required Input:</strong> Users must prepare a tab-delimited phenotype file as the minimum requirement to run all three tools.<br><br>
    <ul>
        <li>The phenotype file must contain either all binary traits or all quantitative traits, as regenie cannot process mixed phenotype types in a single run.</li>
        <li>While the tools can theoretically handle multiple phenotypes, current configurations have only been tested with up to 3 phenotypes. Including more may lead to resource allocation issues.</li>
    </ul>
</p>
<p>
    Below is an example of the expected phenotype file format. The first two columns are FID and IID, which are required for regenie to identify individuals in the genotype data. The third column is the first phenotype, and the fourth and fifth columns are additional phenotypes.
</p>
<pre><code>
FID    IID    PHENO1    PHENO2    PHENO3
1      1      1         0         0
1      2      1         1         1
1      3      0         0         0
</code></pre>

<p>
    Regenie's first step builds a whole-genome regression model that is computationally intensive. For initial exploratory analyses, this step can be skipped. However, for final results, predictions from step 1 should be included to adjust for population stratification and cryptic relatedness in the association tests.<br><br>
    For details about other optional input files and their required formats, please run: <code>dx run app-name --help</code><br><br>
    The following sub-sections provide example codes of how to run the apps for different analysis scenarios:
</p>
<ol>
    <li>Quickly screen for gene-phenotype associations for a short list of genes: <strong>quick gene screening</strong></li>
    <li>Run genome-wide gene-phenotype association test without step 1 for quick results: <strong>quick genome-wide gene-based test</strong></li>
    <li>Run a genome-wide gene-based test with step 1 predictions for final results: <strong>gene-based association test including step1</strong></li>
    <li>Run a genome-wide variant association test (ExWAS) with step 1 predictions for final results: <strong>variant level association test including step1</strong></li></li>
</ol>

<p>
    For further details about genotype data processing and methods, refer to the Common Q&amp;A section.
</p>
