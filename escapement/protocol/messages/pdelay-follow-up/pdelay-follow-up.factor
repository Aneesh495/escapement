! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Pdelay_Resp_Follow_Up message structure (54 octets), packing, and unpacking.

USING: accessors byte-arrays kernel locals math sequences
escapement.common.constants escapement.common.endian
escapement.common.types escapement.protocol.header ;
IN: escapement.protocol.messages.pdelay-follow-up

TUPLE: ptp-pdelay-follow-up
    { header ptp-header }
    { response-origin-timestamp timestamp }
    { requesting-port-id port-identity } ;

:: <ptp-pdelay-follow-up> ( domain flags port-id seq-id ts req-port-id -- pfup-msg )
    MSG-PDELAY-RESP-FOLLOW-UP PTP-PDELAY-RESP-FOLLOW-UP-LENGTH domain flags port-id seq-id <ptp-header>
    ts req-port-id ptp-pdelay-follow-up boa ;

:: pack-ptp-pdelay-follow-up ( pfup-msg -- byte-arr )
    PTP-PDELAY-RESP-FOLLOW-UP-LENGTH <byte-array> :> buf
    pfup-msg header>> pack-ptp-header :> hdr-bytes
    34 [| i | i hdr-bytes nth i buf set-nth ] each-integer
    pfup-msg response-origin-timestamp>> :> ts
    ts seconds>> buf 34 set-be-uint48
    ts nanoseconds>> buf 40 set-be-uint32
    pfup-msg requesting-port-id>> :> req-pid
    req-pid clock-id>> data>> :> cid-bytes
    8 [| i | i cid-bytes nth 44 i + buf set-nth ] each-integer
    req-pid port-number>> buf 52 set-be-uint16
    buf ;

:: unpack-ptp-pdelay-follow-up ( buf -- pfup-msg )
    buf length 54 < [ "Buffer too short for PTP Pdelay_Resp_Follow_Up message" throw ] when
    buf unpack-ptp-header :> hdr
    buf 34 get-be-uint48 :> sec
    buf 40 get-be-uint32 :> nsec
    sec nsec <timestamp> :> ts
    8 <byte-array> :> cid-buf
    8 [| i | 44 i + buf nth i cid-buf set-nth ] each-integer
    cid-buf <clock-identity> :> cid
    buf 52 get-be-uint16 :> pnum
    cid pnum <port-identity> :> req-pid
    hdr ts req-pid ptp-pdelay-follow-up boa ;
