# Escapement

**High-Precision IEEE 1588-2019 (PTPv2.1) & IEEE 802.1AS (gPTP) Network Synchronization Engine**

[![Escapement CI](https://github.com/Aneesh495/escapement/actions/workflows/ci.yml/badge.svg)](https://github.com/Aneesh495/escapement/actions/workflows/ci.yml)
[![Factor](https://img.shields.io/badge/Factor-0.102-orange.svg)](https://factorcode.org/)
[![C99 SIMD](https://img.shields.io/badge/C99-NEON%20%2F%20AVX2-blue.svg)](c_src/)
[![Python SDK](https://img.shields.io/badge/Python-3.9%20%7C%203.10%20%7C%203.11%20%7C%203.12%20%7C%203.13-brightgreen.svg)](python/)
[![Standards](https://img.shields.io/badge/Standards-IEEE%201588--2019%20%7C%20IEEE%20802.1AS-purple.svg)](docs/IEEE1588_SPEC.md)

Escapement is a network clock synchronization engine and frequency stability metrology platform written in Factor, accelerated with C99 SIMD vector kernels, and accompanied by a Python compliance verification suite. It implements sub-microsecond time transfer over Ethernet using End-to-End (E2E) and Peer-to-Peer (P2P) delay mechanisms, the Best Master Clock Algorithm (BMCA), 2-state discrete Kalman filter servos, and Allan deviation stability curves.

```
+-----------------------------------------------------------------------------------+
|                                  ESCAPEMENT ENGINE                                |
|   grandmaster | slave | bmca | simulate | stability | serve | inspect | benchmark  |
+-----------------------------------------+-----------------------------------------+
                                          |
                      +-------------------+-------------------+
                      |                                       |
+---------------------v---------------------+   +-------------v---------------------+
|      PROTOCOL & CODEC SUBSYSTEM           |   |       STATE & BMCA SUBSYSTEM      |
|  - 34-byte Clause 13 common header pack   |   |  - Clause 9.3.4 DCA (dataset comp)|
|  - Event: Sync, Delay_Req, Pdelay_Req/Resp|   |  - Clause 9.3.3 SDA (state dec)   |
|  - General: Follow_Up, Delay_Resp, Announce|   |  - Clause 9.2 Port State Machine  |
|  - TLV Chaining (PathTrace TLV 0x0008)    |   |  - Default/Current/Parent Datasets|
+---------------------+---------------------+   +-------------+---------------------+
                      |                                       |
+---------------------v---------------------+   +-------------v---------------------+
|       TIMING & DELAY SOLVERS              |   |       SERVO DYNAMICS SUBSYSTEM    |
|  - E2E Mean Path Delay: ((t2-t1)+(t4-t3))/2|   |  - Proportional-Integral (PI/PID) |
|  - P2P Link Delay: ((t4-t1)-(t3-t2))/2    |   |  - Anti-windup clamping           |
|  - Peer rate ratio compensation (RR)      |   |  - 2-state Discrete Kalman Filter |
|  - Lucky Packet minimum delay filter      |   |  - Linear drift estimator         |
+---------------------+---------------------+   +-------------+---------------------+
                      |                                       |
+---------------------v---------------------+   +-------------v---------------------+
|      STABILITY & FREQUENCY METROLOGY      |   |    SYNTHETIC CLOCK & NETWORK LINK |
|  - Allan Deviation (ADEV, sigma_y(tau))   |   |  - Synthetic crystal oscillator   |
|  - Overlapping Allan Deviation (OADEV)    |   |  - Thermal wander and aging drift |
|  - Modified Allan Deviation (MDEV)        |   |  - Asymmetric link transit delay  |
|  - Time Deviation (TDEV)                  |   |  - Gaussian jitter generator      |
|  - ITU-T G.810 MTIE and G.811 PRC Mask    |   |  - Burst queuing emulation        |
+---------------------+---------------------+   +-------------+---------------------+
                      |                                       |
+---------------------v---------------------------------------v---------------------+
|                       C99 SIMD VECTOR ACCELERATION                                |
|  - ARM NEON / x86 AVX2 vector SIMD validation for 34-byte packet headers          |
|  - Parallelized multi-tau Allan variance reduction kernel                        |
|  - Matrix multiplication and Riccati state update for Kalman filter               |
|  - Sub-nanosecond hardware timestamp capture via clock_gettime(CLOCK_MONOTONIC_RAW)|
+-----------------------------------------------------------------------------------+
```

---

## Key Technical Features

- **Bit-Exact IEEE 1588-2019 Wire Codecs**: Implements Clause 13 binary message formats for event messages (`Sync`, `Delay_Req`, `Pdelay_Req`, `Pdelay_Resp`) and general messages (`Follow_Up`, `Delay_Resp`, `Pdelay_Resp_Follow_Up`, `Announce`, `Signaling`, `Management`).
- **Best Master Clock Algorithm (BMCA)**: Full implementation of Clause 9.3.4 Dataset Comparison Algorithm (DCA) and Clause 9.3.3 State Decision Algorithm (SDA), resolving master, slave, and passive roles across arbitrary network graphs.
- **Hardware Clock Servos**:
  - **Proportional-Integral (PI/PID)** with anti-windup clamping to prevent integrator saturation during network queuing surges.
  - **2-State Discrete Kalman Filter** estimating continuous phase offset $\theta_k$ and frequency drift $\omega_k$ under Gaussian transit noise.
- **Precision Metrology & Stability Analysis**: Computes Allan Deviation (ADEV, $\sigma_y(\tau)$), Modified Allan Deviation (MDEV), Time Deviation (TDEV), and Maximum Time Interval Error (MTIE) with automated ITU-T G.811 Primary Reference Clock (PRC) mask verification.
- **C99 SIMD Vector Acceleration**: NEON and AVX2 vector routines validating over 400 million PTP packet headers per second and computing Allan variance across 1 billion samples per second.
- **Telemetry Server**: Asynchronous HTTP REST API (`/api/v1/status`) and Prometheus exporter (`/metrics`).
- **Python SDK & Compliance Harness**: High-level Python client, wire protocol parser, network simulator, and unittest test runner.

---

## Performance Microbenchmarks

Measurements conducted on Apple Silicon (ARM64 NEON) with `-O3` compilation and Factor 0.102 optimizing compiler:

| Component | Subsystem | Throughput | Latency |
| :--- | :--- | :--- | :--- |
| **PTP Header SIMD Validation** | C99 (NEON / AVX2) | **419.02 M pkts/sec** | 2.39 ns / call |
| **Monotonic Nanotime Capture** | C99 FFI | **34.56 M ops/sec** | 28.94 ns / call |
| **Allan Variance Vector Kernel** | C99 SIMD | **1.003 G samples/sec** | 0.99 ns / sample |
| **Kalman Filter Step** | C99 SIMD | **40.32 M steps/sec** | 24.80 ns / step |
| **BMCA Dataset Comparison (DCA)** | Factor (Native) | **21.80 M ops/sec** | 45.88 ns / eval |
| **PI Servo Step with Anti-Windup** | Factor (Native) | **5.76 M steps/sec** | 173.67 ns / step |
| **2-State Discrete Kalman Step** | Factor (Native) | **2.07 M steps/sec** | 482.12 ns / step |
| **34-Byte Header Unpack + Pack** | Factor (Native) | **543.48 K ops/sec** | 1.84 us / op |
| **Announce Message Codec** | Factor (Native) | **603.76 K ops/sec** | 1.66 us / op |

---

## Quickstart

### Prerequisites
- **Factor**: Version 0.102 or higher at `/Applications/factor/factor` or on your PATH.
- **C Compiler**: Clang (macOS) or GCC (Linux) with C99 and SIMD support.
- **Python**: Version 3.9+ for the verification harness.

### Build and Verify
Clone the repository and run the 7-stage automated verification suite:

```bash
git clone https://github.com/Aneesh495/escapement.git
cd escapement

# Run full automated verification pass
make verify
```

The verification pass builds the C99 SIMD acceleration library, runs C microbenchmarks, executes all Factor unit and integration test suites, runs Factor benchmarks, executes the Python SDK test suite, and completes an end-to-end network simulation.

---

## CLI Reference

Escapement includes a comprehensive command-line interface:

### 1. Network Synchronization Simulation
Simulates 60 epochs of clock synchronization between Master and Slave clocks over an asymmetric channel with Gaussian jitter and burst delay spikes:
```bash
factor -roots=. -run=escapement simulate
```

### 2. Allan Deviation and MTIE Stability Engine
Calculates frequency stability curves (ADEV, MDEV, TDEV) and verifies phase wander against the ITU-T G.811 PRC mask:
```bash
factor -roots=. -run=escapement stability
```

### 3. Best Master Clock Election Demo
Runs an interactive BMCA election comparing local clock attributes against atomic Rubidium and GNSS foreign masters:
```bash
factor -roots=. -run=escapement bmca
```

### 4. Raw Wire Packet Inspector
Dissects and prints structured IEEE 1588 packet fields from raw hex datagrams:
```bash
factor -roots=. -run=escapement inspect 0002002c000000000000000000000000000000000102030405060708000100010000
```

### 5. Telemetry & Prometheus Server
Starts the HTTP status and Prometheus metrics server:
```bash
factor -roots=. -run=escapement serve 8080
# Query JSON status: curl http://localhost:8080/api/v1/status
# Query Prometheus:  curl http://localhost:8080/metrics
```

### 6. Subsystem Microbenchmarks
Runs the high-performance benchmark suite measuring throughput and nanosecond latencies:
```bash
factor -roots=. -run=escapement benchmark
```

---

## Repository Structure

```
escapement/
├── c_src/                           # C99 SIMD acceleration core
│   ├── escapement_simd.h            # Header with NEON/AVX2 detection
│   ├── escapement_simd.c            # SIMD validation, Allan kernel, Kalman step
│   ├── bench_simd.c                 # Standalone C benchmark harness
│   └── Makefile                     # Build rules for dynamic library
├── escapement/                      # Main Factor package
│   ├── common/                      # Constants, endian codecs, ring buffer, types
│   ├── simd/                        # Parse-time FFI loader for C SIMD library
│   ├── protocol/                    # 34-byte header, event/general codecs, TLVs
│   ├── bmca/                        # DCA, SDA, priority vector comparison
│   ├── state/                       # Clause 9.2 port state machine and datasets
│   ├── timing/                      # E2E/P2P delay math, timestamps, filters
│   ├── servo/                       # PI servo, 2-state Kalman filter, linear drift
│   ├── stability/                   # Allan deviation, MDEV, TDEV, ITU-T G.811 MTIE
│   ├── clock/                       # Synthetic oscillator with thermal drift
│   ├── network/                     # Asymmetric channel, Gaussian jitter, queuing
│   ├── boundary/                    # Boundary clock and transparent clock engines
│   ├── profiles/                    # IEEE 1588 default, 802.1AS, G.8275.1 profiles
│   ├── telemetry/                   # JSON serialization and Prometheus exporter
│   ├── server/                      # Asynchronous event loop and UDP dispatcher
│   ├── cli/                         # CLI subcommands (grandmaster, slave, etc.)
│   ├── benchmarks/                  # Factor benchmark suite
│   ├── tests/                       # Unit, conformance, and integration tests
│   └── escapement.factor            # Top-level CLI router and entrypoint
├── python/                          # Python client SDK & conformance harness
│   ├── escapement_sdk/              # Protocol dissector, client, simulator
│   ├── setup.py                     # Setuptools packaging
│   ├── pyproject.toml               # Modern packaging metadata
│   └── test_escapement.py           # Unittest suite
├── configs/                         # PTP profile configuration templates
├── test_vectors/                    # Golden packet vectors and phase wander CSV
├── docs/                            # Deep architectural and mathematical docs
│   ├── ARCHITECTURE.md              # System decomposition and dataflow
│   ├── IEEE1588_SPEC.md             # Wire protocol and delay equations
│   ├── SERVO_DYNAMICS.md            # Control loop theory and Kalman filter
│   ├── STABILITY_ANALYSIS.md        # Allan deviation and MTIE derivations
│   ├── PROFILES_GUIDE.md            # IEEE 1588, 802.1AS, and G.8275.1
│   ├── BENCHMARKS.md                # Execution throughput and latency report
│   ├── DEVELOPER_GUIDE.md           # Developer workflow and Factor idioms
│   └── VERIFICATION_REPORT.md       # Test matrix and edge case results
├── scripts/                         # Build, demo, and audit shell scripts
│   ├── check_no_em_dash.sh          # Strict character verification audit
│   ├── verify.sh                    # 7-stage automated verification harness
│   └── demo.sh                      # Interactive showcase runner
├── Makefile                         # Unified top-level Makefile
└── README.md                        # Project documentation
```

---

## Technical Standards Referenced

- **IEEE Std 1588-2019**: *IEEE Standard for a Precision Clock Synchronization Protocol for Networked Measurement and Control Systems*.
- **IEEE Std 802.1AS-2020**: *Timing and Synchronization for Time-Sensitive Applications in Bridged Local Area Networks*.
- **ITU-T Recommendation G.811 (1997)**: *Timing characteristics of primary reference clocks*.
- **ITU-T Recommendation G.8275.1 (2020)**: *Precision time protocol telecom profile for phase/time synchronization with full timing support from the network*.
- **IEEE Std 1139-2008**: *IEEE Standard Definitions of Physical Quantities for Fundamental Frequency and Time Metrology*.

---

## License

Copyright (C) 2026 Aneesh Krishna. All rights reserved.  
Released under the MIT License.
