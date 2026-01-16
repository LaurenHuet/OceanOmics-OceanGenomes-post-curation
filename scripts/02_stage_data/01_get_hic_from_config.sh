#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail

## USEGAE bash 01_get_hic_from_config.sh ../postcuration_pipeline.conf

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <config.conf>" >&2
  exit 1
fi

CONFIG_FILE="$1"
[[ -f "$CONFIG_FILE" ]] || { echo "Config not found: $CONFIG_FILE" >&2; exit 1; }

# Load config (bash-compatible KEY=VALUE)
set -a
# shellcheck disable=SC1090
source "$CONFIG_FILE"
set +a

# expand {user} placeholders in paths
USER_REAL="${USER:-$(whoami)}"
expand_user() { printf '%s' "${1//\{user\}/$USER_REAL}"; }

SAMPLESHEET="$(expand_user "${SAMPLESHEET}")"
RCLONE_FLAGS="${RCLONE_FLAGS:-}"

[[ -f "$SAMPLESHEET" ]] || { echo "Samplesheet not found: $SAMPLESHEET" >&2; exit 1; }

# Helper: trim CR/LF and leading/trailing whitespace
clean() { printf '%s' "$1" | tr -d '\r' | xargs; }


HIC_BUCKET="${HIC_BUCKET:?Missing HIC_BUCKET in config}"
tmp_list="$(mktemp)"
trap 'rm -f "$tmp_list"' EXIT

declare -A HIC_DIR_MAP
samples=()

# build map: sample -> hic_dir (col1 -> col2)
while IFS=$'\t' read -r sample hic_dir; do
  sample="$(clean "$sample")"
  hic_dir="$(clean "$hic_dir")"
  [[ -z "$sample" ]] && continue
  HIC_DIR_MAP["$sample"]="$(expand_user "$hic_dir")"
  samples+=("$sample")
done < <(awk -F, 'NR>1 { gsub(/\r/,"",$1); gsub(/\r/,"",$2); print $1 "\t" $2 }' "$SAMPLESHEET")

[[ ${#samples[@]} -gt 0 ]] || { echo "No samples found in $SAMPLESHEET" >&2; exit 1; }

include=()
for s in "${samples[@]}"; do include+=( --include "${s}*" ); done
rclone ls "$HIC_BUCKET" ${RCLONE_FLAGS:+$RCLONE_FLAGS} "${include[@]}" > "$tmp_list"

while IFS= read -r line || [[ -n "$line" ]]; do
  path="$(printf '%s' "$line" | sed -E 's/^[[:space:]]*[0-9]+[[:space:]]+//; s/\r$//')"
  og="$(printf '%s' "$path" | grep -o -m1 -E 'OG[0-9]+' || true)"

  target=""
  if [[ -n "$og" && -n "${HIC_DIR_MAP[$og]:-}" ]]; then
    target="${HIC_DIR_MAP[$og]}"
  else
    for s in "${samples[@]}"; do
      if [[ "$path" == *"$s"* ]]; then
        target="${HIC_DIR_MAP[$s]}"
        og="$s"
        break
      fi
    done
  fi

  if [[ -z "$target" ]]; then
    target="/scratch/pawsey0964/${USER_REAL}/post_curation/${og:-unknown}/hic"
    echo "Warning: no hic_dir for remote path; falling back to ${target}" >&2
  fi

  mkdir -p "$target"
  echo "Copying ${HIC_BUCKET}/${path} -> ${target}/"
  rclone copy ${RCLONE_FLAGS:+$RCLONE_FLAGS} "${HIC_BUCKET}/${path}" "${target}/"
done < "$tmp_list"

echo "Done."
