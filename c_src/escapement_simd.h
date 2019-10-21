/*
 * Escapement SIMD Fast-Path and High-Precision Clock Acceleration
 *
 * Provides vectorized packet validation, rolling Allan variance computation,
 * discrete Kalman filter matrix updates, and nanosecond monotonic clock capture.
 */

#ifndef ESCAPEMENT_SIMD_H
#define ESCAPEMENT_SIMD_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Monotonic and real-time clock timestamp acquisition in nanoseconds */
uint64_t escapement_nanotime_monotonic(void);
uint64_t escapement_nanotime_realtime(void);

/* PTP header validation via SIMD/SWAR byte inspection */
int32_t escapement_validate_header_simd(const uint8_t *data, size_t len);

/* Vectorized Allan variance computation over frequency deviation series */
int32_t escapement_compute_allan_variance_simd(
    const double *fractional_freqs,
    size_t count,
    size_t stride,
    double *out_variance
);

/* Vectorized Modified Allan variance computation */
int32_t escapement_compute_modified_allan_variance_simd(
    const double *phase_samples,
    size_t count,
    size_t tau_step,
    double *out_mvar
);

/* 2-State Kalman filter prediction and measurement update step
 * State: [0] = phase offset (ns), [1] = frequency drift (ppb)
 * Covariance: [0]=P00, [1]=P01, [2]=P10, [3]=P11
 */
int32_t escapement_kalman_step_simd(
    double *state_2,
    double *cov_2x2,
    double meas_phase,
    double dt,
    double q_phase,
    double q_freq,
    double r_meas
);

/* Fast rolling median filter for packet delay variation outlier rejection */
int32_t escapement_rolling_median_filter(
    const double *in_samples,
    double *out_filtered,
    size_t count,
    size_t window_size
);

/* Network byte order correction field encoder and decoder (scaled nanoseconds) */
int64_t escapement_unpack_correction_field(const uint8_t *buf_8bytes);
void escapement_pack_correction_field(int64_t scaled_ns, uint8_t *out_8bytes);

#ifdef __cplusplus
}
#endif

#endif /* ESCAPEMENT_SIMD_H */
