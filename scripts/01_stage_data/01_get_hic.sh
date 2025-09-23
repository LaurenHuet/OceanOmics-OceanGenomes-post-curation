# Path to your samples file (YOUR OG NUMBERS)
OGnum="OG.txt"
 
# Generate the include filter arguments
include_filters=$(awk '{print "--include " $0 "*HIC*"}' "$OGnum" | xargs)
 
# Set your S3 bucket path
s3_bucket="s3:oceanomics/OceanGenomes/illumina-hic"

# Run rclone with the include filters
rclone ls $s3_bucket $include_filters > to_download-hic.txt
 
 
#second, make a loop that inserts the path into rclone to copy them onto your scratch using the file
for line in $(awk '{print $2}' to_download-hic.txt); do
rclone copy $s3_bucket/${line}  /scratch/pawsey0964/lhuet/post_curation
done

