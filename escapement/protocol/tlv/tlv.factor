! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Type-Length-Value (TLV) extension records, management IDs, and wire codecs.

USING: accessors arrays byte-arrays kernel locals math sequences
escapement.common.endian escapement.common.types ;
IN: escapement.protocol.tlv

CONSTANT: TLV-MANAGEMENT                             0x0001
CONSTANT: TLV-MANAGEMENT-ERROR-STATUS                0x0002
CONSTANT: TLV-ORGANIZATION-EXTENSION                 0x0003
CONSTANT: TLV-REQUEST-UNICAST-TRANSMISSION           0x0004
CONSTANT: TLV-GRANT-UNICAST-TRANSMISSION             0x0005
CONSTANT: TLV-CANCEL-UNICAST-TRANSMISSION            0x0006
CONSTANT: TLV-ACKNOWLEDGE-CANCEL-UNICAST             0x0007
CONSTANT: TLV-PATH-TRACE                             0x0008
CONSTANT: TLV-ALTERNATE-TIME-OFFSET-INDICATOR        0x0009

! Standard Management IDs per IEEE 1588 Table 40
CONSTANT: MID-USER-DESCRIPTION                       0x0002
CONSTANT: MID-DEFAULT-DATA-SET                       0x2000
CONSTANT: MID-CURRENT-DATA-SET                       0x2001
CONSTANT: MID-PARENT-DATA-SET                        0x2002
CONSTANT: MID-TIME-PROPERTIES-DATA-SET               0x2003
CONSTANT: MID-PORT-DATA-SET                          0x2004
CONSTANT: MID-PRIORITY1                              0x2005
CONSTANT: MID-PRIORITY2                              0x2006
CONSTANT: MID-DOMAIN                                 0x2007
CONSTANT: MID-LOG-ANNOUNCE-INTERVAL                  0x200B
CONSTANT: MID-ANNOUNCE-RECEIPT-TIMEOUT               0x200C
CONSTANT: MID-LOG-SYNC-INTERVAL                      0x200D
CONSTANT: MID-VERSION-NUMBER                         0x200E
CONSTANT: MID-TIME                                   0x200F
CONSTANT: MID-CLOCK-ACCURACY                         0x2010

TUPLE: ptp-tlv
    { tlv-type integer }
    { length-field integer }
    { value-field byte-array } ;

:: <ptp-tlv> ( type value-bytes -- tlv )
    type value-bytes length value-bytes ptp-tlv boa ;

! Pack TLV into wire format (2 bytes type, 2 bytes length, N bytes value)
:: pack-ptp-tlv ( tlv -- byte-arr )
    tlv length-field>> 4 + <byte-array> :> buf
    tlv tlv-type>> buf 0 set-be-uint16
    tlv length-field>> buf 2 set-be-uint16
    tlv value-field>> :> val
    tlv length-field>> [| i | i val nth 4 i + buf set-nth ] each-integer
    buf ;

! Unpack single TLV from byte-array at offset
:: unpack-ptp-tlv ( buf offset -- tlv next-offset )
    buf offset get-be-uint16 :> type
    buf offset 2 + get-be-uint16 :> len
    len <byte-array> :> val
    len [| i | offset 4 + i + buf nth i val set-nth ] each-integer
    type len val ptp-tlv boa
    offset 4 + len + ;

! Unpack all chained TLVs from a buffer starting at offset
:: unpack-all-tlvs ( buf offset -- tlv-array )
    V{ } clone :> acc
    offset :> curr-off!
    [ curr-off buf length 4 - <= ] [
        buf curr-off unpack-ptp-tlv :> ( tlv next-off )
        tlv acc push
        next-off curr-off!
    ] while
    acc >array ;

! PathTrace TLV Builder (0x0008): Sequence of 8-octet clock identities
:: <path-trace-tlv> ( clock-ids-array -- tlv )
    clock-ids-array length 8 * <byte-array> :> val
    clock-ids-array [| cid idx |
        cid data>> :> cid-bytes
        8 [| i | i cid-bytes nth idx 8 * i + val set-nth ] each-integer
    ] each-index
    TLV-PATH-TRACE val <ptp-tlv> ;

! PathTrace TLV Decoder: Extracts array of clock-identity
:: unpack-path-trace-tlv ( tlv -- clock-ids-array )
    tlv value-field>> :> val
    val length 8 /i :> count
    V{ } clone :> acc
    count [| idx |
        8 <byte-array> :> cid-buf
        8 [| i | idx 8 * i + val nth i cid-buf set-nth ] each-integer
        cid-buf <clock-identity> acc push
    ] each-integer
    acc >array ;
