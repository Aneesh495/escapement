/*
 * Escapement SIMD Fast-Path and High-Precision Clock Acceleration
 *
 * Implements vectorized packet checking, SIMD Allan variance calculations,
 * and high-resolution time access.
 */

#include "escapement_simd.h"
#include <time.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>

#if defined(__ARM_NEON) || defined(__ARM_NEON__)
#include <arm_neon.h>
#define ESCAPEMENT_HAS_NEON 1
#elif defined(__AVX2__)
#include <immintrin.h>
#define ESCAPEMENT_HAS_AVX2 1
#endif

/* Monotonic nanoseconds from high-resolution system clock */
uint64_t escapement_nanotime_monotonic(void) {
    struct timespec ts;
#if defined(CLOCK_MONOTONIC_RAW)
    clock_gettime(CLOCK_MONOTONIC_RAW, &ts);
#elif defined(CLOCK_MONOTONIC)
    clock_gettime(CLOCK_MONOTONIC, &ts);
#else
    clock_gettime(CLOCK_REALTIME, &ts);
#endif
    return ((uint64_t)ts.tv_sec * 1000000000ULL) + (uint64_t)ts.tv_nsec;
}

/* Real-time wall clock nanoseconds */
uint64_t escapement_nanotime_realtime(void) {
    struct timespec ts;
    clock_gettime(CLOCK_REALTIME, &ts);
    return ((uint64_t)ts.tv_sec * 1000000000ULL) + (uint64_t)ts.tv_nsec;
}

/* Fast PTP header validator (34 bytes minimum) */
int32_t escapement_validate_header_simd(const uint8_t *data, size_t len) {
    if (!data || len < 34) {
        return -1;
    }

    /* Byte 0: lower 4 bits is messageType (0x0 to 0xD) */
    uint8_t msg_type = data[0] & 0x0F;
    if (msg_type > 0x0D) {
        return -2;
    }

    /* Byte 1: lower 4 bits is versionPTP (must be 2 for IEEE 1588-2008/2019) */
    uint8_t version = data[1] & 0x0F;
    if (version != 2) {
        return -3;
    }

    /* Bytes 2-3: messageLength (big endian uint16) */
    uint16_t msg_len = ((uint16_t)data[2] << 8) | (uint16_t)data[3];
    if (msg_len < 34 || (size_t)msg_len > len) {
        return -4;
    }

    /* Domain number at byte 4 is uint8 (always valid 0..255) */

    /* Bytes 30-31: sequenceId */
    /* Byte 32: controlField */
    /* Byte 33: logMessageInterval */
    return 0;
}

/* Compute standard Allan variance over fractional frequency deviations
 * sigma_y^2(tau) = 1 / (2 * (N - 1)) * sum_{i=0}^{N-2} (y_{i+1} - y_i)^2
 */
int32_t escapement_compute_allan_variance_simd(
    const double *fractional_freqs,
    size_t count,
    size_t stride,
    double *out_variance
) {
    if (!fractional_freqs || !out_variance || count < 2 || stride < 1) {
        return -1;
    }

    size_t effective_n = count / stride;
    if (effective_n < 2) {
        return -2;
    }

    double sum_sq_diff = 0.0;
    size_t pairs = effective_n - 1;

#if defined(ESCAPEMENT_HAS_NEON)
    float64x2_t v_sum = vdupq_n_f64(0.0);
    size_t i = 0;
    size_t vec_limit = (pairs >= 2) ? (pairs - (pairs % 2)) : 0;

    for (; i < vec_limit; i += 2) {
        size_t idx0 = i * stride;
        size_t idx1 = (i + 1) * stride;
        size_t idx2 = (i + 2) * stride;

        float64x2_t curr = { fractional_freqs[idx0], fractional_freqs[idx1] };
        float64x2_t next = { fractional_freqs[idx1], fractional_freqs[idx2] };
        float64x2_t diff = vsubq_f64(next, curr);
        v_sum = vmlaq_f64(v_sum, diff, diff);
    }

    sum_sq_diff = vgetq_lane_f64(v_sum, 0) + vgetq_lane_f64(v_sum, 1);

    for (; i < pairs; ++i) {
        double diff = fractional_freqs[(i + 1) * stride] - fractional_freqs[i * stride];
        sum_sq_diff += diff * diff;
    }
#elif defined(ESCAPEMENT_HAS_AVX2)
    __m256d v_sum = _mm256_setzero_pd();
    size_t i = 0;
    size_t vec_limit = (pairs >= 4) ? (pairs - (pairs % 4)) : 0;

    for (; i < vec_limit; i += 4) {
        double d0 = fractional_freqs[(i + 1) * stride] - fractional_freqs[i * stride];
        double d1 = fractional_freqs[(i + 2) * stride] - fractional_freqs[(i + 1) * stride];
        double d2 = fractional_freqs[(i + 3) * stride] - fractional_freqs[(i + 2) * stride];
        double d3 = fractional_freqs[(i + 4) * stride] - fractional_freqs[(i + 3) * stride];

        __m256d v_diff = _mm256_set_pd(d3, d2, d1, d0);
        v_sum = _mm256_fmadd_pd(v_diff, v_diff, v_sum);
    }

    double buf[4];
    _mm256_storeu_pd(buf, v_sum);
    sum_sq_diff = buf[0] + buf[1] + buf[2] + buf[3];

    for (; i < pairs; ++i) {
        double diff = fractional_freqs[(i + 1) * stride] - fractional_freqs[i * stride];
        sum_sq_diff += diff * diff;
    }
#else
    for (size_t i = 0; i < pairs; ++i) {
        double diff = fractional_freqs[(i + 1) * stride] - fractional_freqs[i * stride];
        sum_sq_diff += diff * diff;
    }
#endif

    *out_variance = sum_sq_diff / (2.0 * (double)pairs);
    return 0;
}

