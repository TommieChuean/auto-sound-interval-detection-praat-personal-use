#!/bin/zsh
set -eu

script_dir="${0:A:h}"
praat_bin="/Applications/Praat.app/Contents/MacOS/Praat"

if [[ $# -lt 1 || $# -gt 3 ]]; then
  echo "Usage: $0 <audio-file-or-folder> [output-csv] [file-glob]" >&2
  exit 1
fi

input_path="$1"
output_csv="${2:-test3_results.csv}"
file_glob="${3:-*.wav}"

exec "$praat_bin" --run "$script_dir/detect_intervals.praat" \
  "$input_path" \
  "$file_glob" \
  "$output_csv" \
  0.001 \
  0.45 \
  0.08 \
  0.800 \
  1.0 \
  10.000 \
  0.100 \
  0.015 \
  0.120 \
  0.70
