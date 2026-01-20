#!/bin/bash
# ~/.bashrc :  Managed by salt
#------------------------------------------------------------------------------
# if [ -r /etc/profile ]; then
#   # shellcheck disable=SC1091
#   source /etc/profile
# fi
# if [ -d /etc/profile.d ]; then
#   for _i in /etc/profile.d/*.sh; do
#     if [ -r "${_i}" ]; then
#       # shellcheck disable=SC1090
#       source "${_i}"
#     fi
#   done
#   unset _i
# fi
#------------------------------------------------------------------------------
export HISTFILE="$HOME/.bash_history"
export HISTCONTROL=ignoredups:erasedups
export HISTSIZE=500000
export HISTFILESIZE=500000
export NVM_DIR="/opt/nvm"
export CONDA_AUTO_ACTIVATE_BASE=true
#------------------------------------------------------------------------------
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
# shellcheck disable=SC1091
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
#------------------------------------------------------------------------------
if [ -f /usr/bin/yay ] ; then
  alias yay='yay_clean'
fi
#------------------------------------------------------------------------------
if [ -f /usr/bin/yay ] ; then
  alias yay='yay_clean'
  yay_clean() {
    # Resolve the real yay binary every time
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
fi
rude() {
  # Marker text to stop at; default stays your original
  local marker="${1}"

  if [[ -z ${marker} ]];then
    echo "Usage: rude <marker>"
    return 1
  fi

  _MARK="$marker" git filter-repo --force --message-callback '
import os

marker = os.environ.get("_MARK", "").encode()

lines = message.split(b"\n")
cleaned = []

for l in lines:
    if marker and marker in l:
        break
    cleaned.append(l)

return b"\n".join(cleaned)
'
}
t(){
  if [[ -d ${PWD}/.git ]] ; then
    tmux new -s "$(basename "${PWD}/")"
  fi
}
#------------------------------------------------------------------------------
#eval "$(carapace _carapace)"
#eval "$(rbenv init -)"
#eval "$(atuin init bash)"  # TODO: not working at all
#------------------------------------------------------------------------------
