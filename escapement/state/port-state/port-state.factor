! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Port state machine and transition table per IEEE 1588 Clause 9.2.

USING: accessors assocs combinators kernel locals math
escapement.bmca.state-decision escapement.common.types ;
IN: escapement.state.port-state

CONSTANT: EV-POWERUP                    1
CONSTANT: EV-INITIALIZE                 2
CONSTANT: EV-FAULT-DETECTED             3
CONSTANT: EV-FAULT-CLEARED              4
CONSTANT: EV-DESIGNATED-ENABLED         5
CONSTANT: EV-DESIGNATED-DISABLED        6
CONSTANT: EV-ANNOUNCE-RECEIPT-TIMEOUT   7
CONSTANT: EV-QUALIFICATION-TIMEOUT      8
CONSTANT: EV-STATE-DECISION             9
CONSTANT: EV-SYNCHRONIZATION-FAULT      10
CONSTANT: EV-SYNCHRONIZATION-ACHIEVED   11

: event>string ( ev -- str )
    {
        { 1 "POWERUP" }
        { 2 "INITIALIZE" }
        { 3 "FAULT_DETECTED" }
        { 4 "FAULT_CLEARED" }
        { 5 "DESIGNATED_ENABLED" }
        { 6 "DESIGNATED_DISABLED" }
        { 7 "ANNOUNCE_RECEIPT_TIMEOUT" }
        { 8 "QUALIFICATION_TIMEOUT" }
        { 9 "STATE_DECISION" }
        { 10 "SYNCHRONIZATION_FAULT" }
        { 11 "SYNCHRONIZATION_ACHIEVED" }
    } ?at [ "UNKNOWN_EVENT" ] unless ;

:: sda>listening-transition ( dec -- next-state )
    dec {
        { DECISION-M1 [ PORT-STATE-PRE-MASTER ] }
        { DECISION-M2 [ PORT-STATE-PRE-MASTER ] }
        { DECISION-S1 [ PORT-STATE-UNCALIBRATED ] }
        { DECISION-P1 [ PORT-STATE-PASSIVE ] }
        { DECISION-P2 [ PORT-STATE-PASSIVE ] }
        [ drop PORT-STATE-LISTENING ]
    } case ;

:: sda>pre-master-transition ( dec -- next-state )
    dec {
        { DECISION-S1 [ PORT-STATE-UNCALIBRATED ] }
        { DECISION-P1 [ PORT-STATE-PASSIVE ] }
        { DECISION-P2 [ PORT-STATE-PASSIVE ] }
        [ drop PORT-STATE-PRE-MASTER ]
    } case ;

:: sda>master-transition ( dec -- next-state )
    dec {
        { DECISION-S1 [ PORT-STATE-UNCALIBRATED ] }
        { DECISION-P1 [ PORT-STATE-PASSIVE ] }
        { DECISION-P2 [ PORT-STATE-PASSIVE ] }
        [ drop PORT-STATE-MASTER ]
    } case ;

:: sda>passive-transition ( dec -- next-state )
    dec {
        { DECISION-M1 [ PORT-STATE-PRE-MASTER ] }
        { DECISION-M2 [ PORT-STATE-PRE-MASTER ] }
        { DECISION-S1 [ PORT-STATE-UNCALIBRATED ] }
        [ drop PORT-STATE-PASSIVE ]
    } case ;

:: sda>uncalibrated-transition ( dec -- next-state )
    dec {
        { DECISION-M1 [ PORT-STATE-PRE-MASTER ] }
        { DECISION-M2 [ PORT-STATE-PRE-MASTER ] }
        { DECISION-P1 [ PORT-STATE-PASSIVE ] }
        { DECISION-P2 [ PORT-STATE-PASSIVE ] }
        [ drop PORT-STATE-UNCALIBRATED ]
    } case ;

