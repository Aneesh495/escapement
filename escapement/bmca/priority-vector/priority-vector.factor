! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Priority Vector structures per IEEE 1588-2019 Clause 9.3.2.4.

USING: accessors kernel locals math sequences
escapement.common.constants escapement.common.types ;
IN: escapement.bmca.priority-vector

TUPLE: priority-vector
    { priority1 integer initial: 128 }
    { clock-class integer initial: 248 }
    { clock-accuracy integer initial: 0xFE }
    { offset-scaled-log-variance integer initial: 0xFFFF }
    { priority2 integer initial: 128 }
    { grandmaster-id clock-identity }
    { steps-removed integer initial: 0 }
    { sender-port-id port-identity }
    { receiver-port-number integer initial: 1 } ;

:: <priority-vector> ( pri1 cclass cacc cvar pri2 gm-id steps sender-pid recv-port -- pv )
    pri1 cclass cacc cvar pri2 gm-id steps sender-pid recv-port priority-vector boa ;

! System Priority Vector D0 (representing this clock itself as potential master)
:: <system-priority-vector> ( pri1 cclass cacc cvar pri2 my-clock-id -- pv )
    my-clock-id 0 <port-identity> :> self-pid
    pri1 cclass cacc cvar pri2 my-clock-id 0 self-pid 0 priority-vector boa ;
