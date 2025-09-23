# Path to your samples file (YOUR OG NUMBERS)
OGnum="OG.txt"
 
# Generate the include filter arguments
include_meryl=$(awk '{print "--include " $0 "*meryl*.tar.gz*"}' "$OGnum" | xargs)

include_assembly=$(awk '{print "--include " $0 "*.hap1.hap2_combined_scaffolds.fa*"}' "$OGnum" | xargs)
 
# Set your S3 bucket path
s3_bucket="pawsey0964:oceanomics-refassemblies"

> to_download.txt

# Run rclone with the include filters
rclone ls $s3_bucket $include_meryl >> to_download.txt
rclone ls $s3_bucket $include_assembly >> to_download.txt
 
 
#second, make a loop that inserts the path into rclone to copy them onto your scratch using the file
for line in $(awk '{print $2}' to_download.txt); do
rclone copy $s3_bucket/${line}  /scratch/pawsey0964/$USER/post_curation
done

