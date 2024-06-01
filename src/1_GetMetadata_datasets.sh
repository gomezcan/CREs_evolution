#!/bin/bash

# Uses datasets to crate raw metadata for all the genome assemblies available for the corresponding species list. 
## list_species.txt example: head -3 list_species.txt
#  Neopyropia yezoensis
#  Thalassiosira pseudonana
#  Guillardia theta

conda activate ncbi_datasets

My_fucn(){
	name=$(echo $1 | sed 's/ /_/g');
 datasets summary genome taxon "$1" --reference --as-json-lines | \
 dataformat tsv genome --fields accession,assminfo-name,annotinfo-name,annotinfo-release-date,organism-name,organism-tax-id,annotinfo-status > Meta_$name;	
}

export -f My_fucn

parallel -j 10 My_fucn ::: $(cat list_species.txt | cut -d' ' -f1 | sort -u);
