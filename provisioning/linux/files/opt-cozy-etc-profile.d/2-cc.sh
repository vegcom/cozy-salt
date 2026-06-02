#!/bin/sh
# Managed by Salt - DO NOT EDIT MANUALLY

# colorgcc
[ -d /usr/lib/colorgcc/bin ] && export PATH="/usr/lib/colorgcc/bin:$PATH"

# ccache
if [ -d /usr/lib/ccache/bin ] ; then
  export __CCACHE_PATH="/usr/lib/ccache/bin"
elif [ -d /usr/lib/ccache ] && [ ! -d /usr/lib/ccache/bin ] ; then
  export __CCACHE_PATH="/usr/lib/ccache"
fi

# ccache -> distcc
if [ -e "${__CCACHE_PATH}" ];then
  export CCACHE_PREFIX="ccache"
  export PATH="$__CCACHE_PATH:$PATH"
  if [ -e "$(which distcc)" ] ; then
    export CCACHE_PREFIX="distcc"
  fi
fi

if [ -e "$(which ccache)" ] ; then
  export CCACHE_DIR="${TMPDIR}/cache/ccache"
  export CCACHE_SLOPPINESS="locale,time_macros"
  export CCACHE_PATH="/usr/bin"
  export CCACHE_MAXSIZE="8G"
  export CCACHE_COMPRESS=true
  export CC="ccache gcc"
  export CXX="ccache g++"
  export LD="ccache ld"
  export FC="ccache gfortran"
  export PATH="/usr/lib/ccache/bin:$PATH"
fi
