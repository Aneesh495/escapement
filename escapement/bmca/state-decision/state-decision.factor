! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! State Decision Algorithm (SDA) per IEEE 1588-2019 Clause 9.3.3.

USING: accessors arrays assocs kernel locals math sequences
escapement.bmca.dataset-comparison escapement.bmca.priority-vector
escapement.common.constants escapement.common.types ;
IN: escapement.bmca.state-decision

CONSTANT: DECISION-M1 1 ! Master by self superiority
CONSTANT: DECISION-M2 2 ! Master on port
CONSTANT: DECISION-M3 3 ! Master reserved
CONSTANT: DECISION-S1 4 ! Slave to best master
CONSTANT: DECISION-P1 5 ! Passive port
CONSTANT: DECISION-P2 6 ! Passive backup

: decision>string ( dec -- str )
    {
        { DECISION-M1 "M1 (Master)" }
        { DECISION-M2 "M2 (Master)" }
        { DECISION-M3 "M3 (Master)" }
        { DECISION-S1 "S1 (Slave)" }
        { DECISION-P1 "P1 (Passive)" }
        { DECISION-P2 "P2 (Passive)" }
    } ?at [ "UNKNOWN" ] unless ;

! Given system priority vector d0 and array of port best foreign vectors erbest:
! Computes Ebest (the best overall vector across all ports and d0)
:: compute-ebest ( d0 erbest-array -- ebest best-port-idx )
    d0 :> best-vec!
    -1 :> best-idx!
    erbest-array [| vec idx |
        vec [
            vec best-vec vector-better? [
                vec best-vec!
                idx best-idx!
            ] when
        ] when
    ] each-index
    best-vec best-idx ;

! Evaluate State Decision Algorithm for a specific port
! d0: system priority vector
! ebest: overall best priority vector across all ports and d0
! erbest-r: best vector on this port r (or f if none received)
! port-idx: index of this port
! best-port-idx: index of port that received ebest (-1 if d0 was best)
:: evaluate-state-decision ( d0 ebest erbest-r port-idx best-port-idx -- decision )
    erbest-r [
        ! Port received foreign announce messages
        best-port-idx port-idx = [
            ! This port received the globally best master vector Ebest
            d0 ebest vector-better? [
                DECISION-M1
            ] [
                DECISION-S1
            ] if
        ] [
            ! Another port received Ebest, or d0 was best
            d0 ebest vector-better? [
                DECISION-M1
            ] [
                ! This port did not receive Ebest; compare erbest-r against d0
                erbest-r d0 vector-better? [
                    DECISION-P1
                ] [
                    DECISION-M2
                ] if
            ] if
        ] if
    ] [
        ! No foreign master vectors on this port
        d0 ebest vector-better? [
            DECISION-M1
        ] [
            DECISION-M2
        ] if
    ] if ;
