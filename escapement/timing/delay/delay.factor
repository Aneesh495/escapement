! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! End-to-End (E2E) and Peer-to-Peer (P2P) delay and clock offset computation.

USING: accessors kernel locals math math.functions
escapement.common.types escapement.timing.timestamps ;
IN: escapement.timing.delay

! Convert 64-bit scaled nanoseconds (ns * 65536) to nanoseconds float
: scaled-ns>ns ( scaled -- ns-float )
    >float 65536.0 / ;

! Convert nanoseconds float to 64-bit scaled nanoseconds integer
: ns>scaled-ns ( ns-float -- scaled )
    65536.0 * round >integer ;

! Calculate End-to-End (E2E) mean path delay and clock offset in nanoseconds
! t1: Sync egress timestamp (master)
! t2: Sync ingress timestamp (slave)
! t3: Delay_Req egress timestamp (slave)
! t4: Delay_Req ingress timestamp (master)
! c1-scaled: Sync/Follow_Up correction field (scaled ns)
! c2-scaled: Delay_Resp correction field (scaled ns)
:: compute-e2e-delay-and-offset ( t1 t2 t3 t4 c1-scaled c2-scaled -- mean-delay-ns offset-ns )
    c1-scaled scaled-ns>ns :> c1
    c2-scaled scaled-ns>ns :> c2

    t2 t1 timestamp-diff-ns c1 - :> forward-transit
    t4 t3 timestamp-diff-ns c2 - :> reverse-transit

    forward-transit reverse-transit + 2.0 / :> delay
    forward-transit delay - :> offset

    delay offset ;

! Calculate Peer-to-Peer (P2P) mean path delay and neighbor rate ratio
! t1: Pdelay_Req egress timestamp (requester)
! t2: Pdelay_Req ingress timestamp (responder)
! t3: Pdelay_Resp egress timestamp (responder)
! t4: Pdelay_Resp ingress timestamp (requester)
! c1-scaled: Pdelay_Resp correction field
! c2-scaled: Pdelay_Resp_Follow_Up correction field
:: compute-p2p-delay-and-ratio ( t1 t2 t3 t4 c1-scaled c2-scaled -- peer-delay-ns rate-ratio )
    c1-scaled scaled-ns>ns :> c1
    c2-scaled scaled-ns>ns :> c2

    t4 t1 timestamp-diff-ns :> requester-turnaround
    t3 t2 timestamp-diff-ns :> responder-turnaround

    requester-turnaround responder-turnaround - c1 - c2 - 2.0 / :> pdelay

    responder-turnaround c2 + 0.0 > [
        requester-turnaround c1 - responder-turnaround c2 + /
    ] [
        1.0
    ] if :> ratio

    pdelay ratio ;
