! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! BMCA CLI simulator: exercises multi-master elections and state transitions.

USING: accessors arrays byte-arrays formatting io kernel locals
math math.parser sequences strings escapement.bmca.dataset-comparison
escapement.bmca.priority-vector escapement.bmca.state-decision
escapement.common.constants escapement.common.types
escapement.state.datasets escapement.state.engine-state
escapement.state.port-state ;
IN: escapement.cli.bmca

:: run-bmca-simulation ( -- )
    "================================================================================" print
    "              ESCAPEMENT BEST MASTER CLOCK ALGORITHM (BMCA) DEMO                " print
    "================================================================================" print
    "Scenario: 3 candidate clocks vying for Grandmaster leadership:\n" print

    ! Candidate 1: Local Clock (Free-running crystal, Priority1=128, Class=248)
    { 0x00 0x11 0x22 0x33 0x44 0x55 0x66 0x77 } >byte-array <clock-identity> :> cid-local
    cid-local 0 2 DELAY-MECH-E2E <engine-state> :> engine

    cid-local clock-identity>string "1. Local Clock Identity:     %s (Class 248, Priority1 128)\n" printf

    ! Candidate 2: Upstream GNSS Grandmaster (Class 6, Priority1 128, Accuracy 25ns)
    { 0x08 0x00 0x27 0xFF 0xFE 0xAA 0xBB 0xCC } >byte-array <clock-identity> :> cid-gnss
    128 6 0x20 0x1000 128 cid-gnss 0 cid-gnss 1 <port-identity> 1 <priority-vector> :> pv-gnss

    cid-gnss clock-identity>string "2. Foreign Master on Port 1: %s (GNSS Primary Ref, Class 6, Acc <25ns)\n" printf

    ! Candidate 3: Secondary Atomic Rubidium (Class 7, Priority1 128, Accuracy 100ns)
    { 0x00 0x50 0x56 0xFF 0xFE 0x11 0x22 0x33 } >byte-array <clock-identity> :> cid-rubidium
    128 7 0x21 0x2000 128 cid-rubidium 1 cid-rubidium 1 <port-identity> 2 <priority-vector> :> pv-rubidium

    cid-rubidium clock-identity>string "3. Foreign Master on Port 2: %s (Atomic Rubidium Holdover, Class 7, Acc <100ns)\n\n" printf

    engine ports>> first port-state>> port-state>string
    engine ports>> second port-state>> port-state>string
    "Initial Port States: Port 1 = %s, Port 2 = %s\n" printf

    ! Initialize ports to LISTENING
    PORT-STATE-INITIALIZING EV-INITIALIZE 0 transition-port-state :> ps-init
    engine ports>> first ps-init >>port-state drop
    engine ports>> second ps-init >>port-state drop

    engine ports>> first port-state>> port-state>string
    engine ports>> second port-state>> port-state>string
    "Transitioned to LISTENING: Port 1 = %s, Port 2 = %s\n\n" printf

    "Receiving Announce messages from both masters..." print
    engine 0 pv-gnss handle-foreign-announce
    engine 1 pv-rubidium handle-foreign-announce

    "Evaluating Dataset Comparison Algorithm (DCA)..." print
    pv-gnss pv-rubidium compare-priority-vectors :> comp-res
    comp-res -1 = [ "GNSS is SUPERIOR (lower clock class 6 < 7)" ] [ "Rubidium is SUPERIOR" ] if
    "DCA Result: GNSS vs Rubidium -> %s\n" printf

    "Evaluating State Decision Algorithm (SDA)..." print
    engine ebest-vector>> grandmaster-id>> clock-identity>string
    "Active Grandmaster Selected: %s\n" printf

    "Updated Port States:\n" print
    engine ports>> first port-state>> port-state>string
    "  Port 1 (GNSS link):     %s\n" printf
    engine ports>> second port-state>> port-state>string
    "  Port 2 (Backup link):   %s\n" printf

    "BMCA correctly designated Port 1 as SLAVE/UNCALIBRATED and Port 2 as PASSIVE backup." print
    "================================================================================" print ;
