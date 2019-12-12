! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Integration tests: multi-clock synchronization loop and grandmaster failover.

USING: accessors arrays byte-arrays io kernel locals math
math.functions sequences escapement.bmca.dataset-comparison
escapement.bmca.priority-vector escapement.clock.synthetic
escapement.common.constants escapement.common.types
escapement.network.impairment escapement.servo.kalman
escapement.state.datasets escapement.state.engine-state
escapement.state.port-state escapement.timing.delay
escapement.timing.timestamps ;
IN: escapement.tests.integration

:: run-integration-tests ( -- )
    "--- Running Multi-Node System Integration Tests ---" print

    ! 1. End-to-End Clock Synchronization Convergence Test
    0.0 0.0 <synthetic-clock> :> master-clk
    1000.0 20.0 <synthetic-clock> :> slave-clk
    default-kalman-servo :> kf
    50000.0 50000.0 100.0 0.0 0.0 0.0 <impairment-channel> :> chan

    0.125 :> dt
    50 [| epoch |
        dt master-clk clock-advance
        dt slave-clk clock-advance

        master-clk clock-read-timestamp :> t1
        chan channel-forward-delay drop :> fwd-delay
        slave-clk current-time-ns>> fwd-delay + floor >integer nanoseconds>timestamp :> t2

        slave-clk clock-read-timestamp :> t3
        chan channel-reverse-delay drop :> rev-delay
        master-clk current-time-ns>> rev-delay + floor >integer nanoseconds>timestamp :> t4

        t1 t2 t3 t4 0 0 compute-e2e-delay-and-offset :> ( delay offset )
        offset dt kf kalman-servo-step :> adj
        adj slave-clk clock-adjust-freq

        ! If initial offset is large on first epoch, step clock phase
        epoch 0 = offset abs 500.0 > and [
            offset neg slave-clk clock-step-phase
        ] when
    ] each-integer

    kf phase-est>> abs 100.0 <
    [ "pass: end-to-end synchronization converges within 100 ns" print ]
    [ "fail: synchronization convergence" throw ] if

    ! 2. Grandmaster Failover Test
    { 1 2 3 4 5 6 7 8 } >byte-array <clock-identity> :> self-cid
    self-cid 0 1 DELAY-MECH-E2E <engine-state> :> slave-engine
    PORT-STATE-INITIALIZING EV-INITIALIZE 0 transition-port-state :> ps-init
    slave-engine ports>> first ps-init >>port-state drop

    ! Receive superior master announcement
    { 0 0 0 0 0 0 0 1 } >byte-array <clock-identity> :> gm-cid
    128 6 0x20 0x1000 128 gm-cid 0 gm-cid 1 <port-identity> 1 <priority-vector> :> gm-pv
    slave-engine 0 gm-pv handle-foreign-announce
    slave-engine ports>> first port-state>> PORT-STATE-UNCALIBRATED =
    [ "pass: slave recognizes foreign master" print ] [ "fail: uncalibrated" throw ] if

    ! Simulate Announce Receipt Timeout when GM goes offline
    slave-engine ports>> first port-state>> EV-ANNOUNCE-RECEIPT-TIMEOUT 0 transition-port-state :> ps-failover
    slave-engine ports>> first ps-failover >>port-state drop
    slave-engine ports>> first port-state>> PORT-STATE-MASTER =
    [ "pass: failover to MASTER state on announce timeout" print ] [ "fail: failover" throw ] if

    "All Multi-Node System Integration tests passed successfully." print ;
