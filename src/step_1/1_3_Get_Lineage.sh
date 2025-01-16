#!/bin/bash

conda activate ncbi_datasets

My_fucn(){
	#while read line; do
	name=$(echo $1 | sed 's/ /_/g');
	datasets download taxonomy taxon $1 --filename Lineage.${1}.zip;
}

export -f My_fucn

parallel -j 36 My_fucn ::: $(cat 1_Metadata_DB_filtered.txt | cut -f3 | sort -u);

# Extract taxonomy file by from compressed ncbi data object
for f in *.zip;
        do unzip "ncbi_dataset/data/taxonomy_summary.tsv"  >  "${f%.zip}.txt";
done
#cat list_species.txt | parallel -j 10 --line-buffer My_fucn {} ; 