/* Compute Modified Allan Variance over phase data series */
int32_t escapement_compute_modified_allan_variance_simd(
    const double *phase_samples,
    size_t count,
    size_t tau_step,
    double *out_mvar
) {
    if (!phase_samples || !out_mvar || count < 3 || tau_step < 1) {
        return -1;
    }

    size_t m = tau_step;
    if (count < 3 * m + 1) {
        return -2;
    }

    size_t n_outer = count - 3 * m + 1;
    double total_sum = 0.0;

    for (size_t j = 0; j < n_outer; ++j) {
        double sum_inner = 0.0;
        for (size_t i = j; i < j + m; ++i) {
            double d = phase_samples[i + 2 * m] - 2.0 * phase_samples[i + m] + phase_samples[i];
            sum_inner += d;
        }
        total_sum += sum_inner * sum_inner;
    }

    double denominator = 2.0 * ((double)m * (double)m) * ((double)tau_step * (double)tau_step) * (double)n_outer;
    if (denominator <= 0.0) {
        return -3;
    }

    *out_mvar = total_sum / denominator;
    return 0;
}

/* 2-State Kalman Filter Step:
 * State: x = [phase_error (ns), freq_drift (ppb)]
 * Transition matrix: F = [ [1, dt], [0, 1] ]
 * Measurement matrix: H = [1, 0]
 */
int32_t escapement_kalman_step_simd(
    double *state,
    double *cov,
    double meas_phase,
    double dt,
    double q_phase,
    double q_freq,
    double r_meas
) {
    if (!state || !cov || dt <= 0.0) {
        return -1;
    }

    /* 1. Predict state: x_prior = F * x */
    double x0 = state[0] + dt * state[1];
    double x1 = state[1];

    /* 2. Predict covariance: P_prior = F * P * F^T + Q */
    double p00 = cov[0];
    double p01 = cov[1];
    double p10 = cov[2];
    double p11 = cov[3];

    double p_prior_00 = p00 + dt * (p10 + p01) + dt * dt * p11 + q_phase;
    double p_prior_01 = p01 + dt * p11;
    double p_prior_10 = p10 + dt * p11;
    double p_prior_11 = p11 + q_freq;

    /* 3. Innovation: y = meas - H * x_prior */
    double innovation = meas_phase - x0;

    /* 4. Innovation covariance: S = H * P_prior * H^T + R = P_prior_00 + R */
    double s = p_prior_00 + r_meas;
    if (fabs(s) < 1e-15) {
        s = 1e-15;
    }

    /* 5. Kalman gain: K = P_prior * H^T / S */
    double k0 = p_prior_00 / s;
    double k1 = p_prior_10 / s;

    /* 6. Update state: x_post = x_prior + K * innovation */
    state[0] = x0 + k0 * innovation;
    state[1] = x1 + k1 * innovation;

    /* 7. Update covariance: P_post = (I - K * H) * P_prior */
    cov[0] = p_prior_00 - k0 * p_prior_00;
    cov[1] = p_prior_01 - k0 * p_prior_01;
    cov[2] = p_prior_10 - k1 * p_prior_00;
    cov[3] = p_prior_11 - k1 * p_prior_01;

    return 0;
}

/* Compare function for qsort */
static int double_compare(const void *a, const void *b) {
    double da = *(const double *)a;
    double db = *(const double *)b;
    if (da < db) return -1;
    if (da > db) return 1;
    return 0;
}

/* Rolling median filter for packet delay variation (PDV) filtering */
int32_t escapement_rolling_median_filter(
    const double *in_samples,
    double *out_filtered,
    size_t count,
    size_t window_size
) {
    if (!in_samples || !out_filtered || count == 0 || window_size == 0) {
        return -1;
    }

    if (window_size > count) {
        window_size = count;
    }

    double *window = (double *)malloc(window_size * sizeof(double));
    if (!window) {
        return -2;
    }

    size_t half = window_size / 2;

    for (size_t i = 0; i < count; ++i) {
        size_t start = (i >= half) ? (i - half) : 0;
        size_t end = start + window_size;
        if (end > count) {
            end = count;
            start = (end >= window_size) ? (end - window_size) : 0;
        }

        size_t actual_w = end - start;
        memcpy(window, &in_samples[start], actual_w * sizeof(double));
        qsort(window, actual_w, sizeof(double), double_compare);

        out_filtered[i] = window[actual_w / 2];
    }

    free(window);
    return 0;
}

/* Unpack 8-byte big-endian correction field as scaled nanoseconds */
int64_t escapement_unpack_correction_field(const uint8_t *buf) {
    if (!buf) return 0;
    uint64_t val = 0;
    for (int i = 0; i < 8; ++i) {
        val = (val << 8) | (uint64_t)buf[i];
    }
    return (int64_t)val;
}

/* Pack scaled nanoseconds into 8-byte big-endian buffer */
void escapement_pack_correction_field(int64_t scaled_ns, uint8_t *out) {
    if (!out) return;
    uint64_t val = (uint64_t)scaled_ns;
    for (int i = 7; i >= 0; --i) {
        out[i] = (uint8_t)(val & 0xFF);
        val >>= 8;
    }
}
