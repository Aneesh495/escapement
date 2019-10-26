! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Delay_Req message structure (44 octets), packing, and unpacking.

USING: accessors byte-arrays kernel locals math sequences
escapement.common.constants escapement.common.endian
escapement.common.types escapement.protocol.header ;
IN: escapement.protocol.messages.delay-req

TUPLE: ptp-delay-req
    { header ptp-header }
    { origin-timestamp timestamp } ;

:: <ptp-delay-req> ( domain flags port-id seq-id ts -- dreq-msg )
    MSG-DELAY-REQ PTP-DELAY-REQ-LENGTH domain flags port-id seq-id <ptp-header>
    ts ptp-delay-req boa ;

:: pack-ptp-delay-req ( dreq-msg -- byte-arr )
    PTP-DELAY-REQ-LENGTH <byte-array> :> buf
    dreq-msg header>> pack-ptp-header :> hdr-bytes
    34 [| i | i hdr-bytes nth i buf set-nth ] each-integer
    dreq-msg origin-timestamp>> :> ts
    ts seconds>> buf 34 set-be-uint48
    ts nanoseconds>> buf 40 set-be-uint32
    buf ;

:: unpack-ptp-delay-req ( buf -- dreq-msg )
    buf length 44 < [ "Buffer too short for PTP Delay_Req message" throw ] when
    buf unpack-ptp-header :> hdr
    buf 34 get-be-uint48 :> sec
    buf 40 get-be-uint32 :> nsec
    sec nsec <timestamp> :> ts
    hdr ts ptp-delay-req boa ;
