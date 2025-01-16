#!/bin/bash
########## SLURM Job Scheduler Settings ##########
#SBATCH --time=2:00:00           # Maximum run time (HH:MM:SS)
#SBATCH --nodes=1                # Number of nodes
#SBATCH --ntasks=1               # Number of tasks
#SBATCH --cpus-per-task=1        # Number of CPUs per task
#SBATCH --mem=10G                # Memory per node
#SBATCH --job-name=MakeBlastDB   # Job name
#SBATCH --array=0-22             # Array range for 1137 genomes with chunks of 50

# Load Conda Environment
source ~/home_turbo/fabio_home/LocalInstall/miniconda3/etc/profile.d/conda.sh
conda activate phylo

# Input Metadata File
METADATA_FILE="1_Metadata_paths.txt"

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

# Function to process a single sample
process_sample() {
    local name="$1"
    
    # Extract metadata for the current sample
    META=$(grep -w "$name" "$METADATA_FILE")

    if [ -z "$META" ]; then
        echo "Error: Metadata not found for sample $name"
        return 1
    fi

    # Parse metadata fields
  
    GenomeID=$(echo "$META" | cut -f1)
    GenomeName=$(echo "$META" | cut -f2 | sed 's/ /@/g')
    GenomeTAXON=$(echo "$META" | cut -f3)
    GenomePATH="GenomesDB_/"$(echo "$META" | cut -f4)

    if [ ! -f "$GenomePATH" ]; then
        echo "Error: Genome file not found at $GenomePATH"
        return 1
    fi

    # Create the BLAST database
  
    makeblastdb -in "$GenomePATH" \
        -dbtype 'nucl' \
        -out "BlastDBs/blastdb_${GenomeID}_${GenomeTAXON}" \
        -title "${GenomeID}_${GenomeName}_${GenomeTAXON}"

    echo "BLAST database created for $GenomeName ($GenomeID)"
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
