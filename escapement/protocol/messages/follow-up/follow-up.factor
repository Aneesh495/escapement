! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Follow_Up message structure (44 octets), packing, and unpacking.

USING: accessors byte-arrays kernel locals math sequences
escapement.common.constants escapement.common.endian
escapement.common.types escapement.protocol.header ;
IN: escapement.protocol.messages.follow-up

TUPLE: ptp-follow-up
    { header ptp-header }
    { precise-origin-timestamp timestamp } ;

:: <ptp-follow-up> ( domain flags port-id seq-id ts -- fup-msg )
    MSG-FOLLOW-UP PTP-FOLLOW-UP-LENGTH domain flags port-id seq-id <ptp-header>
    ts ptp-follow-up boa ;

:: pack-ptp-follow-up ( fup-msg -- byte-arr )
    PTP-FOLLOW-UP-LENGTH <byte-array> :> buf
    fup-msg header>> pack-ptp-header :> hdr-bytes
    34 [| i | i hdr-bytes nth i buf set-nth ] each-integer
    fup-msg precise-origin-timestamp>> :> ts
    ts seconds>> buf 34 set-be-uint48
    ts nanoseconds>> buf 40 set-be-uint32
    buf ;

:: unpack-ptp-follow-up ( buf -- fup-msg )
    buf length 44 < [ "Buffer too short for PTP Follow_Up message" throw ] when
    buf unpack-ptp-header :> hdr
    buf 34 get-be-uint48 :> sec
    buf 40 get-be-uint32 :> nsec
    sec nsec <timestamp> :> ts
    hdr ts ptp-follow-up boa ;
