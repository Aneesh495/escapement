! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Network impairment channel model: asymmetry, jitter, queuing delay, and loss.

USING: accessors kernel locals math math.functions math.order
random escapement.common.types escapement.timing.timestamps ;
IN: escapement.network.impairment

TUPLE: impairment-channel
    { forward-base-delay-ns float initial: 50000.0 }
    { reverse-base-delay-ns float initial: 50000.0 }
    { jitter-stddev-ns float initial: 250.0 }
    { burst-prob float initial: 0.05 }
    { burst-delay-ns float initial: 15000.0 }
    { drop-rate float initial: 0.0 } ;

:: <impairment-channel> ( fwd-ns rev-ns jitter-ns burst-p burst-ns drop-r -- chan )
    fwd-ns rev-ns jitter-ns burst-p burst-ns drop-r impairment-channel boa ;

:: default-impairment-channel ( -- chan )
    50000.0 52000.0 200.0 0.02 10000.0 0.0 <impairment-channel> ;

! Generate synthetic zero-mean jitter
:: sample-jitter ( stddev -- jitter-ns )
    0.0 :> s!
    12 [| i | 1.0 random s + s! ] each-integer
    s 6.0 - stddev * ;

! Calculate transit delay across channel for forward direction
:: channel-forward-delay ( chan -- delay-ns dropped? )
    chan drop-rate>> 0.0 > [
        1.0 random chan drop-rate>> < [ 0.0 t ] [
            chan forward-base-delay-ns>>
            chan jitter-stddev-ns>> sample-jitter +
            1.0 random chan burst-prob>> < [ chan burst-delay-ns>> + ] when
            0.0 max f
        ] if
    ] [
        chan forward-base-delay-ns>>
        chan jitter-stddev-ns>> sample-jitter +
        1.0 random chan burst-prob>> < [ chan burst-delay-ns>> + ] when
        0.0 max f
    ] if ;

! Calculate transit delay across channel for reverse direction
:: channel-reverse-delay ( chan -- delay-ns dropped? )
    chan drop-rate>> 0.0 > [
        1.0 random chan drop-rate>> < [ 0.0 t ] [
            chan reverse-base-delay-ns>>
            chan jitter-stddev-ns>> sample-jitter +
            1.0 random chan burst-prob>> < [ chan burst-delay-ns>> + ] when
            0.0 max f
        ] if
    ] [
        chan reverse-base-delay-ns>>
        chan jitter-stddev-ns>> sample-jitter +
        1.0 random chan burst-prob>> < [ chan burst-delay-ns>> + ] when
        0.0 max f
    ] if ;
