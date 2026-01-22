#!/bin/bash
# /etc/profile.d/yay-wrapper.sh: YAY AUR helper environment isolation (Arch Linux only)
# Deployed by salt to clean yay execution environment

# Only apply on Arch Linux / derivative systems
if [[ ! -f /etc/arch-release ]] && [[ ! -f /etc/artix-release ]]; then
  return 0
fi

#------------------------------------------------------------------------------
# YAY WRAPPER: Clean environment for AUR operations
#------------------------------------------------------------------------------
alias yay='yay_clean'

yay_clean() {
  # Resolve the real yay binary every time with isolated environment
  env -i \
    PATH=/usr/bin:/bin:/usr/sbin:/sbin \
    HOME="$HOME" USER="$USER" SHELL="$SHELL" \
    LANG=en_US.UTF-8 \
    PYTHON=/usr/bin/python PYTHONHOME= PYTHONPATH= \
    CONDA_PREFIX= CONDA_DEFAULT_ENV= CONDA_EXE= \
    NVM_DIR= NODE_PATH= npm_config_prefix= \
    CARGO_HOME= RUSTUP_HOME= \
    GOPATH= GOROOT= \
    GEM_HOME= GEM_PATH= \
    PERL5LIB= PERL_LOCAL_LIB_ROOT= PERL_MB_OPT= PERL_MM_OPT= \
    JAVA_HOME= \
    QT_PLUGIN_PATH= QT_QPA_PLATFORMTHEME= QT_STYLE_OVERRIDE= \
    CC= CXX= LD= AR= NM= STRIP= OBJCOPY= OBJDUMP= \
    CFLAGS= CXXFLAGS= LDFLAGS= CPPFLAGS= \
    MAKEFLAGS="-j$(nproc)" \
    "/usr/bin/yay" "$@"
}

yay_fix() {
  # Rebuild all packages in clean environment
  # shellcheck disable=SC2046
  env -i \
    PATH=/usr/bin:/bin:/usr/sbin:/sbin \
    HOME="$HOME" USER="$USER" SHELL="$SHELL" \
    LANG=en_US.UTF-8 \
    PYTHON=/usr/bin/python PYTHONHOME= PYTHONPATH= \
    CONDA_PREFIX= CONDA_DEFAULT_ENV= CONDA_EXE= \
    NVM_DIR= NODE_PATH= npm_config_prefix= \
    CARGO_HOME= RUSTUP_HOME= \
    GOPATH= GOROOT= \
    GEM_HOME= GEM_PATH= \
    PERL5LIB= PERL_LOCAL_LIB_ROOT= PERL_MB_OPT= PERL_MM_OPT= \
    JAVA_HOME= \
    QT_PLUGIN_PATH= QT_QPA_PLATFORMTHEME= QT_STYLE_OVERRIDE= \
    CC= CXX= LD= AR= NM= STRIP= OBJCOPY= OBJDUMP= \
    CFLAGS= CXXFLAGS= LDFLAGS= CPPFLAGS= \
    MAKEFLAGS="-j$(nproc)" \
    "/usr/bin/yay" -S --noconfirm --asexplicit --answerclean All --rebuildall \
    $(/usr/bin/yay -Qneq)

  # Rebuild dependency packages
  # shellcheck disable=SC2046
  env -i \
    PATH=/usr/bin:/bin:/usr/sbin:/sbin \
    HOME="$HOME" USER="$USER" SHELL="$SHELL" \
    LANG=en_US.UTF-8 \
    PYTHON=/usr/bin/python PYTHONHOME= PYTHONPATH= \
    CONDA_PREFIX= CONDA_DEFAULT_ENV= CONDA_EXE= \
    NVM_DIR= NODE_PATH= npm_config_prefix= \
    CARGO_HOME= RUSTUP_HOME= \
    GOPATH= GOROOT= \
    GEM_HOME= GEM_PATH= \
    PERL5LIB= PERL_LOCAL_LIB_ROOT= PERL_MB_OPT= PERL_MM_OPT= \
    JAVA_HOME= \
    QT_PLUGIN_PATH= QT_QPA_PLATFORMTHEME= QT_STYLE_OVERRIDE= \
    CC= CXX= LD= AR= NM= STRIP= OBJCOPY= OBJDUMP= \
    CFLAGS= CXXFLAGS= LDFLAGS= CPPFLAGS= \
    MAKEFLAGS="-j$(nproc)" \
    "/usr/bin/yay" -S --noconfirm --asdeps --answerclean All --rebuildall \
    $(/usr/bin/yay -Qndq)
}
