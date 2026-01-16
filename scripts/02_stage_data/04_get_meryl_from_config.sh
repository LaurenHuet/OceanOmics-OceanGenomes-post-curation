#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail

# Usage:
#   bash 04_get_meryl_from_config.sh ../postcuration_pipeline.conf

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

MERYL_BUCKET="${MERYL_BUCKET:?Missing MERYL_BUCKET in config}"

# Optional matching knobs (default like your config)
MERYL_REQUIRED_SUBSTR_1="${MERYL_REQUIRED_SUBSTR_1:-meryl}"
MERYL_REQUIRED_SUBSTR_2="${MERYL_REQUIRED_SUBSTR_2:-tar.gz}"

tmp="$(mktemp)"
trap 'rm -f "$tmp" "${tmp}.matched" 2>/dev/null || true' EXIT

declare -A MERYL_DIR
samples=()

# map sample -> meryldb dir (col1 -> col4)
while IFS=$'\t' read -r s dir; do
  s="$(clean "$s")"
  dir="$(clean "$dir")"
  [[ -z "$s" ]] && continue
  MERYL_DIR["$s"]="$(expand_user "$dir")"
  samples+=("$s")
done < <(awk -F, 'NR>1{ gsub(/\r/,"",$1); gsub(/\r/,"",$4); print $1 "\t" $4 }' "$SAMPLESHEET")

[[ ${#samples[@]} -gt 0 ]] || { echo "No samples found in $SAMPLESHEET" >&2; exit 1; }

for s in "${samples[@]}"; do
  base="${MERYL_DIR[$s]:-}"
  [[ -n "$base" ]] || { echo "Error: no meryldb entry for ${s} in samplesheet" >&2; exit 1; }

  # We will untar into: <base>/meryldb
  outdir="${base%/}"
  mkdir -p "$outdir"

  # list remote paths under sample
  rclone lsf --recursive ${RCLONE_FLAGS:+$RCLONE_FLAGS} "${MERYL_BUCKET}/${s}" > "$tmp" 2>/dev/null || true

  # filter for meryl tarballs
  grep -i "$MERYL_REQUIRED_SUBSTR_1" "$tmp" | \
    grep -i "$MERYL_REQUIRED_SUBSTR_2" > "${tmp}.matched" || true

  if [[ ! -s "${tmp}.matched" ]]; then
    echo "Error: no matching MERYL tarball found for ${s} on remote ${MERYL_BUCKET}/${s}" >&2
    exit 1
  fi

  while IFS= read -r relpath; do
    relpath="$(clean "$relpath")"
    [[ -z "$relpath" ]] && continue

    fname="$(basename "$relpath")"
    local_tar="${outdir%/}/${fname}"

    echo "Downloading ${MERYL_BUCKET}/${s}/${relpath} -> ${local_tar}"
    rclone copy ${RCLONE_FLAGS:+$RCLONE_FLAGS} "${MERYL_BUCKET}/${s}/${relpath}" "${outdir}/"

    echo "Extracting ${local_tar} -> ${outdir}/"
    tar -xzf "${local_tar}" -C "${outdir}"

    # Optional: delete tarball after extraction to save space
    rm -f "${local_tar}"
  done < "${tmp}.matched"
done

echo "Done."
