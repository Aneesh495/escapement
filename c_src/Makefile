CC ?= clang
CFLAGS ?= -O3 -Wall -Wextra -pedantic -fPIC -std=c99
UNAME_S := $(shell uname -s)

ifeq ($(UNAME_S),Darwin)
    DYLIB_EXT := dylib
    SHARED_FLAG := -dynamiclib
    ARCH_FLAGS :=
else
    DYLIB_EXT := so
    SHARED_FLAG := -shared
    ARCH_FLAGS :=
endif

LIB_TARGET = ../libescapement_simd.$(DYLIB_EXT)
BENCH_TARGET = bench_simd
TEST_TARGET = test_simd

all: $(LIB_TARGET) $(BENCH_TARGET) $(TEST_TARGET)

$(LIB_TARGET): escapement_simd.c escapement_simd.h
	$(CC) $(CFLAGS) $(SHARED_FLAG) $(ARCH_FLAGS) -o $@ escapement_simd.c -lm

$(BENCH_TARGET): bench_simd.c escapement_simd.c escapement_simd.h
	$(CC) $(CFLAGS) $(ARCH_FLAGS) -o $@ bench_simd.c escapement_simd.c -lm

$(TEST_TARGET): test_simd.c escapement_simd.c escapement_simd.h
	$(CC) $(CFLAGS) $(ARCH_FLAGS) -o $@ test_simd.c escapement_simd.c -lm

clean:
	rm -f $(LIB_TARGET) $(BENCH_TARGET) $(TEST_TARGET) *.o

.PHONY: all clean
