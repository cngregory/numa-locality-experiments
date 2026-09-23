# August 2026 NUMA and PAPI setup records

## Purpose

This folder records early machine setup, bandwidth measurements, and attempts to discover PAPI performance events for the NUMA memory research project.

The folder is named `2026-08-10`, but `system_info.txt` contains the timestamp **2026-08-03 17:27 UTC**. The exact dates of the other commands have not been verified. Do not assume every file was generated on August 10.

## Machine recorded

`system_info.txt` describes a bare-metal machine named `mincer-papi-quicktest2` with:

- Two Intel Xeon Gold 6126 sockets
- 24 CPUs total, with 12 CPUs per NUMA node
- Two NUMA nodes
- Approximately 187 GiB of total memory
- NUMA node distance 10 within a node and 21 between nodes

Node 0 contains even-numbered CPUs (`0, 2, ... 22`), and node 1 contains odd-numbered CPUs (`1, 3, ... 23`). These details apply to the recorded machine and must be checked again on any new Chameleon host.

## Files

| File | What it records |
| --- | --- |
| `system_info.txt` | Host, CPU, memory, NUMA topology, system NUMA statistics, and perf settings |
| `install_log.txt` | Package installation output, including PAPI and numactl |
| `papi_avail.txt` | PAPI preset event discovery |
| `papi_component_avail.txt` | Status of PAPI components and reasons components were disabled |
| `papi_native_all.txt` | Native event discovery output |
| `papi_native_memory.txt` | Short filtered output from native event discovery |
| `perf_list.txt` | Reports that `perf` was not found |
| `baseline_results.txt` | Five bandwidth measurements labeled “baseline” |
| `contention_results.txt` | Five bandwidth measurements labeled “contention” |
| `stress_ng.txt` | Output from an eight-worker, 45-second `stress-ng` stream run |


## Where the raw files are stored

The complete set of raw `.txt` files is in OneDrive:

`HPC - Mincer/Metrics/06_results/raw_local_baseline/2026-08-03_baseline_contention/`

Copies of these five files are also in this GitHub folder:

- `baseline_results.txt`
- `papi_avail.txt`
- `papi_component_avail.txt`
- `stress_ng.txt`
- `system_info.txt`

The other raw files, including `contention_results.txt`, `install_log.txt`, `papi_native_all.txt`, `papi_native_memory.txt`, and `perf_list.txt`, are in OneDrive. Keep the OneDrive originals so the complete run record stays together.

## What the files show

`system_info.txt` records a machine with two Intel Xeon Gold 6126 sockets and two NUMA nodes. The baseline file contains five bandwidth measurements averaging **13.097 GB/s**. The contention file in OneDrive contains five measurements averaging **8.914 GB/s**.

These are labeled *baseline* and *contention*. The saved outputs do not include the exact benchmark commands or CPU and memory bindings, so these two files alone do not establish a local versus remote NUMA penalty.

PAPI 7.2.0 was installed, but these checks found **zero available events**. The CPU counter component reported `perf_event_paranoid=4`, and the uncore component reported insufficient permissions. No PAPI event was validated in this run.

## Bandwidth measurements

Both bandwidth result files report a 768 MiB working set and five runs.

| Recorded condition | Individual bandwidths (GB/s) | Mean (GB/s) |
| --- | --- | ---: |
| Baseline | 12.750, 12.787, 13.480, 13.428, 13.040 | 13.097 |
| Contention | 8.978, 8.905, 8.990, 8.934, 8.764 | 8.914 |

The contention mean is approximately **32% lower** than the baseline mean. These files do **not** establish a local-versus-remote NUMA bandwidth penalty: the exact benchmark command, CPU binding, memory binding, and meaning of “contention” were not saved with these outputs.

`stress_ng.txt` records a separate stream stress run. Its output describes the stressor as loosely based on STREAM and says not to submit these numbers as STREAM benchmark results.

## PAPI and perf status

PAPI 7.2.0 was installed, but no usable preset or native events were reported in these saved checks:

- The `perf_event` component was disabled with `kernel.perf_event_paranoid = 4`.
- The `perf_event_uncore` component reported insufficient permissions.
- `papi_avail.txt` reported zero available events.
- `papi_native_all.txt` reported zero events.
- `perf_list.txt` says `perf not found`.

**No PAPI event was validated by these files.** Event discovery and collection must be checked again on the machine used for the next experiment.

## Reproducibility limits

The exact shell commands used to produce these results were not saved. In particular, this folder does not document:

- The benchmark source code and compile command for the bandwidth results
- CPU affinity and memory binding for each bandwidth run
- Whether Linux automatic NUMA balancing was enabled
- Process-level physical page placement checks
- The full command used to generate each output file

Do not reconstruct those commands from memory and describe them as the original commands. Future runs should save the exact commands, machine configuration, placement checks, and raw output together.

## Missing run details

The original commands were not saved. The benchmark source and compile command, CPU and memory bindings, automatic NUMA balancing setting, and process-level page placement checks are not documented here. Future runs should save those details alongside their results.

## Relationship to Dr. Moore's experimental plan

This folder provides machine topology, initial repeated bandwidth measurements, and a record of why PAPI event discovery was blocked. It does not complete the README's four-way placement matrix, physical page placement verification, pointer-chasing latency tests, STREAM kernel and thread-count study, or validation of local DRAM, remote DRAM, and inter-socket traffic counters.

See the project's current run folder for event validation and the next controlled local-versus-remote experiment.
