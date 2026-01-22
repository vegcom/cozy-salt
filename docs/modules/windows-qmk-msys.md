# QMK MSYS Environment

MSYS2-based development environment for mechanical keyboard firmware (QMK).

## Location

- **State**: `srv/salt/windows/qmk_msys.sls`
- **Include**: `windows.init`

## Purpose

QMK MSYS provides:
- Compiler toolchain for ARM microcontrollers
- Build environment for keyboard firmware
- Serial communication tools
- Python environment for QMK utilities

## Installation

Installs QMK MSYS from official releases:
https://msys.qmk.fm/

| Item | Location |
|------|----------|
| MSYS2 | `C:\opt\qmk_msys` |
| Compiler | ARM GCC, STM32 tools |
| Build tools | Make, CMake, ninja |

## Included Tools

- **arm-none-eabi-gcc**: ARM Cortex M compiler
- **dfu-util**: Bootloader flashing
- **avrdude**: AVR flashing
- **Python**: QMK CLI and scripts
- **Git**: Version control
- **Make**: Build system

## Usage

```bash
qmk setup                          # Initialize QMK
qmk compile -kb planck -km default # Compile firmware
qmk flash -kb planck -km default  # Compile and flash
qmk new-keyboard                   # Create keyboard
```

## Pillar Configuration

```yaml
qmk_msys:
  version: latest
  home_dir: C:\opt\qmk_msys
```

## Notes

- MSYS2-based (not Cygwin)
- Standalone environment (isolated from system)
- Can coexist with WSL toolchain
- Keyboard firmware development only
- Requires bootloader-specific flash tool
