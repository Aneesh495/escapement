! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! High-performance circular buffer with rolling statistics.

USING: accessors arrays kernel locals math math.functions
math.order sequences sorting ;
IN: escapement.common.ring-buffer

TUPLE: ring-buffer
    { capacity integer }
    { buffer array }
    { head integer initial: 0 }
    { size integer initial: 0 } ;

:: <ring-buffer> ( capacity -- ring )
    capacity
    capacity f <array>
    0 0 ring-buffer boa ;

:: ring-push ( val ring -- )
    val ring head>> ring buffer>> set-nth
    ring head>> 1 + ring capacity>> mod :> new-head
    ring new-head >>head drop
    ring size>> ring capacity>> < [
        ring size>> 1 + :> new-size
        ring new-size >>size drop
    ] when ;

:: ring-to-array ( ring -- arr )
    ring size>> 0 = [ { } ] [
        ring size>> f <array> :> result
        ring size>> ring capacity>> < [
            ring size>> [| i |
                i ring buffer>> nth i result set-nth
            ] each-integer
        ] [
            ring capacity>> [| i |
                ring head>> i + ring capacity>> mod :> src-idx
                src-idx ring buffer>> nth i result set-nth
            ] each-integer
        ] if
        result
    ] if ;

:: ring-clear ( ring -- )
    ring 0 >>head 0 >>size drop ;

:: ring-mean ( ring -- mean )
    ring size>> 0 = [ 0.0 ] [
        ring ring-to-array :> arr
        arr sum arr length >float /
    ] if ;

:: ring-variance ( ring -- var )
    ring size>> 2 < [ 0.0 ] [
        ring ring-to-array :> arr
        ring ring-mean :> m
        0.0 :> sum-sq!
        arr [| x |
            x m - dup * sum-sq + sum-sq!
        ] each
        sum-sq arr length 1 - >float /
    ] if ;

:: ring-stddev ( ring -- sd )
    ring ring-variance sqrt ;

:: ring-min ( ring -- min-val )
    ring size>> 0 = [ 0.0 ] [
        ring ring-to-array minimum
    ] if ;

:: ring-max ( ring -- max-val )
    ring size>> 0 = [ 0.0 ] [
        ring ring-to-array maximum
    ] if ;

:: ring-median ( ring -- med )
    ring size>> 0 = [ 0.0 ] [
        ring ring-to-array natural-sort :> s
        s length :> n
        n 2 mod 1 = [
            n 2 /i s nth
        ] [
            n 2 /i 1 - s nth
            n 2 /i s nth + 2.0 /
        ] if
    ] if ;
