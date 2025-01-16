#!/bin/bash
#SBATCH --time=3:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=10G
#SBATCH --job-name=BlastSearch
#SBATCH --array=0-22

# Load Conda Environment
source ~/home_turbo/fabio_home/LocalInstall/miniconda3/etc/profile.d/conda.sh
conda activate phylo

# Input Metadata File
METADATA_FILE="2_DBs_paths.txt"
Angiosperms353="Angiosperms353_targetSequences.fasta"

# Define chunk size
CHUNK_SIZE=50

# Calculate the range of samples for this task
START_INDEX=$((SLURM_ARRAY_TASK_ID * CHUNK_SIZE))
END_INDEX=$((START_INDEX + CHUNK_SIZE - 1))

# Read all samples into an array
readarray -t SAMPLES < <(cut -f1 "$METADATA_FILE" | sort -u)

# Ensure the end index does not exceed the array length
TOTAL_SAMPLES=${#SAMPLES[@]}
if [ "$END_INDEX" -ge "$TOTAL_SAMPLES" ]; then
    END_INDEX=$((TOTAL_SAMPLES - 1))
fi

# Ensure output directory exists
mkdir -p BlastResults

# Function to process a single sample
process_sample() {
    local DB="$1"
    local GenomeTarget="BlastDBs/$DB"
    local results="BlastResults/Result_${DB}.tsv"

    # Check for BLAST database files
    if [ ! -f "${GenomeTarget}.nin" ] || [ ! -f "${GenomeTarget}.nsq" ] || [ ! -f "${GenomeTarget}.nhr" ]; then
        echo "Error: BLAST database for $GenomeTarget is incomplete or missing."
        return 1
    fi

    # Run BLASTn
    blastn -query "$Angiosperms353" \
           -db "$GenomeTarget" \
           -out "$results" \
           -perc_identity 0.7 \
           -evalue 1e-5 \
           -outfmt "6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore"

    echo "BLASTn for $DB done"
}

# Process each sample in the range
for ((i=START_INDEX; i<=END_INDEX; i++)); do
    name="${SAMPLES[$i]}"
    if [ -z "$name" ]; then
        echo "Error: No sample found for index $i"
        continue
    fi
    echo "Processing sample: $name"
    process_sample "$name"
done
