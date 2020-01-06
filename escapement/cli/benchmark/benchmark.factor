! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Benchmark CLI command: evaluates execution throughput of Factor PTP routines.

USING: accessors arrays byte-arrays formatting io kernel locals
math math.functions math.parser sequences strings system
escapement.bmca.dataset-comparison escapement.bmca.priority-vector
escapement.common.constants escapement.common.types
escapement.protocol.header escapement.protocol.messages.announce
escapement.servo.kalman escapement.stability.allan ;
IN: escapement.cli.benchmark

:: run-benchmark-cli ( -- )
    "================================================================================" print
    "                     ESCAPEMENT FACTOR MICROBENCHMARKS                          " print
    "================================================================================" print

    ! 1. Benchmark PTP Header Packing / Unpacking
    { 1 2 3 4 5 6 7 8 } >byte-array <clock-identity> 1 <port-identity> :> pid
    0 44 0 0 pid 1 <ptp-header> :> hdr
    hdr pack-ptp-header :> raw-bytes

    50000 :> hdr-iters
    nano-count :> t0
    hdr-iters [| i |
        raw-bytes unpack-ptp-header pack-ptp-header drop
    ] each-integer
    nano-count :> t1
    t1 t0 - >float 1e-9 * :> hdr-elapsed
    hdr-iters >float hdr-elapsed / :> hdr-ops-per-sec
    hdr-elapsed hdr-iters >float / 1e9 * :> hdr-ns-per-op

    hdr-iters "[1] 34-Byte Header Unpack+Pack (%d iterations):\n" printf
    hdr-ops-per-sec 1000.0 / hdr-ns-per-op
    "    Throughput: %.2f K ops/sec | Latency: %.2f ns/roundtrip\n\n" printf

    ! 2. Benchmark BMCA Dataset Comparison Algorithm (DCA)
    { 0x01 0x02 0x03 0x04 0x05 0x06 0x07 0x08 } >byte-array <clock-identity> :> cid1
    { 0x01 0x02 0x03 0x04 0x05 0x06 0x07 0x09 } >byte-array <clock-identity> :> cid2
    128 6 0x20 0x1000 128 cid1 0 cid1 1 <port-identity> 1 <priority-vector> :> pv1
    128 7 0x21 0x2000 128 cid2 0 cid2 1 <port-identity> 1 <priority-vector> :> pv2

    100000 :> dca-iters
    nano-count :> t2
    dca-iters [| i |
        pv1 pv2 compare-priority-vectors drop
    ] each-integer
    nano-count :> t3
    t3 t2 - >float 1e-9 * :> dca-elapsed
    dca-iters >float dca-elapsed / :> dca-ops-per-sec
    dca-elapsed dca-iters >float / 1e9 * :> dca-ns-per-op

    dca-iters "[2] BMCA Dataset Comparison (DCA) (%d iterations):\n" printf
    dca-ops-per-sec 1000.0 / dca-ns-per-op
    "    Throughput: %.2f K comparisons/sec | Latency: %.2f ns/eval\n\n" printf

    ! 3. Benchmark Discrete Kalman Filter Iterations
    default-kalman-servo :> kf
    100000 :> kf-iters
    nano-count :> t4
    kf-iters [| i |
        15.0 0.125 kf kalman-servo-step drop
    ] each-integer
    nano-count :> t5
    t5 t4 - >float 1e-9 * :> kf-elapsed
    kf-iters >float kf-elapsed / :> kf-ops-per-sec
    kf-elapsed kf-iters >float / 1e9 * :> kf-ns-per-op

    kf-iters "[3] 2-State Kalman Filter Loop (%d steps):\n" printf
    kf-ops-per-sec 1000.0 / kf-ns-per-op
    "    Throughput: %.2f K steps/sec | Latency: %.2f ns/step\n\n" printf

    ! 4. Benchmark Allan Deviation over 1,000 Points
    1000 f <array> :> xs
    1000 [| i | i >float 0.05 * sin i xs set-nth ] each-integer
    50 :> avar-iters
    nano-count :> t6
    avar-iters [| i |
        xs 0.1 compute-stability-curve drop
    ] each-integer
    nano-count :> t7
    t7 t6 - >float 1e-9 * :> avar-elapsed

    avar-iters "[4] Multi-Tau Stability Curve (%d evaluations of 1,000 samples):\n" printf
    avar-elapsed avar-elapsed avar-iters >float / 1000.0 *
    "    Elapsed Time: %.4f s | Latency: %.2f ms/curve\n\n" printf

    "All Factor microbenchmarks completed successfully." print
    "================================================================================" print ;
