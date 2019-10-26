! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Signaling message structure (44+ octets), packing, and unpacking.

USING: accessors arrays byte-arrays kernel locals math sequences
escapement.common.constants escapement.common.endian
escapement.common.types escapement.protocol.header ;
IN: escapement.protocol.messages.signaling

TUPLE: ptp-signaling
    { header ptp-header }
    { target-port-id port-identity }
    { tlvs array initial: { } } ;

:: <ptp-signaling> ( domain flags port-id seq-id target-pid -- sig-msg )
    MSG-SIGNALING PTP-SIGNALING-BASE-LENGTH domain flags port-id seq-id <ptp-header>
    target-pid { } ptp-signaling boa ;

:: pack-ptp-signaling ( sig-msg -- byte-arr )
    PTP-SIGNALING-BASE-LENGTH <byte-array> :> buf
    sig-msg header>> pack-ptp-header :> hdr-bytes
    34 [| i | i hdr-bytes nth i buf set-nth ] each-integer
    sig-msg target-port-id>> :> tgt-pid
    tgt-pid clock-id>> data>> :> cid-bytes
    8 [| i | i cid-bytes nth 34 i + buf set-nth ] each-integer
    tgt-pid port-number>> buf 42 set-be-uint16
    buf ;

:: unpack-ptp-signaling ( buf -- sig-msg )
    buf length 44 < [ "Buffer too short for PTP Signaling message" throw ] when
    buf unpack-ptp-header :> hdr
    8 <byte-array> :> cid-buf
    8 [| i | 34 i + buf nth i cid-buf set-nth ] each-integer
    cid-buf <clock-identity> :> cid
    buf 42 get-be-uint16 :> pnum
    cid pnum <port-identity> :> tgt-pid
    hdr tgt-pid { } ptp-signaling boa ;
