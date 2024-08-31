#!/bin/bash
echo
echo
# Define colors for output
color_cyan="\033[0;36m"  # Cyan color for files
color_lyellow_bold="\033[1;33m"  # Light yellow and bold for directories
color_reset="\033[0m"    # Reset color to default

# Construct the directory structure
tree_structure=$(cat <<EOF
FOLLOWING FOLDER STRUCTURE NEED TO BE MAINTAINED
_____________________________________________________
${color_lyellow_bold}Deliverables/${color_reset}
${color_lyellow_bold}|-- bams${color_reset}
${color_cyan}|   |-- ABLG11582-1.bam${color_reset}
${color_cyan}|   |-- ABLG11582-1.bam.bai${color_reset}
${color_cyan}|   |-- ABLG11629-1.bam${color_reset}
${color_cyan}|   |-- ABLG11629-1.bam.bai${color_reset}
${color_cyan}|   |-- ABLG11912-1.bam${color_reset}
${color_cyan}|   |-- ABLG11912-1.bam.bai${color_reset}
${color_cyan}|   |-- ABLG11913-1.bam${color_reset}
${color_cyan}|   |-- ABLG11913-1.bam.bai${color_reset}
${color_cyan}|   |-- ABLG11918-1.bam${color_reset}
${color_cyan}|   |-- ABLG11918-1.bam.bai${color_reset}
${color_cyan}|   |-- ABLG11920-1.bam${color_reset}
${color_cyan}|   |-- ABLG11920-1.bam.bai${color_reset}
${color_cyan}|   |-- ABLG11944-1.bam${color_reset}
${color_cyan}|   |-- ABLG11944-1.bam.bai${color_reset}
${color_cyan}|   |-- ABLG12067-1.bam${color_reset}
${color_cyan}|   \`-- ABLG12067-1.bam.bai${color_reset}
${color_lyellow_bold}|-- config${color_reset}
${color_cyan}|   \`-- config.yaml${color_reset}
${color_lyellow_bold}|-- docs${color_reset}
${color_cyan}|   |-- chr_table.tsv${color_reset}
${color_cyan}|   \`-- sample_table.tsv${color_reset}
${color_lyellow_bold}\`-- reference${color_reset}
${color_cyan}    |-- toy_refgen.fa${color_reset}
${color_cyan}    \`-- toy_refgen.fa.fai${color_reset}
______________________________________________________

NOTE
1. The BAM files must be indexed
2. The reference genome need to be indexed
3. The config folder and samples.tsv will will be created
4. Path for samples.tsv, basefolder and genome fasta must be updated in the config.yaml file

EOF
)

# Print the tree structure
echo -e "$tree_structure"
echo
echo
###########################################################################################

echo -n "Enter the Deliverables with sub-folders containing bams docs and reference: "
read DeliverablesDIR

echo
echo

ConfigDIR=${DeliverablesDIR}/config
mkdir -p ${ConfigDIR}


BAM_DIR=${DeliverablesDIR}/bams
if [ ! -d "$BAM_DIR" ]; then
    echo "Error: Directory '$BAM_DIR' not found. Please create the bams directory and place indexed bam and bai files in it"
    exit 1
fi

found = false
    if ls "$BAM_DIR"/*.bai &> /dev/null; then
        found=true
        break
    fi

# Check the presence of indexed bam and exit with appropriate message
if [ "$found" = true ]; then
    echo "File check passed. indexed bam files found."
else
    echo "Error: indexed bam files not found in the Deliverables/bams folder."
    exit 1
fi


####################################################################
#      CHECK reference folder for reference                                       #
####################################################################

REF_FOLDER_PATH=${DeliverablesDIR}/reference

# List of allowed extensions
EXTENSIONS=("fna.gz" "fna" "fa" "fasta" "fasta.gz")

# Check if the folder exists
if [ ! -d "$REF_FOLDER_PATH" ]; then
    echo "Error: The folder '$REF_FOLDER_PATH' does not exist."
    exit 1
fi

# Flag to indicate if any file with the required extension is found
found=false

# Iterate over each allowed extension
for ext in "${EXTENSIONS[@]}"; do
    # Check if files with the current extension exist in the folder
    if ls "$REF_FOLDER_PATH"/*."$ext" &> /dev/null; then
        found=true
        break
    fi
done

# Check the result and exit with appropriate message
if [ "$found" = true ]; then
    echo "Reference genome found."
else
    echo "Error: Reference genome not found with extensions [.fna.gz, .fna, .fa, .fasta, or .fasta.gz] in the Deliverables/reference folder."
    exit 1
fi

##########################################################################################
# Get the Genome Name                                                                    #
##########################################################################################
# Loop through each file in the directory
for refFilePath in ${REF_FOLDER_PATH}/*; do
    # Check if the file has a matching extension
    if [[ ${refFilePath} =~ \.(fna|fna.gz|fa|fa.gz|fasta|fasta.gz)$ ]]; then
        # Get the base name without the extension(s)
        refGenome=$(basename ${refFilePath} | sed -E 's/\.(fna|fna.gz|fa|fa.gz|fasta|fasta.gz)$//')
        refGenomeFile=$(basename ${refFilePath})
        # Output the base name
        echo "Genome Name: " $refGenome
        refPath="Deliverable/reference"/${refGenomeFile}
        echo "Genome File relative path: $refPath"
        echo "Genome File absolute path: $refFilePath"
    fi
done


########################################################################################
# Check chr_table.tsv in docs folder                                                   #     
########################################################################################

file_path="REF_FOLDER_PATH=${DeliverablesDIR}/docs/chr_table.tsv"

# Check if the file exists
if [ -f "$file_path" ]; then
    echo "File found: $file_path"
else
    echo "Error: chr_table.tsv not found in the ${DeliverablesDIR}/docs/ folder."
fi


########################################################################################
# genertion of sample_sheet TSV file                                                   #       
########################################################################################

echo "sample_name,bam,species,population" > ${DeliverablesDIR}/docs/sample_table.csv

for i in `ls ${BAM_DIR} | grep -v .bai`;do 
sample_name=`basaname $i .bam`

bam_path=${BAM_DIR}/${sample_name}.bam
echo "${sample_name},${bam_path} >> ${DeliverablesDIR}/docs/sample_table.csv
done

echo "sample_table path: ${DeliverablesDIR}/docs/sample_table.csv"
echo "sample table in csv format and contains the sample_name and bam file path"
echo "please add species and population information and convert the csv to TSV"
echo
echo "NOTE: the column hearder corresponding to species must be updated at config.yaml" 
########################################################################################
#Getting Config File                                                                   #
########################################################################################

cd ${ConfigDIR}
wget https://raw.githubusercontent.com/sarangian/locopipe/master/config.yaml

echo 

echo "${ConfigDIR}/config.yaml need to be modified"
echo "global: "
echo "basedir: ${DeliverablesDIR}"
echo
echo "reference: ${$refFilePath}
echo 
echo "pop_level: species"
echo

echo"Test Command"
echo
echo "singularity exec /storage/colddata/basesolve/tools/locopipe-v01.sif  snakemake --snakefile /opt/locopipe/workflow/pipelines/loco-pipe.smk --directory ${DeliverablesDIR} --rerun-triggers mtime --scheduler greedy --printshellcmds --cores 8"
