# Escapement: IEEE 1588-2019 Precision Time Protocol Engine
# Copyright (C) 2026 Aneesh Krishna. All rights reserved.

.PHONY: all build build-c test test-c test-factor test-python bench simulate stability verify clean help demo

FACTOR ?= /Applications/factor/factor
PYTHON ?= python3

all: build

build: build-c

build-c:
	$(MAKE) -C c_src all

test: test-c test-factor test-python

test-c: build-c
	./c_src/bench_simd

test-factor:
	$(FACTOR) -roots=. -run=escapement test

test-python:
	PYTHONPATH=python $(PYTHON) python/test_escapement.py

bench: build-c
	./c_src/bench_simd
	$(FACTOR) -roots=. -run=escapement.benchmarks

simulate:
	$(FACTOR) -roots=. -run=escapement simulate

stability:
	$(FACTOR) -roots=. -run=escapement stability

bmca:
	$(FACTOR) -roots=. -run=escapement bmca

demo:
	./scripts/demo.sh

verify:
	./scripts/verify.sh

clean:
	$(MAKE) -C c_src clean
	rm -rf __pycache__ python/__pycache__ python/escapement_sdk/__pycache__
	rm -rf build dist *.egg-info python/*.egg-info

help:
	@echo "Escapement Build Targets:"
	@echo "  build        Compile C99 SIMD acceleration library"
	@echo "  test         Run all verification test suites (C, Factor, Python)"
	@echo "  bench        Execute performance microbenchmarks"
	@echo "  simulate     Run 60-epoch network clock synchronization test"
	@echo "  stability    Run Allan deviation (ADEV/MDEV/TDEV) & MTIE analysis"
	@echo "  bmca         Run interactive Best Master Clock election demo"
	@echo "  demo         Run comprehensive interactive showcase"
	@echo "  verify       Execute 7-stage automated end-to-end verification"
	@echo "  clean        Remove built binaries and intermediate files"
