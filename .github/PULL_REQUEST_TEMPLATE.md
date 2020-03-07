### Description
Brief summary of changes proposed in this pull request.

### Subsystems Touched
- [ ] Protocol Codecs (`escapement/protocol/`)
- [ ] Best Master Clock Algorithm (`escapement/bmca/`)
- [ ] State Machine & Datasets (`escapement/state/`)
- [ ] Timing & Servo Filters (`escapement/servo/`, `escapement/timing/`)
- [ ] Allan Deviation & Stability (`escapement/stability/`)
- [ ] C99 SIMD Acceleration (`c_src/`)
- [ ] Python SDK & Conformance (`python/`)

### Verification Checklist
- [ ] `./scripts/check_no_em_dash.sh` passes with zero em dashes or en dashes
- [ ] `make test` completes with zero failures
- [ ] All new words have stack effect declarations and unit tests
- [ ] Factor 0.102 compilation succeeds without warnings
