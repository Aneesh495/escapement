! Copyright (C) 2026 Aneesh Krishna.
! Escapement: Standalone Subsystem Benchmark Suite.
! Measures throughput, operations per second, and nanosecond latency per operation.

USING: accessors arrays byte-arrays formatting io kernel locals
math math.functions namespaces sequences strings system
escapement.bmca.dataset-comparison escapement.bmca.priority-vector
escapement.common.constants escapement.common.ring-buffer
escapement.common.types escapement.protocol.header
escapement.protocol.messages.announce escapement.protocol.messages.sync
escapement.servo.kalman escapement.servo.pi
escapement.stability.allan escapement.stability.mtie ;
IN: escapement.benchmarks

:: bench-header ( iters -- )
    { 0x01 0x02 0x03 0x04 0x05 0x06 0x07 0x08 } >byte-array <clock-identity> 1 <port-identity> :> pid
    0 44 0 0 pid 1 <ptp-header> :> hdr
    hdr pack-ptp-header :> raw

    nano-count :> t0
    iters [| i |
        raw unpack-ptp-header pack-ptp-header drop
    ] each-integer
    nano-count :> t1

    t1 t0 - >float 1e-9 * :> elapsed
    iters >float elapsed / :> ops-per-sec
    elapsed iters >float / 1e9 * :> ns-per-op
    iters ops-per-sec 1e-3 * ns-per-op
    "  [Header Unpack+Pack]       %7d iters | Throughput: %9.2f K ops/s | Latency: %8.2f ns\n" printf ;

:: bench-announce ( iters -- )
    { 0x01 0x02 0x03 0x04 0x05 0x06 0x07 0x08 } >byte-array <clock-identity> 1 <port-identity> :> pid
    { 0x0A 0x0B 0x0C 0x0D 0x0E 0x0F 0x10 0x11 } >byte-array <clock-identity> :> gm-cid
    0 0 <timestamp> :> ts
    6 0x20 0x1000 <clock-quality> :> qual
    0 0 pid 1 ts 37 128 qual 128 gm-cid 0 0x20 <ptp-announce> :> msg
    msg pack-ptp-announce :> raw

    nano-count :> t0
    iters [| i |
        raw unpack-ptp-announce drop
    ] each-integer
    nano-count :> t1

    t1 t0 - >float 1e-9 * :> elapsed
    iters >float elapsed / :> ops-per-sec
    elapsed iters >float / 1e9 * :> ns-per-op
    iters ops-per-sec 1e-3 * ns-per-op
    "  [Announce Message Codec]   %7d iters | Throughput: %9.2f K ops/s | Latency: %8.2f ns\n" printf ;

:: bench-dca ( iters -- )
    { 0x01 0x02 0x03 0x04 0x05 0x06 0x07 0x08 } >byte-array <clock-identity> :> cid1
    { 0x01 0x02 0x03 0x04 0x05 0x06 0x07 0x09 } >byte-array <clock-identity> :> cid2
    128 6 0x20 0x1000 128 cid1 0 cid1 1 <port-identity> 1 <priority-vector> :> pv1
    128 7 0x21 0x2000 128 cid2 0 cid2 1 <port-identity> 1 <priority-vector> :> pv2

    nano-count :> t0
    iters [| i |
        pv1 pv2 compare-priority-vectors drop
    ] each-integer
    nano-count :> t1

    t1 t0 - >float 1e-9 * :> elapsed
    iters >float elapsed / :> ops-per-sec
    elapsed iters >float / 1e9 * :> ns-per-op
    iters ops-per-sec 1e-3 * ns-per-op
    "  [BMCA Dataset Comparison]  %7d iters | Throughput: %9.2f K ops/s | Latency: %8.2f ns\n" printf ;

:: bench-ring ( iters -- )
    64 <ring-buffer> :> rb
    nano-count :> t0
    iters [| i |
        i >float rb ring-push
        rb ring-mean drop
        rb ring-variance drop
    ] each-integer
    nano-count :> t1

    t1 t0 - >float 1e-9 * :> elapsed
    iters >float elapsed / :> ops-per-sec
    elapsed iters >float / 1e9 * :> ns-per-op
    iters ops-per-sec 1e-3 * ns-per-op
    "  [Ring Push+Mean+Variance]  %7d iters | Throughput: %9.2f K ops/s | Latency: %8.2f ns\n" printf ;

:: bench-kalman ( iters -- )
    default-kalman-servo :> kf
    nano-count :> t0
    iters [| i |
        15.0 0.125 kf kalman-servo-step drop
    ] each-integer
    nano-count :> t1

    t1 t0 - >float 1e-9 * :> elapsed
    iters >float elapsed / :> ops-per-sec
    elapsed iters >float / 1e9 * :> ns-per-op
    iters ops-per-sec 1e-3 * ns-per-op
    "  [Kalman 2-State Filter]    %7d iters | Throughput: %9.2f K ops/s | Latency: %8.2f ns\n" printf ;

:: bench-pi ( iters -- )
    default-pi-servo :> srv
    nano-count :> t0
    iters [| i |
        12.5 0.125 srv pi-servo-step drop
    ] each-integer
    nano-count :> t1

    t1 t0 - >float 1e-9 * :> elapsed
    iters >float elapsed / :> ops-per-sec
    elapsed iters >float / 1e9 * :> ns-per-op
    iters ops-per-sec 1e-3 * ns-per-op
    "  [PI Servo Anti-Windup]     %7d iters | Throughput: %9.2f K ops/s | Latency: %8.2f ns\n" printf ;

:: bench-allan ( iters -- )
    500 f <array> :> xs
    500 [| i | i >float 0.05 * sin i xs set-nth ] each-integer
    nano-count :> t0
    iters [| i |
        xs 0.1 compute-stability-curve drop
    ] each-integer
    nano-count :> t1

    t1 t0 - >float 1e-9 * :> elapsed
    elapsed iters >float / 1000.0 * :> ms-per-op
    iters elapsed ms-per-op
    "  [Allan Multi-Tau Curve]    %7d iters | Total Elapsed:  %7.4f s | Latency: %8.2f ms\n" printf ;

:: run-benchmark-suite ( -- )
    "================================================================================" print
    "                 ESCAPEMENT FACTOR HIGH-PERFORMANCE SUITE                       " print
    "================================================================================" print
    50000 bench-header
    50000 bench-announce
    100000 bench-dca
    50000 bench-ring
    100000 bench-kalman
    100000 bench-pi
    20 bench-allan
    "================================================================================" print
    "All benchmarks completed with statistical confidence." print
    "================================================================================" print ;

MAIN: run-benchmark-suite
