! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Unit and conformance tests for BMCA DCA and SDA state logic.

USING: accessors arrays byte-arrays io kernel locals math
sequences escapement.bmca.dataset-comparison
escapement.bmca.priority-vector escapement.bmca.state-decision
escapement.common.constants escapement.common.types
escapement.state.datasets escapement.state.engine-state
escapement.state.port-state ;
IN: escapement.tests.bmca

:: run-bmca-tests ( -- )
    "--- Running BMCA & State Machine Conformance Tests ---" print

    { 1 1 1 1 1 1 1 1 } >byte-array <clock-identity> :> cid1
    { 2 2 2 2 2 2 2 2 } >byte-array <clock-identity> :> cid2

    ! Test 1: Priority 1 comparison
    100 248 0xFE 0xFFFF 128 cid1 0 cid1 1 <port-identity> 1 <priority-vector> :> pv-p1-low
    128 248 0xFE 0xFFFF 128 cid2 0 cid2 1 <port-identity> 1 <priority-vector> :> pv-p1-high
    pv-p1-low pv-p1-high vector-better? [ "pass: priority1 comparison" print ] [ "fail: priority1" throw ] if

    ! Test 2: Clock Class comparison
    128 6 0x20 0x1000 128 cid1 0 cid1 1 <port-identity> 1 <priority-vector> :> pv-class6
    128 7 0x20 0x1000 128 cid2 0 cid2 1 <port-identity> 1 <priority-vector> :> pv-class7
    pv-class6 pv-class7 vector-better? [ "pass: clock-class comparison" print ] [ "fail: clock-class" throw ] if

    ! Test 3: Clock Accuracy comparison
    128 248 0x20 0xFFFF 128 cid1 0 cid1 1 <port-identity> 1 <priority-vector> :> pv-acc25ns
    128 248 0x25 0xFFFF 128 cid2 0 cid2 1 <port-identity> 1 <priority-vector> :> pv-acc10us
    pv-acc25ns pv-acc10us vector-better? [ "pass: clock-accuracy comparison" print ] [ "fail: clock-accuracy" throw ] if

    ! Test 4: Clock Identity tie-breaker
    128 248 0xFE 0xFFFF 128 cid1 0 cid1 1 <port-identity> 1 <priority-vector> :> pv-cid1
    128 248 0xFE 0xFFFF 128 cid2 0 cid2 1 <port-identity> 1 <priority-vector> :> pv-cid2
    pv-cid1 pv-cid2 vector-better? [ "pass: clock-id tiebreaker" print ] [ "fail: clock-id" throw ] if

    ! Test 5: Steps removed comparison when same GM
    128 6 0x20 0x1000 128 cid1 1 cid1 1 <port-identity> 1 <priority-vector> :> pv-step1
    128 6 0x20 0x1000 128 cid1 3 cid2 1 <port-identity> 1 <priority-vector> :> pv-step3
    pv-step1 pv-step3 vector-better? [ "pass: steps-removed comparison" print ] [ "fail: steps-removed" throw ] if

    ! Test 5b: Priority 2 tiebreaker comparison
    128 6 0x20 0x1000 100 cid1 0 cid1 1 <port-identity> 1 <priority-vector> :> pv-p2-low
    128 6 0x20 0x1000 200 cid1 0 cid1 1 <port-identity> 1 <priority-vector> :> pv-p2-high
    pv-p2-low pv-p2-high vector-better? [ "pass: priority2 tiebreaker" print ] [ "fail: priority2" throw ] if

    ! Test 6: State transition from INITIALIZING -> LISTENING -> MASTER on timeout
    PORT-STATE-INITIALIZING EV-INITIALIZE 0 transition-port-state :> ps1
    ps1 PORT-STATE-LISTENING = [ "pass: transition to listening" print ] [ "fail: listening" throw ] if

    ps1 EV-ANNOUNCE-RECEIPT-TIMEOUT 0 transition-port-state :> ps2
    ps2 PORT-STATE-MASTER = [ "pass: announce timeout to master" print ] [ "fail: master timeout" throw ] if

    ! Test 7: State transition from LISTENING -> UNCALIBRATED -> SLAVE
    ps1 EV-STATE-DECISION DECISION-S1 transition-port-state :> ps3
    ps3 PORT-STATE-UNCALIBRATED = [ "pass: listening to uncalibrated" print ] [ "fail: uncalibrated transition" throw ] if

    ps3 EV-SYNCHRONIZATION-ACHIEVED 0 transition-port-state :> ps4
    ps4 PORT-STATE-SLAVE = [ "pass: uncalibrated to slave" print ] [ "fail: slave transition" throw ] if

    "All BMCA & State Machine conformance tests passed successfully." print ;
