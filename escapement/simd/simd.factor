! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Factor FFI bindings and fallback implementations for C99 SIMD acceleration.

USING: accessors alien alien.c-types alien.data alien.libraries
alien.syntax byte-arrays combinators continuations kernel locals
math math.functions math.parser sequences system ;
IN: escapement.simd

<<
"escapement_simd" {
    { [ os macos? ] [ "libescapement_simd.dylib" ] }
    { [ os unix? ]  [ "libescapement_simd.so" ] }
    { [ os windows? ] [ "escapement_simd.dll" ] }
} cond [ cdecl add-library ] when*
>>

LIBRARY: escapement_simd

FUNCTION: ulonglong escapement_nanotime_monotonic ( )
FUNCTION: ulonglong escapement_nanotime_realtime ( )
FUNCTION: int escapement_validate_header_simd ( void* data, size_t len )
FUNCTION: int escapement_compute_allan_variance_simd ( double* fractional_freqs, size_t count, size_t stride, double* out_variance )
FUNCTION: int escapement_compute_modified_allan_variance_simd ( double* phase_samples, size_t count, size_t tau_step, double* out_mvar )
FUNCTION: int escapement_kalman_step_simd ( double* state_2, double* cov_2x2, double meas_phase, double dt, double q_phase, double q_freq, double r_meas )
FUNCTION: int escapement_rolling_median_filter ( double* in_samples, double* out_filtered, size_t count, size_t window_size )
FUNCTION: longlong escapement_unpack_correction_field ( void* buf_8bytes )
FUNCTION: void escapement_pack_correction_field ( longlong scaled_ns, void* out_8bytes )

! Monotonic timestamp with high-resolution system fallback
:: fast-nanotime-monotonic ( -- ns )
    [ escapement_nanotime_monotonic ]
    [ drop nano-count ] recover ;

! Realtime timestamp with system fallback
:: fast-nanotime-realtime ( -- ns )
    [ escapement_nanotime_realtime ]
    [ drop nano-count ] recover ;

! Fast header validation with pure Factor fallback
:: fast-validate-header ( byte-arr -- ? )
    [
        byte-arr byte-arr length escapement_validate_header_simd 0 =
    ] [
        drop
        byte-arr length 34 >= [
            byte-arr 0 nth 0x0F bitand 0x0D <=
            byte-arr 1 nth 0x0F bitand 2 = and
            byte-arr 2 nth 8 shift byte-arr 3 nth bitor :> msg-len
            msg-len 34 >= msg-len byte-arr length <= and and
        ] [ f ] if
    ] recover ;
