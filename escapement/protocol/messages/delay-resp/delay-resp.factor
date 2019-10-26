! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Delay_Resp message structure (54 octets), packing, and unpacking.

USING: accessors byte-arrays kernel locals math sequences
escapement.common.constants escapement.common.endian
escapement.common.types escapement.protocol.header ;
IN: escapement.protocol.messages.delay-resp

TUPLE: ptp-delay-resp
    { header ptp-header }
    { receive-timestamp timestamp }
    { requesting-port-id port-identity } ;

:: <ptp-delay-resp> ( domain flags port-id seq-id ts req-port-id -- dresp-msg )
    MSG-DELAY-RESP PTP-DELAY-RESP-LENGTH domain flags port-id seq-id <ptp-header>
    ts req-port-id ptp-delay-resp boa ;

:: pack-ptp-delay-resp ( dresp-msg -- byte-arr )
    PTP-DELAY-RESP-LENGTH <byte-array> :> buf
    dresp-msg header>> pack-ptp-header :> hdr-bytes
    34 [| i | i hdr-bytes nth i buf set-nth ] each-integer
    dresp-msg receive-timestamp>> :> ts
    ts seconds>> buf 34 set-be-uint48
    ts nanoseconds>> buf 40 set-be-uint32
    dresp-msg requesting-port-id>> :> req-pid
    req-pid clock-id>> data>> :> cid-bytes
    8 [| i | i cid-bytes nth 44 i + buf set-nth ] each-integer
    req-pid port-number>> buf 52 set-be-uint16
    buf ;

:: unpack-ptp-delay-resp ( buf -- dresp-msg )
    buf length 54 < [ "Buffer too short for PTP Delay_Resp message" throw ] when
    buf unpack-ptp-header :> hdr
    buf 34 get-be-uint48 :> sec
    buf 40 get-be-uint32 :> nsec
    sec nsec <timestamp> :> ts
    8 <byte-array> :> cid-buf
    8 [| i | 44 i + buf nth i cid-buf set-nth ] each-integer
    cid-buf <clock-identity> :> cid
    buf 52 get-be-uint16 :> pnum
    cid pnum <port-identity> :> req-pid
    hdr ts req-pid ptp-delay-resp boa ;
