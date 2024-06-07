#!/bin/bash

conda activate ncbi_datasets

My_fucn(){
	#while read line; do

	name=$(echo $1 | sed 's/ /_/g');

	datasets download genome accession $1 --reference --assembly-version 'latest' \
										--assembly-level "chromosome,complete,contig" \
										--include "genome,gff3,gtf,cds,protein" \
										--filename  ${name}.zip
									
}

export -f My_fucn

# $1: 1_Metadata_DB_unfiltered.txt
parallel -j 72 My_fucn ::: $(cat $1 | cut -f1 | sort -u);
