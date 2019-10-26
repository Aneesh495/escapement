! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Management message structure (48+ octets), action codes, packing, and unpacking.

USING: accessors arrays byte-arrays kernel locals math sequences
escapement.common.constants escapement.common.endian
escapement.common.types escapement.protocol.header ;
IN: escapement.protocol.messages.management

CONSTANT: MGMT-ACTION-GET      0x0
CONSTANT: MGMT-ACTION-SET      0x1
CONSTANT: MGMT-ACTION-RESPONSE 0x2
CONSTANT: MGMT-ACTION-COMMAND  0x3

TUPLE: ptp-management
    { header ptp-header }
    { target-port-id port-identity }
    { starting-boundary-hops integer initial: 0 }
    { boundary-hops integer initial: 0 }
    { action-field integer initial: 0 }
    { tlvs array initial: { } } ;

:: <ptp-management> ( domain flags port-id seq-id target-pid start-hops hops action -- mgmt-msg )
    MSG-MANAGEMENT PTP-MANAGEMENT-BASE-LENGTH domain flags port-id seq-id <ptp-header>
    target-pid start-hops hops action { } ptp-management boa ;

:: pack-ptp-management ( mgmt-msg -- byte-arr )
    PTP-MANAGEMENT-BASE-LENGTH <byte-array> :> buf
    mgmt-msg header>> pack-ptp-header :> hdr-bytes
    34 [| i | i hdr-bytes nth i buf set-nth ] each-integer
    mgmt-msg target-port-id>> :> tgt-pid
    tgt-pid clock-id>> data>> :> cid-bytes
    8 [| i | i cid-bytes nth 34 i + buf set-nth ] each-integer
    tgt-pid port-number>> buf 42 set-be-uint16
    mgmt-msg starting-boundary-hops>> buf 44 set-be-uint8
    mgmt-msg boundary-hops>> buf 45 set-be-uint8
    mgmt-msg action-field>> buf 46 set-be-uint8
    0 buf 47 set-be-uint8 ! reserved
    buf ;

:: unpack-ptp-management ( buf -- mgmt-msg )
    buf length 48 < [ "Buffer too short for PTP Management message" throw ] when
    buf unpack-ptp-header :> hdr
    8 <byte-array> :> cid-buf
    8 [| i | 34 i + buf nth i cid-buf set-nth ] each-integer
    cid-buf <clock-identity> :> cid
    buf 42 get-be-uint16 :> pnum
    cid pnum <port-identity> :> tgt-pid
    buf 44 get-be-uint8 :> start-hops
    buf 45 get-be-uint8 :> hops
    buf 46 get-be-uint8 :> action
    hdr tgt-pid start-hops hops action { } ptp-management boa ;
