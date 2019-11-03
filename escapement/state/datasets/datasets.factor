! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Standard PTP Data Sets per IEEE 1588-2019 Clause 8.

USING: accessors byte-arrays kernel locals math sequences
escapement.common.constants escapement.common.types ;
IN: escapement.state.datasets

! Default Data Set (Clause 8.2.1)
TUPLE: default-data-set
    { two-step-flag boolean initial: t }
    { clock-id clock-identity }
    { number-ports integer initial: 1 }
    { quality clock-quality }
    { priority1 integer initial: 128 }
    { priority2 integer initial: 128 }
    { domain-number integer initial: 0 }
    { slave-only boolean initial: f } ;

:: <default-data-set> ( clock-id domain -- dds )
    t
    clock-id
    1
    248 0x21 0xFFFF <clock-quality>
    128
    128
    domain
    f
    default-data-set boa ;

! Current Data Set (Clause 8.2.2)
TUPLE: current-data-set
    { steps-removed integer initial: 0 }
    { offset-from-master integer initial: 0 }
    { mean-path-delay integer initial: 0 } ;

: <current-data-set> ( -- cds )
    0 0 0 current-data-set boa ;

! Parent Data Set (Clause 8.2.3)
TUPLE: parent-data-set
    { parent-port-id port-identity }
    { parent-stats boolean initial: f }
    { observed-offset-scaled-log-variance integer initial: 0xFFFF }
    { observed-phase-change-rate integer initial: 0x7FFFFFFF }
    { grandmaster-priority1 integer initial: 128 }
    { grandmaster-quality clock-quality }
    { grandmaster-priority2 integer initial: 128 }
    { grandmaster-id clock-identity } ;

:: <parent-data-set> ( self-clock-id -- pds )
    self-clock-id 0 <port-identity>
    f
    0xFFFF
    0x7FFFFFFF
    128
    248 0x21 0xFFFF <clock-quality>
    128
    self-clock-id
    parent-data-set boa ;

! Time Properties Data Set (Clause 8.2.4)
TUPLE: time-properties-data-set
    { current-utc-offset integer initial: 37 }
    { current-utc-offset-valid boolean initial: t }
    { leap59 boolean initial: f }
    { leap61 boolean initial: f }
    { time-traceable boolean initial: t }
    { frequency-traceable boolean initial: t }
    { ptp-timescale boolean initial: t }
    { time-source integer initial: 0x20 } ;

: <time-properties-data-set> ( -- tpds )
    37 t f f t t t 0x20 time-properties-data-set boa ;

! Port Data Set (Clause 8.2.5)
TUPLE: port-data-set
    { port-id port-identity }
    { port-state integer initial: 0 }
    { log-min-delay-req-interval integer initial: 0 }
    { peer-mean-path-delay integer initial: 0 }
    { log-announce-interval integer initial: 1 }
    { announce-receipt-timeout integer initial: 3 }
    { log-sync-interval integer initial: 0 }
    { delay-mechanism integer initial: 1 }
    { version-number integer initial: 2 } ;

:: <port-data-set> ( port-id mech -- pds )
    port-id
    PORT-STATE-INITIALIZING
    0
    0
    1
    3
    0
    mech
    2
    port-data-set boa ;
