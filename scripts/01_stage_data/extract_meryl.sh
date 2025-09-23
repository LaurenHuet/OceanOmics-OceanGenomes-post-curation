#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 /path/to/samplesheet.csv"
  exit 1
fi

samplesheet="$1"

# Skip header line
tail -n +2 "$samplesheet" | while IFS=, read -r sample hic_dir assembly meryldb agp version date genomesize; do
  meryldb="${meryldb//[$'\t\r\n ']/}"

  echo "==> ${sample}: meryldb dir: ${meryldb}"

  if [[ -z "${meryldb}" || ! -d "${meryldb}" ]]; then
    echo "    (skip) meryldb directory not found"
    continue
  fi

  shopt -s nullglob
  for arc in "$meryldb"/*meryl*.tar.gz; do
    [[ -e "$arc" ]] || continue
    echo "    Extracting: $(basename "$arc")"

    # base name without .tar.gz
    base=$(basename "$arc" .tar.gz)

    # normalise "meryldb" → "meryl" in the extracted dir name
    normbase="${base/meryldb/meryl}"

    target="$meryldb/$normbase"
    mkdir -p "$target"

    tar -xzf "$arc" -C "$target" --strip-components=1

    echo "    Created: $target"
  done
  shopt -u nullglob
done
