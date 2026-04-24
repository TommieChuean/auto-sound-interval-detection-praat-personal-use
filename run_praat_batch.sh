#!/bin/zsh
set -eu

script_dir="${0:A:h}"
praat_bin="/Applications/Praat.app/Contents/MacOS/Praat"

if [[ $# -lt 1 || $# -gt 3 ]]; then
  echo "Usage: $0 <audio-file-or-folder> [output-csv] [file-glob]" >&2
  exit 1
fi

input_path="$1"
output_csv="${2:-praat_results.csv}"
file_glob="${3:-*.wav}"

exec "$praat_bin" --run "$script_dir/detect_intervals.praat" \
  "$input_path" \
  "$file_glob" \
  "$output_csv" \
  -14 \
  -30 \
  100 \
  75 \
  0.008 \
  0.05 \
  0.003 \
  0.100 \
  0.100 \
  0.050 \
  8.0 \
  0.120 \
  0.100 \
  0.700 \
  0.800 \
  0.450 \
  0.350 \
  0.250 \
  0.550 \
  8.0 \
  3.000 \
  0.080 \
  0.020 \
  0.450 \
  2 \
  0.350 \
  0.120 \
  180 \
  260 \
  2 \
  0
