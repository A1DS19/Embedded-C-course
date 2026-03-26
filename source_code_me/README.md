# source_code_me

Modern C23 project with cross-platform host builds and ARM Cortex-M4 cross-compilation support.

## Features

- **C23** with GCC 13+ / Clang 15+
- **Cross-platform host builds** (macOS, Linux, Windows)
- **ARM Cortex-M4 cross-compilation** producing `.elf`, `.hex`, and `.bin`
- **Memory safety** with AddressSanitizer and Valgrind
- **Static analysis** with cppcheck, clang-tidy, and scan-build
- **Code coverage** with gcov/lcov
- **Debugger integration** — lldb (macOS), gdb (Linux)
- **Automated testing** framework

---

## Prerequisites

### macOS

```bash
# Xcode command line tools (clang, lldb, make)
xcode-select --install

# CMake, cppcheck, and optional tools
brew install cmake cppcheck lcov

# ARM cross-compiler (for embedded builds)
brew install --cask gcc-arm-embedded
```

### Fedora

```bash
# Core build tools
sudo dnf install gcc cmake make

# Optional tools
sudo dnf install clang clang-tools-extra   # clang-format, clang-tidy
sudo dnf install cppcheck
sudo dnf install valgrind
sudo dnf install gdb
sudo dnf install lcov

# ARM cross-compiler (for embedded builds)
sudo dnf install arm-none-eabi-gcc arm-none-eabi-newlib
```

> To verify everything is in order: `make check`

---

## Quick Start

```bash
make          # build (default)
make run      # build and run
make debug    # build and launch debugger (lldb on macOS, gdb on Linux)
              # once inside lldb/gdb, type 'gui' for the TUI
make test     # build and run unit tests
make clean    # remove build artifacts
make distclean # full clean including CMake cache
```

---

## Build Targets

### Building & Running
| Target | Description |
|--------|-------------|
| `make build` | Configure (if needed) and build |
| `make rebuild` | Clean then build |
| `make release` | Optimized build (`-O3`, no sanitizers) |
| `make run` | Build and run the main executable |
| `make embedded` | Cross-compile for ARM Cortex-M4 |

### Testing & Quality
| Target | Description |
|--------|-------------|
| `make test` | Build and run unit tests |
| `make format` | Format all `.c`/`.h` with clang-format |
| `make analyze` | Run static analysis |
| `make coverage` | Generate gcov/lcov coverage report |
| `make memcheck` | Run Valgrind memory check (Linux/macOS) |
| `make valgrind` | Comprehensive Valgrind analysis |

### Debugging
| Target | Description |
|--------|-------------|
| `make debug` | Build (Debug) and launch lldb/gdb |

Once inside the debugger, type `gui` to enter the TUI.

### Maintenance
| Target | Description |
|--------|-------------|
| `make clean` | Remove build artifacts |
| `make distclean` | Full clean including CMake cache |
| `make check` | Verify tools are installed |
| `make info` | Show project configuration |
| `make deps` | List required and optional dependencies |

---

## How the CMake Build Works

### Host build (`CMakeLists.txt`)

`cmake -B build -S .` configures a native build for your machine. Key decisions:

- **Sources** are globbed from `src/*.c` — add a `.c` file there and it is automatically compiled into the `main` executable.
- **Headers** live in `include/` and are automatically on the include path.
- **Compiler warnings** are set per compiler (GCC, Clang, MSVC) as `PRIVATE` options on the `main` target.
- **Sanitizers** (AddressSanitizer + UBSan) are enabled in Debug builds via `ENABLE_SANITIZERS=ON` and disabled automatically when cross-compiling or when using Valgrind.
- **`-march=native`** is applied only in Release builds on the host — it is skipped when cross-compiling so it cannot accidentally target your Mac's CPU.
- **Threads and math (`-lm`)** are linked on the host only; they are not available on bare-metal.
- **`compile_commands.json`** is copied to the project root after every build so your LSP (clangd) picks it up.
- **Tests** in `tests/*.c` are compiled into a separate `test_main` executable. Source files in `src/` (except `main.c`) are compiled into a static library that the test binary links against.
- **Vendor libraries** dropped into `vendor/<name>/src/` and `vendor/<name>/include/` are automatically detected and compiled into a `vendor` static library with warnings suppressed.

### Embedded cross-compile (`cmake/arm-cortex-m4.cmake`)

`make embedded` passes this file to CMake via `-DCMAKE_TOOLCHAIN_FILE`. The toolchain file tells CMake:

| Setting | Value | Why |
|---------|-------|-----|
| `CMAKE_SYSTEM_NAME` | `Generic` | Bare-metal — no OS |
| `CMAKE_C_COMPILER` | `arm-none-eabi-gcc` | Cross-compiler for ARM |
| `CMAKE_TRY_COMPILE_TARGET_TYPE` | `STATIC_LIBRARY` | Stops CMake trying to link a test executable against the host system |
| `-mcpu=cortex-m4` | CPU target | Enables M4-specific instructions |
| `-mthumb` | Thumb-2 ISA | Compact 16/32-bit instruction encoding used by all Cortex-M |
| `-mfpu=fpv4-sp-d16` | FPU variant | Single-precision hardware FPU on the M4F |
| `-mfloat-abi=hard` | Hard float ABI | Passes floats in FPU registers (faster than `soft`) |
| `--specs=nano.specs` | Newlib-nano | Minimal C standard library for embedded |
| `--specs=nosys.specs` | Stub syscalls | Provides empty stubs for `_exit`, `_write`, etc. |

After a successful embedded build, `bin/` will contain:

```
bin/main.elf   — for debugging with OpenOCD + GDB
bin/main.hex   — Intel HEX, used by most flashers
bin/main.bin   — raw binary, used by some flashers
```

> If your chip requires a linker script (defines flash/RAM regions), add it to the toolchain file:
> ```cmake
> set(CMAKE_EXE_LINKER_FLAGS_INIT "... -T ${CMAKE_SOURCE_DIR}/linker/STM32F407.ld")
> ```
> STM32CubeIDE and most vendor SDKs ship a `.ld` file for each chip.

---

## Project Structure

```
source_code_me/
├── Makefile               # Build automation (wraps CMake)
├── CMakeLists.txt         # CMake configuration (host + embedded)
├── cmake/
│   └── arm-cortex-m4.cmake  # ARM Cortex-M4 toolchain file
│
├── src/                   # Application source files (.c)
│   └── main.c
├── include/               # Header files (.h)
├── tests/                 # Unit test sources
│   └── test_main.c
├── vendor/                # Third-party libraries
│   └── <lib>/
│       ├── src/
│       └── include/
│
├── bin/                   # Compiled executables and firmware images
├── build/                 # CMake build directory (auto-generated)
├── lib/                   # Static/shared libraries
├── scripts/               # Helper shell scripts
└── docs/                  # Generated documentation (Doxygen)
```

---

## Testing

Place test files in `tests/`. Each file must have a `main` function:

```c
// tests/test_main.c
#include <stdio.h>

int main(void) {
    // call your test functions here
    printf("All tests passed.\n");
    return 0;
}
```

Functions under test live in `src/` (not `main.c`). CMake compiles them into a static library and links it into the `test_main` binary automatically.

Run with:

```bash
make test
```
