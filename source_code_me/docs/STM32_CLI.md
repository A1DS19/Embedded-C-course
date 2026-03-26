# STM32 Project Generation from the CLI

STM provides two main tools for headless/CLI workflows: **STM32CubeMX** (headless mode) and **STM32CubeCLT** (standalone CLI toolset).

---

## STM32CubeMX Headless Mode

The same GUI tool accepts a script file to generate projects without opening the interface:

```bash
STM32CubeMX -q myscript.script
```

### Example script

```
loadboard NUCLEO-F401RE
setpart STM32F401RETx
project name myproject
project toolchain CMake
project path /home/jose/projects/myproject
generatecode
exit
```

This produces the same output as the GUI: HAL drivers, startup files, linker script, and a `CMakeLists.txt`.

### Available `project toolchain` values

| Value | Output |
|-------|--------|
| `CMake` | CMakeLists.txt |
| `Makefile` | Makefile |
| `STM32CubeIDE` | Eclipse CDT project |

---

## STM32CubeCLT (Command Line Toolset)

A standalone CLI package separate from the GUI. Download from st.com/en/development-tools/stm32cubeclt.html.

Includes:

| Tool | Purpose |
|------|---------|
| `arm-none-eabi-gcc` | ARM cross-compiler |
| `cmake` + `ninja` | Build system |
| `STM32_Programmer_CLI` | Flash firmware to the chip |
| `OpenOCD` | On-chip debugger / GDB server |

Primarily used to **build and flash** existing projects — project generation still relies on CubeMX.

### Flash a binary with STM32_Programmer_CLI

```bash
# Via ST-Link
STM32_Programmer_CLI -c port=SWD -w bin/main.hex -v -rst

# Via USB DFU
STM32_Programmer_CLI -c port=USB1 -w bin/main.bin 0x08000000 -v -rst
```

---

## STM32CubeIDE Headless Build

If you already have a CubeIDE project, build it without opening the GUI:

```bash
/path/to/STM32CubeIDE \
  --launcher.suppressErrors \
  -nosplash \
  -application org.eclipse.cdt.managedbuilder.core.headlessbuild \
  -import /path/to/project \
  -build all
```

---

## Recommended Workflow (CMake + this project)

1. **Use CubeMX GUI once** to configure clocks, peripherals, and pinout for your chip
2. Export as **CMake project**
3. Copy the generated files into this project:
   - `Core/Inc/` → `include/`
   - `Core/Src/` → `src/`
   - `Drivers/` → `vendor/`
   - `*.ld` linker script → `linker/`
4. Add the linker script to `cmake/arm-cortex-m4.cmake`:
   ```cmake
   set(CMAKE_EXE_LINKER_FLAGS_INIT
     "-nostartfiles --specs=nano.specs --specs=nosys.specs -T ${CMAKE_SOURCE_DIR}/linker/STM32F4xx.ld")
   ```
5. From that point on, build and flash entirely from the terminal:
   ```bash
   make embedded
   STM32_Programmer_CLI -c port=SWD -w bin/main.hex -v -rst
   ```

The CubeMX-generated `CMakeLists.txt` is also a good reference for the correct compiler and linker flags for your specific chip variant.
