library(stringr)
library(data.table)

args <- commandArgs(trailingOnly = TRUE)
input_dir <- args[1]
output_dir <- args[2]

source("https://raw.githubusercontent.com/BHKLAB-Pachyderm/ICB_Common/main/code/Get_Response.R")
source("https://raw.githubusercontent.com/BHKLAB-Pachyderm/ICB_Common/main/code/format_clin_data.R")

#############################################################################
#############################################################################

expr = read.table( file.path(input_dir, "mel_puch_exp_data.csv") , sep="," , header=TRUE , stringsAsFactors = FALSE )
rownames(expr) = expr[ , 1 ]
expr = expr[ , -1 ]

fpkmToTpm <- function(fpkm)
{
    exp( log( fpkm ) - log( sum( fpkm , na.rm = TRUE ) ) + log( 1e6 ) )
}

expr = fpkmToTpm( fpkm = as.matrix( expr ) )
#############################################################################
#############################################################################
## Get Clinical data

surv = read.table( file.path(input_dir, "mel_puch_survival_data.csv") , sep="," , header=TRUE , stringsAsFactors = FALSE , dec=",")
rownames(surv) = surv[ , "X" ]

clin = read.table( file.path(input_dir, "mel_puch_clin_data.csv") , sep="," , header=TRUE , stringsAsFactors = FALSE , dec=",")
clin = clin[ clin[ , "treatment" ] %in% "pre" , ]

clin_original <- clin
selected_cols <- c("X", "response")
clin = as.data.frame( cbind( clin[ , selected_cols ] , "PD-1/PD-L1" , "Melanoma" , NA , NA , NA , NA , NA , NA , NA , NA , NA , NA , NA , NA ) )
colnames(clin) = c( "patient" , "recist" , "drug_type" , "primary" , "age" , "histo" , "response" , "pfs" ,"os" , "t.pfs" , "t.os" , "stage" , "sex" , "response.other.info" , "dna" , "rna" )

clin$patient = sapply( clin$patient , function(x){ paste( "X" , paste( unlist( strsplit( x , "-" , fixed=TRUE ) ) , collapse= "." ) , sep="" ) } )
rownames(clin) = clin$patient
clin_original$X <- paste0('X', str_replace_all(clin_original$X, '-', '.'))
rownames(clin_original) <- clin_original$X

clin$recist = ifelse( clin$recist %in% 0 , "PD" , ifelse( clin$recist %in% -1 , "SD" , ifelse( clin$recist %in% 1 , "CR" , NA ) ) )
clin$t.pfs = as.numeric( as.character( surv[ rownames(clin) , "PFS" ] ) )
clin$t.os = as.numeric( as.character( surv[ rownames(clin) , "OS" ] ) )
clin$os = as.numeric( as.character( surv[ rownames(clin) , "status" ] ) )

clin$response = Get_Response( data=clin )
clin$rna = "tpm"
clin = clin[ , c("patient" , "sex" , "age" , "primary" , "histo" , "stage" , "response.other.info" , "recist" , "response" , "drug_type" , "dna" , "rna" , "t.pfs" , "pfs" , "t.os" , "os" ) ]

clin <- format_clin_data(clin_original, 'X', selected_cols, clin)

#############################################################################
#############################################################################

patient = intersect( colnames(expr) , rownames(clin) )
clin = clin[ patient , ]
expr =  expr[ , patient ]

case = cbind( patient , 0 , 0 , 1 )
colnames(case ) = c( "patient" , "snv" , "cna" , "expr" )

write.table( case , file = file.path(output_dir, "cased_sequenced.csv") , sep = ";" , quote = FALSE , row.names = FALSE)
write.table( clin , file = file.path(output_dir, "CLIN.csv") , sep = ";" , quote = FALSE , row.names = FALSE)
write.table( expr , file= file.path(output_dir, "EXPR.csv") , quote=FALSE , sep=";" , col.names=TRUE , row.names=TRUE )
