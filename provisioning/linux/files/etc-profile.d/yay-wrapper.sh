#!/bin/sh
# Managed by Salt - DO NOT EDIT MANUALLY

# /etc/profile.d/yay-wrapper.sh: YAY AUR helper environment isolation (Arch Linux only)
# Deployed by salt to clean yay execution environment



# Only apply on Arch Linux / derivative systems
if [ ! -f /etc/arch-release ] ; then
  if [ ! -f /etc/artix-release ] ; then
    return 0
  fi
fi


#------------------------------------------------------------------------------
# YAY WRAPPER: Clean environment for AUR operations
#------------------------------------------------------------------------------
alias yay='yay_clean'

yay_clean() {
  # Resolve the real yay binary every time with isolated environment
  env -i \
    PATH=/usr/lib/ccache/bin:/usr/bin:/bin:/usr/sbin:/sbin \
    HOME="$HOME" USER="$USER" SHELL="$SHELL" \
    LANG=en_US.UTF-8 \
    DISTCC_HOSTS="${DISTCC_HOSTS:-}" \
    CCACHE_PREFIX="${CCACHE_PREFIX:-distcc}" \
    CCACHE_PATH="${CCACHE_PATH:-/usr/bin}" \
    CCACHE_DIR="${CCACHE_DIR:-$HOME/.cache/ccache}" \
    PYTHON=/usr/bin/python PYTHONHOME= PYTHONPATH= \
    CONDA_PREFIX= CONDA_DEFAULT_ENV= CONDA_EXE= \
    NVM_DIR= NODE_PATH= npm_config_prefix= \
    CARGO_HOME= RUSTUP_HOME= \
    GOPATH= GOROOT= \
    GEM_HOME= GEM_PATH= \
    PERL5LIB= PERL_LOCAL_LIB_ROOT= PERL_MB_OPT= PERL_MM_OPT= \
    JAVA_HOME= \
    QT_PLUGIN_PATH= QT_QPA_PLATFORMTHEME= QT_STYLE_OVERRIDE= \
    GIT_CONFIG=/dev/null \
    "/usr/bin/yay" "$@"
}

yay_fix() {
  # Rebuild all packages in clean environment
  # shellcheck disable=SC2046
  env -i \
    PATH=/usr/lib/ccache/bin:/usr/bin:/bin:/usr/sbin:/sbin \
    HOME="$HOME" USER="$USER" SHELL="$SHELL" \
    LANG=en_US.UTF-8 \
    DISTCC_HOSTS="${DISTCC_HOSTS:-}" \
    CCACHE_PREFIX="${CCACHE_PREFIX:-distcc}" \
    CCACHE_PATH="${CCACHE_PATH:-/usr/bin}" \
    CCACHE_DIR="${CCACHE_DIR:-$HOME/.cache/ccache}" \
    PYTHON=/usr/bin/python PYTHONHOME= PYTHONPATH= \
    CONDA_PREFIX= CONDA_DEFAULT_ENV= CONDA_EXE= \
    NVM_DIR= NODE_PATH= npm_config_prefix= \
    CARGO_HOME= RUSTUP_HOME= \
    GOPATH= GOROOT= \
    GEM_HOME= GEM_PATH= \
    PERL5LIB= PERL_LOCAL_LIB_ROOT= PERL_MB_OPT= PERL_MM_OPT= \
    JAVA_HOME= \
    QT_PLUGIN_PATH= QT_QPA_PLATFORMTHEME= QT_STYLE_OVERRIDE= \
    GIT_CONFIG=/dev/null \
    "/usr/bin/yay" -S --noconfirm --asexplicit --answerclean All --rebuildall \
    $(/usr/bin/yay -Qneq)

  # Rebuild dependency packages
  # shellcheck disable=SC2046
  env -i \
    PATH=/usr/lib/ccache/bin:/usr/bin:/bin:/usr/sbin:/sbin \
    HOME="$HOME" USER="$USER" SHELL="$SHELL" \
    LANG=en_US.UTF-8 \
    DISTCC_HOSTS="${DISTCC_HOSTS:-}" \
    CCACHE_PREFIX="${CCACHE_PREFIX:-distcc}" \
    CCACHE_PATH="${CCACHE_PATH:-/usr/bin}" \
    CCACHE_DIR="${CCACHE_DIR:-$HOME/.cache/ccache}" \
    PYTHON=/usr/bin/python PYTHONHOME= PYTHONPATH= \
    CONDA_PREFIX= CONDA_DEFAULT_ENV= CONDA_EXE= \
    NVM_DIR= NODE_PATH= npm_config_prefix= \
    CARGO_HOME= RUSTUP_HOME= \
    GOPATH= GOROOT= \
    GEM_HOME= GEM_PATH= \
    PERL5LIB= PERL_LOCAL_LIB_ROOT= PERL_MB_OPT= PERL_MM_OPT= \
    JAVA_HOME= \
    QT_PLUGIN_PATH= QT_QPA_PLATFORMTHEME= QT_STYLE_OVERRIDE= \
    GIT_CONFIG=/dev/null \
    "/usr/bin/yay" -S --noconfirm --asdeps --answerclean All --rebuildall \
    $(/usr/bin/yay -Qndq)
}


BUILDDIR=${HOME}/scratch/yay
export BUILDDIR
