! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Nanosecond timestamp arithmetic, normalization, conversion, and comparisons.

USING: accessors kernel locals math math.functions math.order
escapement.common.types ;
IN: escapement.timing.timestamps

CONSTANT: NS-PER-SEC 1000000000

! Normalize timestamp so 0 <= nanoseconds < 1,000,000,000
:: normalize-timestamp ( ts -- norm-ts )
    ts seconds>> :> sec!
    ts nanoseconds>> :> nsec!
    [ nsec 0 < ] [
        sec 1 - sec!
        nsec NS-PER-SEC + nsec!
    ] while
    [ nsec NS-PER-SEC >= ] [
        sec 1 + sec!
        nsec NS-PER-SEC - nsec!
    ] while
    sec nsec <timestamp> ;

! Add two timestamps: ts1 + ts2
:: timestamp+ ( ts1 ts2 -- ts-sum )
    ts1 seconds>> ts2 seconds>> +
    ts1 nanoseconds>> ts2 nanoseconds>> +
    <timestamp> normalize-timestamp ;

! Difference between two timestamps in nanoseconds as float: ts1 - ts2
:: timestamp-diff-ns ( ts1 ts2 -- diff-ns )
    ts1 seconds>> ts2 seconds>> - >float NS-PER-SEC >float *
    ts1 nanoseconds>> ts2 nanoseconds>> - >float + ;

! Add signed nanoseconds to timestamp: ts + delta_ns
:: timestamp+ns ( ts delta-ns -- new-ts )
    ts seconds>> :> sec!
    ts nanoseconds>> delta-ns >integer + :> nsec!
    sec nsec <timestamp> normalize-timestamp ;

! Convert timestamp to seconds as double
: timestamp>seconds ( ts -- sec-double )
    [ seconds>> >float ] [ nanoseconds>> >float NS-PER-SEC >float / ] bi + ;

! Convert seconds as double to timestamp
:: seconds>timestamp ( sec-double -- ts )
    sec-double floor >integer :> sec
    sec-double sec >float - NS-PER-SEC >float * round >integer :> nsec
    sec nsec <timestamp> normalize-timestamp ;

! Convert total nanoseconds to timestamp
:: nanoseconds>timestamp ( total-ns -- ts )
    total-ns NS-PER-SEC /i :> sec
    total-ns NS-PER-SEC mod :> nsec
    sec nsec <timestamp> normalize-timestamp ;

! Convert timestamp to total integer nanoseconds
:: timestamp>nanoseconds ( ts -- total-ns )
    ts seconds>> NS-PER-SEC * ts nanoseconds>> + ;

! Compare two timestamps: returns -1 if ts1 < ts2, 1 if ts1 > ts2, 0 if equal
:: compare-timestamps ( ts1 ts2 -- res )
    ts1 seconds>> ts2 seconds>> <=> :> sec-res
    sec-res +eq+ = [
        ts1 nanoseconds>> ts2 nanoseconds>> <=>
        dup +lt+ = [ drop -1 ] [ +gt+ = [ 1 ] [ 0 ] if ] if
    ] [
        sec-res +lt+ = -1 1 ?
    ] if ;

: timestamp< ( ts1 ts2 -- ? )
    compare-timestamps -1 = ;

: timestamp> ( ts1 ts2 -- ? )
    compare-timestamps 1 = ;

: timestamp= ( ts1 ts2 -- ? )
    compare-timestamps 0 = ;
