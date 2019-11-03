! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Unified engine state context, port coordination, and BMCA triggers.

USING: accessors arrays byte-arrays kernel locals math sequences
escapement.bmca.dataset-comparison escapement.bmca.priority-vector
escapement.bmca.state-decision escapement.common.constants
escapement.common.types escapement.state.datasets
escapement.state.port-state ;
IN: escapement.state.engine-state

TUPLE: engine-state
    { default-ds default-data-set }
    { current-ds current-data-set }
    { parent-ds parent-data-set }
    { time-properties-ds time-properties-data-set }
    { ports array }                ! Array of port-data-set
    { erbest-vectors array }       ! Array of priority-vector (one per port)
    { ebest-vector priority-vector }
    { clock-offset-ns float initial: 0.0 }
    { frequency-drift-ppb float initial: 0.0 } ;

:: <engine-state> ( clock-id domain num-ports delay-mech -- st )
    clock-id domain <default-data-set> :> dds
    <current-data-set> :> cds
    clock-id <parent-data-set> :> pds
    <time-properties-data-set> :> tpds

    V{ } clone :> ports-arr
    num-ports [| i |
        clock-id i 1 + <port-identity> delay-mech <port-data-set> ports-arr push
    ] each-integer

    num-ports f <array> :> erbest-arr

    128 248 0x21 0xFFFF 128 clock-id <system-priority-vector> :> d0

    dds cds pds tpds ports-arr >array erbest-arr d0 0.0 0.0 engine-state boa ;

! Trigger BMCA re-evaluation across all ports in engine
:: run-engine-bmca ( st -- )
    st default-ds>> :> dds
    dds priority1>>
    dds quality>> clock-class>>
    dds quality>> clock-accuracy>>
    dds quality>> offset-scaled-log-variance>>
    dds priority2>>
    dds clock-id>>
    <system-priority-vector> :> d0

    d0 st erbest-vectors>> compute-ebest :> ( ebest best-idx )
    st ebest >>ebest-vector drop

    st ports>> [| port idx |
        idx st erbest-vectors>> nth :> erbest-r
        d0 ebest erbest-r idx best-idx evaluate-state-decision :> dec
        port port-state>> EV-STATE-DECISION dec transition-port-state :> new-ps
        port new-ps >>port-state drop
    ] each-index ;

! Register foreign master announcement on a port
:: handle-foreign-announce ( st port-idx pv -- )
    st erbest-vectors>> :> er-vecs
    port-idx er-vecs nth :> curr-best
    curr-best [
        pv curr-best vector-better? [
            pv port-idx er-vecs set-nth
            st run-engine-bmca
        ] when
    ] [
        pv port-idx er-vecs set-nth
        st run-engine-bmca
    ] if ;
