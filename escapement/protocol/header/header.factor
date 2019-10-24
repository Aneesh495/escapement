! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Common PTP message header (34 octets) tuple, flags, packing, and unpacking.

USING: accessors byte-arrays formatting kernel locals math
math.parser sequences strings escapement.common.constants
escapement.common.endian escapement.common.types ;
IN: escapement.protocol.header

TUPLE: ptp-header
    { message-type integer initial: 0 }
    { version integer initial: 2 }
    { message-length integer initial: 34 }
    { domain-number integer initial: 0 }
    { minor-sdo-id integer initial: 0 }
    { flags integer initial: 0 }
    { correction-field integer initial: 0 } ! Scaled nanoseconds (ns * 65536)
    { message-type-specific integer initial: 0 }
    { source-port-id port-identity }
    { sequence-id integer initial: 0 }
    { control-field integer initial: 0 }
    { log-message-interval integer initial: 0 } ;

:: <ptp-header> ( msg-type len domain flags port-id seq-id -- hdr )
    msg-type
    2
    len
    domain
    0
    flags
    0
    0
    port-id
    seq-id
    0
    0
    ptp-header boa ;

! Pack ptp-header into a 34-byte byte-array
:: pack-ptp-header ( hdr -- byte-arr )
    34 <byte-array> :> buf
    ! Octet 0: (majorSdoId << 4) | messageType
    hdr message-type>> 0x0F bitand buf 0 set-be-uint8
    ! Octet 1: (minorVersionPTP << 4) | versionPTP
    hdr version>> 0x0F bitand buf 1 set-be-uint8
    ! Octets 2-3: messageLength
    hdr message-length>> buf 2 set-be-uint16
    ! Octet 4: domainNumber
    hdr domain-number>> buf 4 set-be-uint8
    ! Octet 5: minorSdoId
    hdr minor-sdo-id>> buf 5 set-be-uint8
    ! Octets 6-7: flags
    hdr flags>> buf 6 set-be-uint16
    ! Octets 8-15: correctionField (64-bit signed)
    hdr correction-field>> buf 8 set-be-int64
    ! Octets 16-19: messageTypeSpecific
    hdr message-type-specific>> buf 16 set-be-uint32
    ! Octets 20-27: sourcePortIdentity.clockIdentity (8 bytes)
    hdr source-port-id>> clock-id>> data>> :> cid-bytes
    8 [| i | i cid-bytes nth 20 i + buf set-nth ] each-integer
    ! Octets 28-29: sourcePortIdentity.portNumber (16 bits)
    hdr source-port-id>> port-number>> buf 28 set-be-uint16
    ! Octets 30-31: sequenceId
    hdr sequence-id>> buf 30 set-be-uint16
    ! Octet 32: controlField
    hdr control-field>> buf 32 set-be-uint8
    ! Octet 33: logMessageInterval (signed int8)
    hdr log-message-interval>> buf 33 set-be-uint8
    buf ;

! Unpack ptp-header from byte-array at offset 0
:: unpack-ptp-header ( buf -- hdr )
    buf length 34 < [ "Buffer too short for PTP header" throw ] when
    buf 0 get-be-uint8 0x0F bitand :> msg-type
    buf 1 get-be-uint8 0x0F bitand :> ver
    buf 2 get-be-uint16 :> msg-len
    buf 4 get-be-uint8 :> dom
    buf 5 get-be-uint8 :> sdo
    buf 6 get-be-uint16 :> flg
    buf 8 get-be-int64 :> corr
    buf 16 get-be-uint32 :> mts
    8 <byte-array> :> cid-buf
    8 [| i | 20 i + buf nth i cid-buf set-nth ] each-integer
    cid-buf <clock-identity> :> cid
    buf 28 get-be-uint16 :> pnum
    cid pnum <port-identity> :> pid
    buf 30 get-be-uint16 :> seq
    buf 32 get-be-uint8 :> ctl
    buf 33 get-be-int8 :> lmi

    msg-type ver msg-len dom sdo flg corr mts pid seq ctl lmi ptp-header boa ;

! Flag inspection helpers
: two-step? ( hdr -- ? )
    flags>> FLAG-PTP-TWO-STEP bitand 0 > ;

: unicast? ( hdr -- ? )
    flags>> FLAG-PTP-UNICAST bitand 0 > ;

: ptp-timescale? ( hdr -- ? )
    flags>> FLAG-PTP-TIMESCALE bitand 0 > ;

: time-traceable? ( hdr -- ? )
    flags>> FLAG-TIME-TRACEABLE bitand 0 > ;

: frequency-traceable? ( hdr -- ? )
    flags>> FLAG-FREQUENCY-TRACEABLE bitand 0 > ;

! Format PTP header for debug inspection
:: ptp-header>string ( hdr -- str )
    hdr message-type>>
    hdr sequence-id>>
    hdr source-port-id>> port-identity>string
    hdr correction-field>>
    "PtpHeader[type=%d, seq=%d, port=%s, corr=%d scaled-ns]" sprintf ;
