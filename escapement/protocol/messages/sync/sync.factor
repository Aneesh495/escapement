! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Sync message structure (44 octets), packing, unpacking, and validation.

USING: accessors byte-arrays kernel locals math sequences
escapement.common.constants escapement.common.endian
escapement.common.types escapement.protocol.header ;
IN: escapement.protocol.messages.sync

TUPLE: ptp-sync
    { header ptp-header }
    { origin-timestamp timestamp } ;

:: <ptp-sync> ( domain flags port-id seq-id ts -- sync-msg )
    MSG-SYNC PTP-SYNC-LENGTH domain flags port-id seq-id <ptp-header>
    ts ptp-sync boa ;

:: pack-ptp-sync ( sync-msg -- byte-arr )
    PTP-SYNC-LENGTH <byte-array> :> buf
    sync-msg header>> pack-ptp-header :> hdr-bytes
    34 [| i | i hdr-bytes nth i buf set-nth ] each-integer
    sync-msg origin-timestamp>> :> ts
    ts seconds>> buf 34 set-be-uint48
    ts nanoseconds>> buf 40 set-be-uint32
    buf ;

:: unpack-ptp-sync ( buf -- sync-msg )
    buf length 44 < [ "Buffer too short for PTP Sync message" throw ] when
    buf unpack-ptp-header :> hdr
    buf 34 get-be-uint48 :> sec
    buf 40 get-be-uint32 :> nsec
    sec nsec <timestamp> :> ts
    hdr ts ptp-sync boa ;
