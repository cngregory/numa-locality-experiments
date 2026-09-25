#!/usr/bin/env bash
set -u

results="$HOME/exp2_2026_09_25"
binary="$results/mem_bw"
source_file="$HOME/numa-locality-experiments/mem_bw.c"
mkdir -p "$results/system" "$results/local" "$results/remote"

# Record the setup immediately before the Experiment 2 runs.
{
  date -u '+UTC: %Y-%m-%d %H:%M:%S'
  hostname
  uname -r
  printf 'Git commit: '
  git -C "$HOME/numa-locality-experiments" rev-parse HEAD
  printf 'NUMA balancing: '
  cat /proc/sys/kernel/numa_balancing
  printf 'perf_event_paranoid: '
  cat /proc/sys/kernel/perf_event_paranoid
  printf 'Allowed CPUs and memory nodes:\n'
  grep -E 'Cpus_allowed_list|Mems_allowed_list' /proc/self/status
  printf 'CPU-to-node map:\n'
  lscpu -e=CPU,NODE,SOCKET,CORE,ONLINE
  printf 'Source and executable hashes:\n'
  sha256sum "$source_file" "$binary"
  printf 'Compile command used for the existing executable:\n'
  printf '%s\n' 'gcc -O2 -std=c11 -Wall -Wextra -o /home/cc/exp2_2026_09_25/mem_bw mem_bw.c'
  printf 'Workload: one process, one thread, 1024 MiB, five passes\n'
} > "$results/system/exp2_run_setup.txt" 2>&1

if [[ ! -x "$binary" ]]; then
  printf 'Missing executable: %s\n' "$binary" >&2
  exit 1
fi

# A separate proof-only build pauses immediately after first touch.
# The measured executable above is not changed.
sed '/#include <stdio.h>/a #include <signal.h>' "$source_file" |
  sed '/    const int passes = 5;/i\    raise(SIGSTOP);' \
  > "$results/system/mem_bw_placement_proof.c"

gcc -O2 -std=c11 -Wall -Wextra \
  -o "$results/system/mem_bw_placement_proof" \
  "$results/system/mem_bw_placement_proof.c" \
  > "$results/system/proof_compile_stdout.txt" \
  2> "$results/system/proof_compile_stderr.txt" || exit 1

manifest="$results/system/exp2_commands.txt"
: > "$manifest"

for spec in 'cpu0_local 0 0 local' \
            'cpu0_remote 0 1 remote' \
            'cpu1_local 1 1 local' \
            'cpu1_remote 1 0 remote'; do
  read -r name cpu node location <<< "$spec"
  dir="$results/$location/$name"
  mkdir -p "$dir"

  printf 'Placement proof: CPU %s, memory node %s\n' "$cpu" "$node" \
    > "$dir/placement_description.txt"

  numactl --physcpubind="$cpu" --membind="$node" \
    "$results/system/mem_bw_placement_proof" 1024 \
    > "$dir/placement_proof_benchmark.txt" \
    2> "$dir/placement_proof_errors.txt" &
  pid=$!

  stopped=0
  for attempt in $(seq 1 100); do
    state="$(ps -o stat= -p "$pid" 2>/dev/null || true)"
    if [[ "$state" == *T* ]]; then
      stopped=1
      break
    fi
    if ! kill -0 "$pid" 2>/dev/null; then
      break
    fi
    sleep 0.1
  done

  if (( stopped == 0 )); then
    printf 'ERROR: %s did not pause after first touch\n' "$name" >&2
    wait "$pid" || true
    exit 1
  fi

  taskset -pc "$pid" > "$dir/placement_cpu_affinity.txt" 2>&1
  numastat -p "$pid" > "$dir/placement_numastat.txt" 2>&1
  cat "/proc/$pid/numa_maps" > "$dir/placement_numa_maps.txt"
  cat "/proc/$pid/status" > "$dir/placement_proc_status.txt"
  kill -CONT "$pid"
  wait "$pid"
  printf '%s placement proof exit=%s\n' "$name" "$?" |
    tee "$dir/placement_status.txt"

  for group in cpu imc upi; do
    for repeat in 1 2 3 4 5; do
      prefix="$dir/${group}_repeat_${repeat}"
      case "$group" in
        cpu)
          cmd=(perf stat -o "${prefix}_perf.txt"
               -e cycles,instructions --)
          ;;
        imc)
          cmd=(perf stat -a -A -o "${prefix}_perf.txt"
               -e 'uncore_imc_0/cas_count_read/,uncore_imc_0/cas_count_write/' --)
          ;;
        upi)
          cmd=(perf stat -a -A -o "${prefix}_perf.txt"
               -e 'uncore_upi_0/event=0x03,umask=0x0f/,uncore_upi_0/event=0x02,umask=0x0f/' --)
          ;;
      esac
      cmd+=(numactl --physcpubind="$cpu" --membind="$node" "$binary" 1024)

      printf '%q ' "${cmd[@]}" >> "$manifest"
      printf '\n' >> "$manifest"
      "${cmd[@]}" > "${prefix}_benchmark.txt" \
        2> "${prefix}_errors.txt"
      status=$?
      printf 'exit=%s\n' "$status" > "${prefix}_status.txt"
      printf '%s %s repeat %s exit=%s\n' "$name" "$group" "$repeat" "$status"
      if (( status != 0 )); then
        printf 'Stopping: inspect %s\n' "${prefix}_errors.txt" >&2
        exit "$status"
      fi
    done
  done
done

printf 'Completed all 60 measurement runs.\n'
