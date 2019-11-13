! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Boundary Clock (BC) multi-port coordination and downstream master dissemination.

USING: accessors arrays kernel locals math sequences
escapement.common.constants escapement.common.types
escapement.protocol.messages.announce
escapement.state.engine-state escapement.state.port-state ;
IN: escapement.boundary.boundary-clock

TUPLE: boundary-clock-coordinator
    { engine engine-state }
    { slave-port-idx integer initial: -1 } ;

:: <boundary-clock-coordinator> ( engine -- bc )
    engine -1 boundary-clock-coordinator boa ;

! Identify current slave port in the boundary clock
:: bc-find-slave-port ( bc -- slave-idx )
    -1 :> found-idx!
    bc engine>> ports>> [| port idx |
        port port-state>> PORT-STATE-SLAVE = [
            idx found-idx!
        ] when
    ] each-index
    bc found-idx >>slave-port-idx drop
    found-idx ;

! Synthesize outbound Announce message for a downstream master port
:: bc-synthesize-downstream-announce ( bc master-port-idx ts seq-id -- ann-msg )
    bc engine>> default-ds>> :> dds
    bc engine>> parent-ds>> :> pds
    bc engine>> current-ds>> :> cds
    bc engine>> ports>> master-port-idx nth :> port

    dds domain-number>> :> dom
    0 :> flags ! One-step or standard flags
    port port-id>> :> pid

    pds grandmaster-priority1>> :> pri1
    pds grandmaster-quality>> :> qual
    pds grandmaster-priority2>> :> pri2
    pds grandmaster-id>> :> gm-id
    cds steps-removed>> 1 + :> steps
    dds quality>> clock-class>> :> src

    dom flags pid seq-id ts 37 pri1 qual pri2 gm-id steps src <ptp-announce> ;
