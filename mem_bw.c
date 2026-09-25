#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

static double now_sec(void)
{
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC_RAW, &t);
    return t.tv_sec + t.tv_nsec / 1e9;
}

int main(int argc, char **argv)
{
    size_t mb = 1024;
    if (argc > 1)
        mb = strtoull(argv[1], NULL, 10);

    size_t bytes = mb * 1024ULL * 1024ULL;
    size_t n = bytes / sizeof(double);

    double *a = NULL;

    if (posix_memalign((void **)&a, 64, bytes) != 0) {
        perror("allocation");
        return 1;
    }

    /* First touch: placement follows the numactl memory policy. */
    for (size_t i = 0; i < n; i++)
        a[i] = 1.0;

    const int passes = 5;
    double start = now_sec();

    for (int p = 0; p < passes; p++)
        for (size_t i = 0; i < n; i++)
            a[i] = a[i] * 1.0000001 + 1.0;

    double elapsed = now_sec() - start;

    /* Effective read + write bytes. */
    double effective_bytes =
        (double)bytes * passes * 2.0;

    printf("WorkingSet_MiB=%zu\n", mb);
    printf("Elapsed_s=%.6f\n", elapsed);
    printf("Effective_BW_GBps=%.3f\n",
           effective_bytes / elapsed / 1e9);
    printf("Checksum=%.3f\n", a[n / 2]);

    free(a);
    return 0;
}
