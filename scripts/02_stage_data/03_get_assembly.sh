#!/usr/bin/env bash
set -euo pipefail

SAMPLESHEET="/scratch/pawsey0964/lhuet/genomenotes/OceanOmics-OceanGenomes-genomenotes/assets/samplesheet.csv"
s3_bucket="pawsey0964:oceanomics-refassemblies"
tmp_list="$(mktemp)"
trap 'rm -f "$tmp_list"' EXIT

[[ -f "$SAMPLESHEET" ]] || { echo "Samplesheet not found: $SAMPLESHEET" >&2; exit 1; }

declare -A ASSEMBLY_DIR
samples=()

# map sample -> assembly dir (col 1, col 4)
while IFS=$'\t' read -r sample assembly_dir; do
  sample="$(printf '%s' "$sample" | tr -d '\r' | tr -cd '[:print:]' | xargs)"
  assembly_dir="$(printf '%s' "$assembly_dir" | tr -d '\r' | xargs)"
  [[ -z "$sample" ]] && continue
  ASSEMBLY_DIR["$sample"]="$assembly_dir"
  samples+=("$sample")
done < <(awk -F, 'NR>1 { gsub(/\r/,"",$1); gsub(/\r/,"",$4); print $1 "\t" $4 }' "$SAMPLESHEET")

[[ ${#samples[@]} -gt 0 ]] || { echo "No samples found in $SAMPLESHEET" >&2; exit 1; }

# include filters for curated assembly files
include=()
for s in "${samples[@]}"; do include+=( --include "${s}*curated.hap1.chr_level.fa*" ); done

rclone ls "$s3_bucket" "${include[@]}" > "$tmp_list"

while IFS= read -r line || [[ -n "$line" ]]; do
  path="$(printf '%s' "$line" | sed -E 's/^[[:space:]]*[0-9]+[[:space:]]+//; s/\r$//')"
  og="$(printf '%s' "$path" | grep -o -m1 -E 'OG[0-9]+' || true)"

  target=""
  if [[ -n "$og" && -n "${ASSEMBLY_DIR[$og]:-}" ]]; then
    target="${ASSEMBLY_DIR[$og]}"
  else
    for s in "${samples[@]}"; do
      if [[ "$path" == *"$s"* ]]; then
        target="${ASSEMBLY_DIR[$s]}"
        og="$s"
        break
      fi
    done
  fi

  if [[ -z "$target" ]]; then
    user="${USER:-$(whoami)}"
    target="/scratch/pawsey0964/${user}/post_curation/${og:-unknown}"
    echo "Warning: no assembly dir for remote path; falling back to ${target}" >&2
  fi

  mkdir -p "$target"
  rclone copy "${s3_bucket}/${path}" "${target}/"
done < "$tmp_list"

echo "Done."
```// filepath: /scratch/pawsey0964/lhuet/genomenotes/OceanOmics-OceanGenomes-genomenotes/scripts/02_stage_data/03_get_assembly.sh
#!/usr/bin/env bash
set -euo pipefail

SAMPLESHEET="/scratch/pawsey0964/lhuet/genomenotes/OceanOmics-OceanGenomes-genomenotes/assets/samplesheet.csv"
s3_bucket="pawsey0964:oceanomics-refassemblies"
tmp_list="$(mktemp)"
trap 'rm -f "$tmp_list"' EXIT

[[ -f "$SAMPLESHEET" ]] || { echo "Samplesheet not found: $SAMPLESHEET" >&2; exit 1; }

declare -A ASSEMBLY_DIR
samples=()

# map sample -> assembly dir (col 1, col 4)
while IFS=$'\t' read -r sample assembly_dir; do
  sample="$(printf '%s' "$sample" | tr -d '\r' | tr -cd '[:print:]' | xargs)"
  assembly_dir="$(printf '%s' "$assembly_dir" | tr -d '\r' | xargs)"
  [[ -z "$sample" ]] && continue
  ASSEMBLY_DIR["$sample"]="$assembly_dir"
  samples+=("$sample")
done < <(awk -F, 'NR>1 { gsub(/\r/,"",$1); gsub(/\r/,"",$4); print $1 "\t" $4 }' "$SAMPLESHEET")

[[ ${#samples[@]} -gt 0 ]] || { echo "No samples found in $SAMPLESHEET" >&2; exit 1; }

# include filters for curated assembly files
include=()
for s in "${samples[@]}"; do include+=( --include "${s}*curated.hap1.chr_level.fa*" ); done

rclone ls "$s3_bucket" "${include[@]}" > "$tmp_list"

while IFS= read -r line || [[ -n "$line" ]]; do
  path="$(printf '%s' "$line" | sed -E 's/^[[:space:]]*[0-9]+[[:space:]]+//; s/\r$//')"
  og="$(printf '%s' "$path" | grep -o -m1 -E 'OG[0-9]+' || true)"

  target=""
  if [[ -n "$og" && -n "${ASSEMBLY_DIR[$og]:-}" ]]; then
    target="${ASSEMBLY_DIR[$og]}"
  else
    for s in "${samples[@]}"; do
      if [[ "$path" == *"$s"* ]]; then
        target="${ASSEMBLY_DIR[$s]}"
        og="$s"
        break
      fi
    done
  fi

  if [[ -z "$target" ]]; then
    user="${USER:-$(whoami)}"
    target="/scratch/pawsey0964/${user}/post_curation/${og:-unknown}"
    echo "Warning: no assembly dir for remote path; falling back to ${target}" >&2
  fi

  mkdir -p "$target"
  rclone copy "${s3_bucket}/${path}" "${target}/"
done < "$tmp_list"

echo "Done."