! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Big-endian binary serialization and parsing primitives.

USING: byte-arrays kernel locals math sequences ;
IN: escapement.common.endian

! Read 8-bit unsigned integer at offset
:: get-be-uint8 ( byte-arr offset -- val )
    offset byte-arr nth ;

! Read 8-bit signed integer at offset
:: get-be-int8 ( byte-arr offset -- val )
    offset byte-arr nth
    dup 0x80 bitand 0 = [ ] [ 0x100 - ] if ;

! Read 16-bit big-endian unsigned integer at offset
:: get-be-uint16 ( byte-arr offset -- val )
    offset byte-arr nth 8 shift
    offset 1 + byte-arr nth bitor ;

! Read 16-bit big-endian signed integer at offset
:: get-be-int16 ( byte-arr offset -- val )
    byte-arr offset get-be-uint16
    dup 0x8000 bitand 0 = [ ] [ 0x10000 - ] if ;

! Read 32-bit big-endian unsigned integer at offset
:: get-be-uint32 ( byte-arr offset -- val )
    offset byte-arr nth 24 shift
    offset 1 + byte-arr nth 16 shift bitor
    offset 2 + byte-arr nth 8 shift bitor
    offset 3 + byte-arr nth bitor ;

! Read 32-bit big-endian signed integer at offset
:: get-be-int32 ( byte-arr offset -- val )
    byte-arr offset get-be-uint32
    dup 0x80000000 bitand 0 = [ ] [ 0x100000000 - ] if ;

! Read 48-bit big-endian unsigned integer at offset (used for PTP seconds)
:: get-be-uint48 ( byte-arr offset -- val )
    byte-arr offset get-be-uint16 32 shift
    byte-arr offset 2 + get-be-uint32 bitor ;

! Read 64-bit big-endian unsigned integer at offset
:: get-be-uint64 ( byte-arr offset -- val )
    byte-arr offset get-be-uint32 32 shift
    byte-arr offset 4 + get-be-uint32 bitor ;

! Read 64-bit big-endian signed integer at offset (used for correctionField)
:: get-be-int64 ( byte-arr offset -- val )
    byte-arr offset get-be-uint64
    dup 0x8000000000000000 bitand 0 = [ ] [ 0x10000000000000000 - ] if ;

! Write 8-bit integer into byte-array at offset
:: set-be-uint8 ( val byte-arr offset -- )
    val 0xFF bitand offset byte-arr set-nth ;

! Write 16-bit integer in big-endian into byte-array at offset
:: set-be-uint16 ( val byte-arr offset -- )
    val -8 shift 0xFF bitand offset byte-arr set-nth
    val 0xFF bitand offset 1 + byte-arr set-nth ;

! Write 16-bit signed integer in big-endian into byte-array at offset
:: set-be-int16 ( val byte-arr offset -- )
    val byte-arr offset set-be-uint16 ;

! Write 32-bit integer in big-endian into byte-array at offset
:: set-be-uint32 ( val byte-arr offset -- )
    val -24 shift 0xFF bitand offset byte-arr set-nth
    val -16 shift 0xFF bitand offset 1 + byte-arr set-nth
    val -8 shift 0xFF bitand offset 2 + byte-arr set-nth
    val 0xFF bitand offset 3 + byte-arr set-nth ;

! Write 32-bit signed integer in big-endian into byte-array at offset
:: set-be-int32 ( val byte-arr offset -- )
    val byte-arr offset set-be-uint32 ;

! Write 48-bit integer in big-endian into byte-array at offset
:: set-be-uint48 ( val byte-arr offset -- )
    val -32 shift byte-arr offset set-be-uint16
    val 0xFFFFFFFF bitand byte-arr offset 2 + set-be-uint32 ;

! Write 64-bit integer in big-endian into byte-array at offset
:: set-be-uint64 ( val byte-arr offset -- )
    val -32 shift 0xFFFFFFFF bitand byte-arr offset set-be-uint32
    val 0xFFFFFFFF bitand byte-arr offset 4 + set-be-uint32 ;

! Write 64-bit signed integer in big-endian into byte-array at offset
:: set-be-int64 ( val byte-arr offset -- )
    val byte-arr offset set-be-uint64 ;

! Pack integer into new 1-byte byte-array
: >be-uint8 ( val -- byte-arr )
    1 <byte-array> [ 0 set-be-uint8 ] keep ;

! Pack integer into new 2-byte byte-array
: >be-uint16 ( val -- byte-arr )
    2 <byte-array> [ 0 set-be-uint16 ] keep ;

! Pack integer into new 4-byte byte-array
: >be-uint32 ( val -- byte-arr )
    4 <byte-array> [ 0 set-be-uint32 ] keep ;

! Pack integer into new 6-byte byte-array
: >be-uint48 ( val -- byte-arr )
    6 <byte-array> [ 0 set-be-uint48 ] keep ;

! Pack integer into new 8-byte byte-array
: >be-uint64 ( val -- byte-arr )
    8 <byte-array> [ 0 set-be-uint64 ] keep ;
