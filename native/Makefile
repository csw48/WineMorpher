CC := i686-w64-mingw32-gcc
HOST_CC := clang

COMMON_FLAGS := -Wall -Wextra -Iinclude -O2
DLL_FLAGS := $(COMMON_FLAGS) -shared -nostdlib -fno-builtin -Wno-cast-function-type -mno-stack-arg-probe
DLL_LDFLAGS := -Wl,-e,_DllMain@12 -lkernel32 -luser32

BUILD_DIR := build
DLL := $(BUILD_DIR)/winemorpher.dll
TEST := $(BUILD_DIR)/command_tests

DLL_SOURCES := \
	src/Command.c \
	src/Logger.c \
	src/WoW335.c \
	src/dllmain.c

.PHONY: all test dll clean

all: test dll

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

test: $(BUILD_DIR)
	$(HOST_CC) $(COMMON_FLAGS) tests/command_tests.c src/Command.c -o $(TEST)
	$(TEST)

dll: $(BUILD_DIR)
	$(CC) $(DLL_FLAGS) $(DLL_SOURCES) -o $(DLL) $(DLL_LDFLAGS)

clean:
	rm -rf $(BUILD_DIR)
