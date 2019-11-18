! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Unit tests for common types, big-endian binary conversions, and ring buffers.

USING: accessors arrays byte-arrays io kernel locals math
math.functions sequences tools.test
escapement.common.constants escapement.common.endian
escapement.common.ring-buffer escapement.common.types ;
IN: escapement.tests.common

:: test-endian ( -- )
    ! Test 16-bit big endian
    1000 >be-uint16 :> b16
    b16 0 get-be-uint16 1000 = [ "pass: uint16" print ] [ "fail: uint16" throw ] if

    ! Test 32-bit big endian
    12345678 >be-uint32 :> b32
    b32 0 get-be-uint32 12345678 = [ "pass: uint32" print ] [ "fail: uint32" throw ] if

    ! Test 48-bit big endian
    9876543210 >be-uint48 :> b48
    b48 0 get-be-uint48 9876543210 = [ "pass: uint48" print ] [ "fail: uint48" throw ] if

    ! Test 64-bit signed int
    -500000 8 <byte-array> [ 0 set-be-int64 ] keep :> b64
    b64 0 get-be-int64 -500000 = [ "pass: int64" print ] [ "fail: int64" throw ] if ;

:: test-ring-buffer ( -- )
    5 <ring-buffer> :> ring
    ring size>> 0 = [ "pass: empty ring size" print ] [ "fail: empty ring" throw ] if

    10.0 ring ring-push
    20.0 ring ring-push
    30.0 ring ring-push
    ring ring-mean 20.0 = [ "pass: ring mean" print ] [ "fail: ring mean" throw ] if
    ring ring-min 10.0 = [ "pass: ring min" print ] [ "fail: ring min" throw ] if
    ring ring-max 30.0 = [ "pass: ring max" print ] [ "fail: ring max" throw ] if
    ring ring-median 20.0 = [ "pass: ring median" print ] [ "fail: ring median" throw ] if ;

:: test-types ( -- )
    { 1 2 3 4 5 6 7 8 } >byte-array <clock-identity> :> cid1
    { 1 2 3 4 5 6 7 8 } >byte-array <clock-identity> :> cid2
    cid1 cid2 clock-identity= [ "pass: cid equality" print ] [ "fail: cid equality" throw ] if

    cid1 1 <port-identity> :> pid1
    cid2 1 <port-identity> :> pid2
    pid1 pid2 port-identity= [ "pass: pid equality" print ] [ "fail: pid equality" throw ] if ;

:: run-common-tests ( -- )
    "--- Running Common Subsystem Unit Tests ---" print
    test-endian
    test-ring-buffer
    test-types
    "All Common subsystem tests passed successfully." print ;
