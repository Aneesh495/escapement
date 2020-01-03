! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Serve CLI command: launches HTTP REST and Prometheus telemetry server.

USING: accessors byte-arrays formatting io kernel locals math
math.parser sequences strings escapement.common.constants
escapement.common.types escapement.state.engine-state
escapement.telemetry.http-server ;
IN: escapement.cli.serve

:: run-serve-cli ( port-str -- )
    port-str [ string>number ] [ 8080 ] if* :> port
    "================================================================================" print
    "                   ESCAPEMENT TELEMETRY & METRICS SERVER                        " print
    "================================================================================" print
    { 0x08 0x00 0x27 0xFF 0xFE 0x99 0x88 0x77 } >byte-array <clock-identity> :> cid
    cid 0 1 DELAY-MECH-E2E <engine-state> :> engine
    engine 12.3 >>clock-offset-ns drop
    engine 4.5 >>frequency-drift-ppb drop

    engine port <telemetry-server> :> srv
    "Server Endpoints:" print
    port "  JSON Status:       http://localhost:%d/api/v1/status\n" printf
    port "  Prometheus:        http://localhost:%d/metrics\n" printf
    "================================================================================" print
    srv start-telemetry-server ;
