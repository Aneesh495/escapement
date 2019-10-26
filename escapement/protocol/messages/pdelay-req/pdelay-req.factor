! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Pdelay_Req message structure (54 octets), packing, and unpacking.

USING: accessors byte-arrays kernel locals math sequences
escapement.common.constants escapement.common.endian
escapement.common.types escapement.protocol.header ;
IN: escapement.protocol.messages.pdelay-req

TUPLE: ptp-pdelay-req
    { header ptp-header }
    { origin-timestamp timestamp } ;

:: <ptp-pdelay-req> ( domain flags port-id seq-id ts -- preq-msg )
    MSG-PDELAY-REQ PTP-PDELAY-REQ-LENGTH domain flags port-id seq-id <ptp-header>
    ts ptp-pdelay-req boa ;

:: pack-ptp-pdelay-req ( preq-msg -- byte-arr )
    PTP-PDELAY-REQ-LENGTH <byte-array> :> buf
    preq-msg header>> pack-ptp-header :> hdr-bytes
    34 [| i | i hdr-bytes nth i buf set-nth ] each-integer
    preq-msg origin-timestamp>> :> ts
    ts seconds>> buf 34 set-be-uint48
    ts nanoseconds>> buf 40 set-be-uint32
    ! Octets 44-53 are reserved (zeroes)
    buf ;

:: unpack-ptp-pdelay-req ( buf -- preq-msg )
    buf length 54 < [ "Buffer too short for PTP Pdelay_Req message" throw ] when
    buf unpack-ptp-header :> hdr
    buf 34 get-be-uint48 :> sec
    buf 40 get-be-uint32 :> nsec
    sec nsec <timestamp> :> ts
    hdr ts ptp-pdelay-req boa ;
