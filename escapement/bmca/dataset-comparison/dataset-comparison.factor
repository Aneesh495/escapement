! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Dataset Comparison Algorithm (DCA) per IEEE 1588-2019 Clause 9.3.4.

USING: accessors byte-arrays kernel locals math math.order
sequences escapement.bmca.priority-vector escapement.common.types ;
IN: escapement.bmca.dataset-comparison

! Lexicographical byte-array comparison: returns -1 if b1 < b2, 1 if b1 > b2, 0 if equal
:: compare-byte-arrays ( b1 b2 -- res )
    0 :> result!
    b1 length b2 length min :> lim
    lim [| i |
        result 0 = [
            i b1 nth :> x
            i b2 nth :> y
            x y < [ -1 result! ] [ x y > [ 1 result! ] when ] if
        ] when
    ] each-integer
    result 0 = [
        b1 length b2 length < [ -1 ] [ b1 length b2 length > [ 1 ] [ 0 ] if ] if
    ] [ result ] if ;

! Compare ClockIdentities lexicographically
: compare-clock-identities ( cid1 cid2 -- res )
    [ data>> ] bi@ compare-byte-arrays ;

! Compare PortIdentities lexicographically
:: compare-port-identities ( pid1 pid2 -- res )
    pid1 clock-id>> pid2 clock-id>> compare-clock-identities :> cid-res
    cid-res 0 = [
        pid1 port-number>> pid2 port-number>> <=>
        dup +lt+ = [ drop -1 ] [ +gt+ = [ 1 ] [ 0 ] if ] if
    ] [ cid-res ] if ;

! Full Dataset Comparison Algorithm per IEEE 1588 Clause 9.3.4
! Returns -1 if pvA is superior (A < B), 1 if pvB is superior (B < A), 0 if identical
:: compare-priority-vectors ( a b -- res )
    ! 1. Grandmaster Priority 1
    a priority1>> b priority1>> <=> :> p1-res
    p1-res +eq+ = [
        ! 2. Grandmaster Clock Class
        a clock-class>> b clock-class>> <=> :> cls-res
        cls-res +eq+ = [
            ! 3. Grandmaster Clock Accuracy
            a clock-accuracy>> b clock-accuracy>> <=> :> acc-res
            acc-res +eq+ = [
                ! 4. Grandmaster Offset Scaled Log Variance
                a offset-scaled-log-variance>> b offset-scaled-log-variance>> <=> :> var-res
                var-res +eq+ = [
                    ! 5. Grandmaster Priority 2
                    a priority2>> b priority2>> <=> :> p2-res
                    p2-res +eq+ = [
                        ! 6. Grandmaster Identity
                        a grandmaster-id>> b grandmaster-id>> compare-clock-identities :> gm-res
                        gm-res 0 = [
                            ! Same GM Identity: Clause 9.3.4 Part 2
                            a steps-removed>> :> a-steps
                            b steps-removed>> :> b-steps
                            a-steps 1 + b-steps < [ -1 ] [
                                b-steps 1 + a-steps < [ 1 ] [
                                    a-steps b-steps < [ -1 ] [
                                        a-steps b-steps > [ 1 ] [
                                            ! Steps equal: compare sender port identities
                                            a sender-port-id>> b sender-port-id>> compare-port-identities :> spid-res
                                            spid-res 0 = [
                                                a receiver-port-number>> b receiver-port-number>> <=>
                                                dup +lt+ = [ drop -1 ] [ +gt+ = [ 1 ] [ 0 ] if ] if
                                            ] [ spid-res ] if
                                        ] if
                                    ] if
                                ] if
                            ] if
                        ] [ gm-res ] if
                    ] [ p2-res +lt+ = -1 1 ? ] if
                ] [ var-res +lt+ = -1 1 ? ] if
            ] [ acc-res +lt+ = -1 1 ? ] if
        ] [ cls-res +lt+ = -1 1 ? ] if
    ] [ p1-res +lt+ = -1 1 ? ] if ;

: vector-better? ( a b -- ? )
    compare-priority-vectors -1 = ;

: vector-worse? ( a b -- ? )
    compare-priority-vectors 1 = ;

: vector-equal? ( a b -- ? )
    compare-priority-vectors 0 = ;
