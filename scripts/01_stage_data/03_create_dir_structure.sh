# Preview actions first
# python structure_data.py \
#   --samplesheet ../0_create_samplesheet/samplesheet.csv \
#   --source /scratch/pawsey0964/$USER/post_curation/ \
#   --dry-run

# If it looks right, run for real (move files)
python structure_data.py \
  --samplesheet ../0_create_samplesheet/samplesheet.csv \
  --source /scratch/pawsey0964/$USER/post_curation/ \