:: sda>slave-transition ( dec -- next-state )
    dec {
        { DECISION-M1 [ PORT-STATE-PRE-MASTER ] }
        { DECISION-M2 [ PORT-STATE-PRE-MASTER ] }
        { DECISION-P1 [ PORT-STATE-PASSIVE ] }
        { DECISION-P2 [ PORT-STATE-PASSIVE ] }
        [ drop PORT-STATE-SLAVE ]
    } case ;

! Transition port state given current state, event, and optional SDA decision
:: transition-port-state ( current-state event decision -- next-state )
    event EV-FAULT-DETECTED = [
        PORT-STATE-FAULTY
    ] [
        event EV-DESIGNATED-DISABLED = [
            PORT-STATE-DISABLED
        ] [
            current-state {
                ! 1. INITIALIZING State
                { PORT-STATE-INITIALIZING [
                    event EV-INITIALIZE = [ PORT-STATE-LISTENING ] [ PORT-STATE-INITIALIZING ] if
                ] }

                ! 2. FAULTY State
                { PORT-STATE-FAULTY [
                    event EV-FAULT-CLEARED = [ PORT-STATE-INITIALIZING ] [ PORT-STATE-FAULTY ] if
                ] }

                ! 3. DISABLED State
                { PORT-STATE-DISABLED [
                    event EV-DESIGNATED-ENABLED = [ PORT-STATE-INITIALIZING ] [ PORT-STATE-DISABLED ] if
                ] }

                ! 4. LISTENING State
                { PORT-STATE-LISTENING [
                    event EV-ANNOUNCE-RECEIPT-TIMEOUT = [
                        PORT-STATE-MASTER
                    ] [
                        event EV-STATE-DECISION = [
                            decision sda>listening-transition
                        ] [ PORT-STATE-LISTENING ] if
                    ] if
                ] }

                ! 5. PRE_MASTER State
                { PORT-STATE-PRE-MASTER [
                    event EV-QUALIFICATION-TIMEOUT = [
                        PORT-STATE-MASTER
                    ] [
                        event EV-STATE-DECISION = [
                            decision sda>pre-master-transition
                        ] [ PORT-STATE-PRE-MASTER ] if
                    ] if
                ] }

                ! 6. MASTER State
                { PORT-STATE-MASTER [
                    event EV-STATE-DECISION = [
                        decision sda>master-transition
                    ] [ PORT-STATE-MASTER ] if
                ] }

                ! 7. PASSIVE State
                { PORT-STATE-PASSIVE [
                    event EV-ANNOUNCE-RECEIPT-TIMEOUT = [
                        PORT-STATE-MASTER
                    ] [
                        event EV-STATE-DECISION = [
                            decision sda>passive-transition
                        ] [ PORT-STATE-PASSIVE ] if
                    ] if
                ] }

                ! 8. UNCALIBRATED State
                { PORT-STATE-UNCALIBRATED [
                    event EV-SYNCHRONIZATION-ACHIEVED = [
                        PORT-STATE-SLAVE
                    ] [
                        event EV-ANNOUNCE-RECEIPT-TIMEOUT = [
                            PORT-STATE-MASTER
                        ] [
                            event EV-STATE-DECISION = [
                                decision sda>uncalibrated-transition
                            ] [ PORT-STATE-UNCALIBRATED ] if
                        ] if
                    ] if
                ] }

                ! 9. SLAVE State
                { PORT-STATE-SLAVE [
                    event EV-SYNCHRONIZATION-FAULT = [
                        PORT-STATE-UNCALIBRATED
                    ] [
                        event EV-ANNOUNCE-RECEIPT-TIMEOUT = [
                            PORT-STATE-MASTER
                        ] [
                            event EV-STATE-DECISION = [
                                decision sda>slave-transition
                            ] [ PORT-STATE-SLAVE ] if
                        ] if
                    ] if
                ] }
                [ drop current-state ]
            } case
        ] if
    ] if ;
