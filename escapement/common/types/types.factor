! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Core data types, tuples, and equality predicates.

USING: accessors arrays assocs byte-arrays formatting kernel math
math.parser sequences strings ;
IN: escapement.common.types

! IEEE 1588-2019 Timestamp tuple: 48-bit unsigned seconds, 32-bit unsigned nanoseconds
TUPLE: timestamp
    { seconds integer initial: 0 }
    { nanoseconds integer initial: 0 } ;

: <timestamp> ( seconds nanoseconds -- timestamp )
    timestamp boa ;

! Clock Identity: 8-octet array (EUI-64 representation)
TUPLE: clock-identity
    { data byte-array } ;

: <clock-identity> ( byte-array -- clock-identity )
    dup length 8 = [ "ClockIdentity must be exactly 8 bytes" throw ] unless
    clock-identity boa ;

! Port Identity: clock-identity + 16-bit port number
TUPLE: port-identity
    { clock-id clock-identity }
    { port-number integer initial: 1 } ;

: <port-identity> ( clock-id port-number -- port-identity )
    port-identity boa ;

! Clock Quality: clockClass, clockAccuracy, offsetScaledLogVariance
TUPLE: clock-quality
    { clock-class integer initial: 248 }
    { clock-accuracy integer initial: 0xFE }
    { offset-scaled-log-variance integer initial: 0xFFFF } ;

: <clock-quality> ( class accuracy variance -- clock-quality )
    clock-quality boa ;

! Port State Enumeration
CONSTANT: PORT-STATE-INITIALIZING  0
CONSTANT: PORT-STATE-FAULTY        1
CONSTANT: PORT-STATE-DISABLED      2
CONSTANT: PORT-STATE-LISTENING     3
CONSTANT: PORT-STATE-PRE-MASTER    4
CONSTANT: PORT-STATE-MASTER        5
CONSTANT: PORT-STATE-PASSIVE       6
CONSTANT: PORT-STATE-UNCALIBRATED  7
CONSTANT: PORT-STATE-SLAVE         8

: port-state>string ( state -- str )
    {
        { 0 "INITIALIZING" }
        { 1 "FAULTY" }
        { 2 "DISABLED" }
        { 3 "LISTENING" }
        { 4 "PRE_MASTER" }
        { 5 "MASTER" }
        { 6 "PASSIVE" }
        { 7 "UNCALIBRATED" }
        { 8 "SLAVE" }
    } ?at [ "UNKNOWN" ] unless ;

! Format ClockIdentity as colon-separated hex string
: clock-identity>string ( clock-id -- str )
    data>> [ "%02X" sprintf ] { } map-as ":" join ;

! Format PortIdentity as clock-id/port
: port-identity>string ( port-id -- str )
    [ clock-id>> clock-identity>string ] [ port-number>> number>string ] bi
    "/" glue ;

! Format Timestamp as seconds.fraction
: timestamp>string ( ts -- str )
    [ seconds>> ] [ nanoseconds>> ] bi
    "%d.%09d" sprintf ;

! Clock Identity Equality
: clock-identity= ( id1 id2 -- ? )
    [ data>> ] bi@ sequence= ;

! Port Identity Equality
: port-identity= ( p1 p2 -- ? )
    [ [ clock-id>> ] bi@ clock-identity= ]
    [ [ port-number>> ] bi@ = ] 2bi and ;
