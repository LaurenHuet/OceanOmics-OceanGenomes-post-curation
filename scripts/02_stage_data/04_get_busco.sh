#!/usr/bin/env bash
set -euo pipefail

SAMPLESHEET="/scratch/pawsey0964/lhuet/PIPELINE_DEV/GEOMENOTES/OceanOmics-OceanGenomes-genomenotes/assets/samplesheet.csv"
s3_bucket="pawsey0964:oceanomics-refassemblies"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

[[ -f "$SAMPLESHEET" ]] || { echo "Samplesheet not found: $SAMPLESHEET" >&2; exit 1; }

declare -A BUSCO_DIR
samples=()

# populate mapping sample -> busco_genes (col1 -> col5)
while IFS=$'\t' read -r s dir; do
  s="$(printf '%s' "$s" | tr -d '\r' | tr -cd '[:print:]' | xargs)"
  dir="$(printf '%s' "$dir" | tr -d '\r' | xargs)"
  [[ -z "$s" ]] && continue
  BUSCO_DIR["$s"]="$dir"
  samples+=("$s")
done < <(awk -F, 'NR>1{ gsub(/\r/,"",$1); gsub(/\r/,"",$5); print $1 "\t" $5 }' "$SAMPLESHEET")

[[ ${#samples[@]} -gt 0 ]] || { echo "No samples found in $SAMPLESHEET" >&2; exit 1; }

# For each sample, list remote files under the sample dir and pick the busco full_table for hap1 chr-level assemblies
for s in "${samples[@]}"; do
  target="${BUSCO_DIR[$s]:-}"
  if [[ -z "$target" ]]; then
    echo "Error: no busco_genes entry for ${s} in samplesheet" >&2
    exit 1
  fi

  mkdir -p "$target"

  # list files under the sample directory on remote, filter for busco + hap1.chr_level + full_table.tsv
  rclone lsf --recursive "${s3_bucket}/${s}" > "$tmp" 2>/dev/null || true
  grep -i 'busco' "$tmp" | grep -i 'hap1.chr_level' | grep -i 'full_table.tsv' > "${tmp}.matched" || true

  if [[ ! -s "${tmp}.matched" ]]; then
    echo "Error: no matching busco full_table found for ${s} on remote ${s3_bucket}/${s}" >&2
    exit 1
  fi

  while IFS= read -r relpath; do
    # rclone copy expects the full remote path; relpath is relative to ${s}
    echo "Copying ${s3_bucket}/${s}/${relpath} -> ${target}/"
    rclone copy "${s3_bucket}/${s}/${relpath}" "${target}/"
  done < "${tmp}.matched"

  rm -f "${tmp}.matched"
done

echo "Done."
