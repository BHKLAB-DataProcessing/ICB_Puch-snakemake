from snakemake.remote.S3 import RemoteProvider as S3RemoteProvider
S3 = S3RemoteProvider(
    access_key_id=config["key"], 
    secret_access_key=config["secret"],
    host=config["host"],
    stay_on_remote=False
)
prefix = config["prefix"]
filename = config["filename"]
data_source  = "https://raw.githubusercontent.com/xmuyulab/ims_gene_signature/main/data/"

rule get_MultiAssayExp:
    input:
        S3.remote(prefix + "processed/cased_sequenced.csv"),
        S3.remote(prefix + "processed/CLIN.csv"),
        S3.remote(prefix + "processed/EXPR.csv"),
        S3.remote(prefix + "annotation/Gencode.v19.annotation.RData")
    output:
        S3.remote(prefix + filename)
    resources:
        mem_mb=3000
    shell:
        """
        Rscript -e \
        '
        load(paste0("{prefix}", "annotation/Gencode.v19.annotation.RData"))
        source("https://raw.githubusercontent.com/BHKLAB-Pachyderm/ICB_Common/main/code/get_MultiAssayExp.R");
        saveRDS(
            get_MultiAssayExp(study = "Puch", input_dir = paste0("{prefix}", "processed")), 
            "{prefix}{filename}"
        );
        '
        """

rule download_annotation:
    output:
        S3.remote(prefix + "annotation/Gencode.v19.annotation.RData"),
        S3.remote(prefix + "annotation/curation_drug.csv"),
        S3.remote(prefix + "annotation/curation_tissue.csv")
    shell:
        """
        wget https://github.com/BHKLAB-Pachyderm/Annotations/blob/master/Gencode.v19.annotation.RData?raw=true -O {prefix}annotation/Gencode.v19.annotation.RData
        wget https://github.com/BHKLAB-Pachyderm/ICB_Common/raw/main/data/curation_drug.csv -O {prefix}annotation/curation_drug.csv
        wget https://github.com/BHKLAB-Pachyderm/ICB_Common/raw/main/data/curation_tissue.csv -O {prefix}annotation/curation_tissue.csv 
        """

rule format_data:
    input:
        S3.remote(prefix + "download/mel_puch_exp_data.csv"),
        S3.remote(prefix + "download/mel_puch_survival_data.csv"),
        S3.remote(prefix + "download/mel_puch_clin_data.csv"),
        S3.remote(prefix + "annotation/curation_drug.csv"),
        S3.remote(prefix + "annotation/curation_tissue.csv")
    output:
        S3.remote(prefix + "processed/cased_sequenced.csv"),
        S3.remote(prefix + "processed/CLIN.csv"),
        S3.remote(prefix + "processed/EXPR.csv")
    resources:
        mem_mb=1000
    shell:
        """
        Rscript scripts/Format_Data.R \
        {prefix}download \
        {prefix}processed \
        {prefix}annotation
        """

rule download_data:
    output:
        S3.remote(prefix + "download/mel_puch_exp_data.csv"),
        S3.remote(prefix + "download/mel_puch_survival_data.csv"),
        S3.remote(prefix + "download/mel_puch_clin_data.csv")
    resources:
        mem_mb=1000
    shell:
        """
        wget {data_source}mel_puch_exp_data.csv -O {prefix}download/mel_puch_exp_data.csv
        wget {data_source}mel_puch_survival_data.csv -O {prefix}download/mel_puch_survival_data.csv
        wget {data_source}mel_puch_cli_data.csv -O {prefix}download/mel_puch_clin_data.csv
        """ 