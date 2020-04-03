# Escapement Subsystem Performance Benchmarks

This report summarizes execution throughput and per-operation latency benchmarks across the Factor engine and C99 SIMD acceleration subsystem.

## Test Environment
- **Architecture**: Apple Silicon (ARM64 NEON vector extensions) / x86_64 AVX2
- **Compiler**: Apple clang version 17.0.0 (`-O3 -Wall -Wextra -pedantic -fPIC -std=c99`)
- **Factor Version**: Factor 0.102 (Optimizing Compiler enabled)
- **Monotonic Hardware Clock**: `clock_gettime(CLOCK_MONOTONIC_RAW)`

## Benchmark Summary

| Subsystem Component | Implementation | Iterations | Throughput | Latency |
| :--- | :--- | :--- | :--- | :--- |
| **PTP Header SIMD Validation** | C99 (NEON/AVX2) | 100,000,000 | 419.02 M pkts/sec | 2.39 ns / call |
| **Monotonic Nanotime Capture** | C99 FFI | 50,000,000 | 34.56 M ops/sec | 28.94 ns / call |
| **Allan Variance Vector Kernel** | C99 SIMD | 100,000 samples | 1.003 G samples/sec | 0.99 ns / sample |
| **Kalman Filter Step** | C99 SIMD | 1,000,000 | 40.32 M steps/sec | 24.80 ns / step |
| **BMCA Dataset Comparison (DCA)** | Factor (Native) | 100,000 | 21.80 M ops/sec | 45.88 ns / eval |
| **PI Servo Step with Anti-Windup** | Factor (Native) | 100,000 | 5.76 M steps/sec | 173.67 ns / step |
| **2-State Discrete Kalman Step** | Factor (Native) | 100,000 | 2.07 M steps/sec | 482.12 ns / step |
| **34-Byte Header Unpack + Pack** | Factor (Native) | 50,000 | 543.48 K ops/sec | 1839.99 ns / op |
| **Announce Message Codec** | Factor (Native) | 50,000 | 603.76 K ops/sec | 1656.28 ns / op |
| **Ring Buffer Rolling Stats (N=64)**| Factor (Native) | 50,000 | 52.21 K ops/sec | 19.15 us / op |
| **Allan Multi-Tau Stability Curve**| Factor (Native) | 500 samples | 70.27 curves/sec | 14.23 ms / curve |

## Analysis and Discussion

### C99 SIMD Acceleration Path
Vectorizing the 34-byte PTP header validation across 128-bit NEON / 256-bit AVX2 registers achieves 419 million packets per second (2.39 ns per header). This ensures wire-rate throughput on 100GbE network interfaces without packet processing bottlenecks.

The vectorized Allan variance kernel processes over 1 billion phase error samples per second, enabling real-time frequency stability analysis without noticeable CPU overhead.

### Factor Native Performance
Factor's optimizing compiler generates tight machine code for stack operations:
- Dataset Comparison Algorithm (DCA) achieves 21.8 million evaluations per second (45.88 ns per evaluation), ensuring instantaneous failover during network topology changes.
- The 2-state discrete Kalman filter processes over 2 million updates per second in pure Factor, which exceeds typical 8 Hz or 128 Hz PTP Sync packet rates by multiple orders of magnitude.
