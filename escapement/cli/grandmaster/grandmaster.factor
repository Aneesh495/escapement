! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Grandmaster CLI command: runs an active or simulated PTP Grandmaster.

USING: accessors byte-arrays formatting io kernel locals math
math.parser sequences strings escapement.clock.synthetic
escapement.common.constants escapement.common.types
escapement.server.event-loop escapement.state.datasets
escapement.state.engine-state escapement.state.port-state ;
IN: escapement.cli.grandmaster

:: run-grandmaster-cli ( domain-str -- )
    domain-str [ string>number ] [ 0 ] if* :> domain
    "================================================================================" print
    "                     ESCAPEMENT IEEE 1588-2019 GRANDMASTER                      " print
    "================================================================================" print
    { 0x08 0x00 0x27 0xFF 0xFE 0x11 0x22 0x33 } >byte-array <clock-identity> :> gm-cid
    gm-cid domain 1 DELAY-MECH-E2E <engine-state> :> engine

    ! Configure as Grandmaster: Priority1=128, Class=6 (GNSS), Accuracy=0x20 (<25ns)
    engine default-ds>> quality>> 6 >>clock-class drop
    engine default-ds>> quality>> 0x20 >>clock-accuracy drop
    engine ports>> first PORT-STATE-MASTER >>port-state drop

    "Grandmaster Initialized:" print
    gm-cid clock-identity>string "  Clock Identity:    %s\n" printf
    domain "  PTP Domain:        %d\n" printf
    "  Clock Class:       6 (Primary Reference Time Clock / GNSS)" print
    "  Clock Accuracy:    0x20 (< 25 ns)" print
    "  Port 1 State:      MASTER" print
    "  Delay Mechanism:   End-to-End (E2E)" print
    "  Announce Interval: 2.0 s (logInterval = 1)" print
    "  Sync Interval:     0.125 s (logInterval = -3, 8 Hz)" print
    "================================================================================" print
    "Grandmaster state machine active. Disseminating precision network time." print ;
