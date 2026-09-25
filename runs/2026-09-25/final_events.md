# Final events: NUMA Experiment 2, 2026-09-25

Host: CHI@UC nc46, Intel Xeon Gold 6126, two NUMA nodes.
Kernel: 6.8.0-124-generic. PAPI: 7.1.0.0. perf: 6.8.12.
Benchmark: mem_bw.c at commit b0358b4468e5e675220a64647ec4c45fbe65ca6f.
Source SHA-256: 876de38a387c0b33dfd5fa84409e7d7ea626e5a306acf644ee6be6224673bbb6.
Validation workload: one thread, 1024 MiB, five passes, CPU 0.
All 18 individual mem_bw tests exited 0 with Checksum=6.000.

## Access and collection

Initially, perf_event_paranoid=4 disabled PAPI uncore access. Setting it to 0
on the reserved host activated perf_event_uncore. PAPI command-line checks
showed each candidate could start; uncore PAPI names required :cpu=0.
The actual mem_bw tests used perf stat. Each event was tested alone three
times. CPU, IMC, and UPI pairs also ran successfully in separate groups.

CPU counters are process-scoped. Uncore counters use perf -a -A and are
system-wide, with separate CPU0 and CPU1 PMU rows. Uncore counts can include
unrelated host activity. No reviewed run reported <not counted>, an error,
or a visible multiplex scaling annotation. Cross-group simultaneous
collection was not tested or required.

## Selected events

| Exact perf event | PAPI spelling and component | Meaning, three individual local runs, decision |
|---|---|---|
| `cycles` | `PAPI_TOT_CYC`, perf_event | Process cycles: 5,234,414,660; 5,202,219,944; 5,198,352,746. Accept. |
| `instructions` | `PAPI_TOT_INS`, perf_event | Retired instructions: 6,570,141,295; 6,572,123,785; 6,569,998,950. Accept. Compute IPC from cycles and instructions in the same paired run. |
| `uncore_imc_0/cas_count_read/` | `skx_unc_imc0::UNC_M_CAS_COUNT:RD:cpu=0`, perf_event_uncore | IMC0 DRAM reads, kernel-scaled MiB. CPU0: 865.13, 865.32, 865.19 MiB; CPU1: 0.93, 1.20, 1.07 MiB. Accept as one-channel indicator, not total DRAM traffic. |
| `uncore_imc_0/cas_count_write/` | `skx_unc_imc0::UNC_M_CAS_COUNT:WR:cpu=0`, perf_event_uncore | IMC0 DRAM writes, kernel-scaled MiB. CPU0: 1016.78, 1016.41, 1016.84 MiB; CPU1: 1.19, 1.13, 1.13 MiB. Accept with the same scope limit. |
| `uncore_upi_0/event=0x03,umask=0x0f/` | `skx_unc_upi0::UNC_UPI_RXL_FLITS:ALL_DATA:cpu=0`, perf_event_uncore | UPI0 received data flits. CPU0: 331164, 273582, 354447; CPU1: 92340, 82170, 93510. Accept with variability and system-wide, one-link caveats. |
| `uncore_upi_0/event=0x02,umask=0x0f/` | `skx_unc_upi0::UNC_UPI_TXL_FLITS:ALL_DATA:cpu=0`, perf_event_uncore | UPI0 transmitted data flits. CPU0: 103266, 91620, 111330; CPU1: 429732, 352611, 299322. Accept with the same caveats. |

PAPI_L3_TCM passed only a built-in-work check and is not selected because
it was not tested three times against mem_bw.

## Group and placement pilot evidence

Three local paired runs succeeded for each CPU, IMC, and UPI group.
The CPU pair yielded about 1.30 IPC. IMC0 activity was concentrated on
the CPU0 row during local-node-0 runs. UPI local counts varied more than
CPU and IMC counts; idle UPI controls were mostly 18,000–62,000 counts.

For the remote pilot, CPU 0 was paired with memory node 1. Three IMC
pair runs moved IMC0 activity to the CPU1 row: reads 1038–1042 MiB and
writes 2023–2035 MiB. Three UPI pair runs showed about 379 million and
449 million data flits in the major directions. Pilot bandwidth was
about 12.91–13.00 GB/s; all checksums were 6.000. This pilot supports
event selection, but is NOT an accepted Experiment 2 result because
live physical page placement was not captured.

## Units and limits

The kernel's IMC `cas_count_read.scale` is 6.103515625e-5 MiB per count,
equivalent to 64 bytes per count for this kernel event. perf already
displays the scaled MiB; do not scale those displayed values again.
Check and retain the corresponding write-event definition too.

Intel's Skylake Server event descriptions say each ALL_DATA UPI flit
contains 64 data bits (8 payload bytes), plus protocol bits. Thus raw
data-flit counts can represent 8 payload bytes per count, not 64 bytes;
this covers only the selected UPI link and excludes other overhead.
Source: https://perfmon-events.intel.com/platforms/skylakex/uncore-events/uncore/

mem_bw's Elapsed_s measures only its five-pass loop. perf measures the
whole command, including allocation and first touch. Keep time scopes
distinct. Compare matched CPU, memory policy, event group, PMU row, and
duration. Record automatic NUMA balancing and capture taskset, numastat
-p PID, and /proc/PID/numa_maps while the benchmark lives before
accepting local/remote Experiment 2 runs.

Raw commands, benchmark output, counter output, errors, and statuses are
in OneDrive's event_validation/individual; pair tests, idle controls,
and remote_pilot are also under event_validation.
