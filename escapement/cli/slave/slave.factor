! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Slave CLI command: runs an ordinary clock slave node with active servo.

USING: accessors byte-arrays formatting io kernel locals math
math.parser sequences strings escapement.clock.synthetic
escapement.common.constants escapement.common.types
escapement.server.event-loop escapement.state.datasets
escapement.state.engine-state escapement.state.port-state ;
IN: escapement.cli.slave

:: run-slave-cli ( domain-str -- )
    domain-str [ string>number ] [ 0 ] if* :> domain
    "================================================================================" print
    "                   ESCAPEMENT IEEE 1588-2019 SLAVE CLOCK                        " print
    "================================================================================" print
    { 0x00 0x1A 0x2B 0xFF 0xFE 0x44 0x55 0x66 } >byte-array <clock-identity> :> slave-cid
    slave-cid domain 1 DELAY-MECH-E2E <engine-state> :> engine

    ! Configure as Slave-Only Ordinary Clock: Priority1=255, Class=255
    engine default-ds>> 255 >>priority1 drop
    engine default-ds>> quality>> 255 >>clock-class drop
    engine default-ds>> t >>slave-only drop
    engine ports>> first PORT-STATE-LISTENING >>port-state drop

    "Slave Clock Initialized:" print
    slave-cid clock-identity>string "  Clock Identity:    %s\n" printf
    domain "  PTP Domain:        %d\n" printf
    "  Clock Class:       255 (Slave-Only Ordinary Clock)" print
    "  Port 1 State:      LISTENING (Awaiting Announce from Grandmaster)" print
    "  Delay Mechanism:   End-to-End (E2E)" print
    "  Active Servo:      2-State Discrete Kalman Filter (Phase & Freq Drift)" print
    "================================================================================" print
    "Listening for Grandmaster synchronization on UDP ports 319/320." print ;
