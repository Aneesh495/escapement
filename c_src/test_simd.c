/*
 * Escapement: C99 SIMD Unit Test Suite.
 * Validates SIMD header validation edge cases, boundary timestamps,
 * and Allan variance numerical stability.
 * Copyright (C) 2026 Aneesh Krishna. All rights reserved.
 */

#include "escapement_simd.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <math.h>

static void test_header_validation_edge_cases(void) {
    uint8_t buf[64];
    memset(buf, 0, sizeof(buf));

    // Too short: length < 34
    assert(escapement_validate_header_simd(buf, 33) == -1);

    // Valid minimal header: msg_type=0, version=2, len=44, domain=0
    buf[0] = 0x00; // major_sdo=0, msg_type=0 (Sync)
    buf[1] = 0x02; // version=2
    buf[2] = 0x00;
    buf[3] = 44;   // len=44
    assert(escapement_validate_header_simd(buf, 44) == 0);

    // Invalid version: version=1
    buf[1] = 0x01;
    assert(escapement_validate_header_simd(buf, 44) == -3);

    // Invalid length: claimed length > packet buffer
    buf[1] = 0x02;
    buf[3] = 100;
    assert(escapement_validate_header_simd(buf, 44) == -4);

    printf("pass: c99 simd header validation edge cases\n");
}

static void test_allan_variance_numerical_stability(void) {
    // Constant signal must yield zero variance
    double const_signal[100];
    for (int i = 0; i < 100; i++) {
        const_signal[i] = 1.0;
    }
    double avar_zero = 0.0;
    int32_t ret = escapement_compute_allan_variance_simd(const_signal, 100, 1, &avar_zero);
    assert(ret == 0);
    assert(fabs(avar_zero) < 1e-18);

    // Too few samples for stride m=50 (need at least 2*m = 100)
    double avar_short = 0.0;
    int32_t ret_short = escapement_compute_allan_variance_simd(const_signal, 50, 30, &avar_short);
    assert(ret_short == -2);

    printf("pass: c99 simd allan variance stability\n");
}

static void test_kalman_step_sanity(void) {
    double state[2] = {0.0, 0.0};
    double cov[4] = {1000.0, 0.0, 0.0, 100.0};

    // Feed constant 10.0 ns measurement
    for (int i = 0; i < 20; i++) {
        escapement_kalman_step_simd(state, cov, 10.0, 0.125, 0.1, 0.01, 50.0);
    }

    assert(state[0] >= 8.0 && state[0] <= 12.0);
    printf("pass: c99 simd kalman step convergence\n");
}

int main(void) {
    printf("--- Running C99 SIMD Unit Test Suite ---\n");
    test_header_validation_edge_cases();
    test_allan_variance_numerical_stability();
    test_kalman_step_sanity();
    printf("All C99 SIMD unit tests passed successfully.\n");
    return 0;
}
