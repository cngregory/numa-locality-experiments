#!/usr/bin/env bash
set -u

out="$HOME/exp2_2026_09_25/event_validation/individual"
mkdir -p "$out"

names=(cycles instructions imc_read imc_write upi_rx upi_tx)
events=(
  'cycles'
  'instructions'
  'uncore_imc_0/cas_count_read/'
  'uncore_imc_0/cas_count_write/'
  'uncore_upi_0/event=0x03,umask=0x0f/'
  'uncore_upi_0/event=0x02,umask=0x0f/'
)

for index in "${!names[@]}"; do
  name="${names[$index]}"
  event="${events[$index]}"
  options=()
  if [[ "$name" == imc_* || "$name" == upi_* ]]; then
    options=(-a -A)
  fi

  for repeat in 1 2 3; do
    prefix="$out/${name}_repeat_${repeat}"
    printf '%q ' perf stat "${options[@]}" -e "$event" -- \
      numactl --physcpubind=0 --membind=0 \
      "$HOME/exp2_2026_09_25/mem_bw" 1024 > "${prefix}_command.txt"
    printf '\n' >> "${prefix}_command.txt"

    perf stat "${options[@]}" -o "${prefix}_perf.txt" -e "$event" -- \
      numactl --physcpubind=0 --membind=0 \
      "$HOME/exp2_2026_09_25/mem_bw" 1024 \
      > "${prefix}_benchmark.txt" 2> "${prefix}_errors.txt"

    printf '%s repeat %s exit=%s\n' "$name" "$repeat" "$?" | tee "${prefix}_status.txt"
  done
done
