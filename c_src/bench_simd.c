/*
 * Escapement SIMD Microbenchmark Suite
 *
 * Measures throughput and latency of SIMD packet validation,
 * Allan variance calculation, and Kalman filter iterations.
 */

#include "escapement_simd.h"
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>

static double get_time_sec(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + (double)ts.tv_nsec * 1e-9;
}

int main(void) {
    printf("================================================================================\n");
    printf("                    ESCAPEMENT C99 / SIMD MICROBENCHMARK                        \n");
    printf("================================================================================\n");

    /* 1. Benchmark high-resolution timestamp capture */
    const size_t TS_ITERS = 5000000;
    double t0 = get_time_sec();
    uint64_t dummy = 0;
    for (size_t i = 0; i < TS_ITERS; ++i) {
        dummy += escapement_nanotime_monotonic();
    }
    double t1 = get_time_sec();
    double ts_rate = (double)TS_ITERS / (t1 - t0);
    double ts_lat_ns = ((t1 - t0) / (double)TS_ITERS) * 1e9;
    printf("[1] Nanotime Monotonic Capture (dummy=%llu):\n", (unsigned long long)dummy);
    printf("    Throughput: %.2f M ops/sec | Latency: %.2f ns/call\n\n", ts_rate / 1e6, ts_lat_ns);

    /* 2. Benchmark PTP header validation */
    uint8_t sample_header[34] = {
        0x00, 0x02, 0x00, 0x2C, /* Sync, v2, len=44 */
        0x00, 0x00, 0x00, 0x00, /* domain=0, flags=0 */
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* correction */
        0x00, 0x00, 0x00, 0x00,
        0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x00, 0x01, /* port */
        0x00, 0x01, 0x00, 0x00  /* seq=1, control=0, interval=0 */
    };
    const size_t HDR_ITERS = 10000000;
    t0 = get_time_sec();
    int32_t val_sum = 0;
    for (size_t i = 0; i < HDR_ITERS; ++i) {
        val_sum += escapement_validate_header_simd(sample_header, 44);
    }
    t1 = get_time_sec();
    double hdr_rate = (double)HDR_ITERS / (t1 - t0);
    double hdr_lat_ns = ((t1 - t0) / (double)HDR_ITERS) * 1e9;
    printf("[2] PTP Header SIMD Validation (res=%d):\n", val_sum);
    printf("    Throughput: %.2f M packets/sec | Latency: %.2f ns/call\n\n", hdr_rate / 1e6, hdr_lat_ns);

    /* 3. Benchmark Allan variance computation */
    const size_t SAMPLE_COUNT = 100000;
    double *freqs = (double *)malloc(SAMPLE_COUNT * sizeof(double));
    for (size_t i = 0; i < SAMPLE_COUNT; ++i) {
        freqs[i] = 1e-9 * sin((double)i * 0.05) + 5e-10 * ((double)rand() / (double)RAND_MAX - 0.5);
    }
    double allan_var = 0.0;
    const size_t AVAR_ITERS = 500;
    t0 = get_time_sec();
    for (size_t i = 0; i < AVAR_ITERS; ++i) {
        escapement_compute_allan_variance_simd(freqs, SAMPLE_COUNT, 1, &allan_var);
    }
    t1 = get_time_sec();
    double avar_samples_per_sec = (double)(SAMPLE_COUNT * AVAR_ITERS) / (t1 - t0);
    printf("[3] Allan Variance Calculation (count=%zu, avar=%.4e):\n", SAMPLE_COUNT, allan_var);
    printf("    Processed: %.2f M samples/sec | Elapsed: %.4f s\n\n", avar_samples_per_sec / 1e6, t1 - t0);

    /* 4. Benchmark 2-State Kalman Filter */
    double state[2] = { 0.0, 0.0 };
    double cov[4] = { 100.0, 0.0, 0.0, 1.0 };
    const size_t KF_ITERS = 5000000;
    t0 = get_time_sec();
    for (size_t i = 0; i < KF_ITERS; ++i) {
        escapement_kalman_step_simd(state, cov, 12.5, 0.125, 0.01, 0.001, 4.0);
    }
    t1 = get_time_sec();
    double kf_rate = (double)KF_ITERS / (t1 - t0);
    double kf_lat_ns = ((t1 - t0) / (double)KF_ITERS) * 1e9;
    printf("[4] 2-State Kalman Filter Steps (state=[%.2f, %.4f]):\n", state[0], state[1]);
    printf("    Throughput: %.2f M steps/sec | Latency: %.2f ns/step\n\n", kf_rate / 1e6, kf_lat_ns);

    printf("All C99/SIMD microbenchmarks completed successfully.\n");
    free(freqs);
    return 0;
}
