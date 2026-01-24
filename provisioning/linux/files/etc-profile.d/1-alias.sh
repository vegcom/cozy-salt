#!/bin/bash
# 1-alias.sh

# We silence known edge cases
if ! declare -F append_path &>/dev/null ; then
  alias append_path=safe_append_path
  export append_path
fi

if ! declare -F _comp_deprecate_func  &>/dev/null ; then
  alias _comp_deprecate_func=safe_comp_deprecate_func
  export _comp_deprecate_func
fi

if ! declare -F _comp_deprecate_var  &>/dev/null ; then
  alias _comp_deprecate_var=safe_comp_deprecate_var
  export _comp_deprecate_var
fi

# we provide custom tooling
if ! declare -A cozy-ps  &>/dev/null ; then
  alias cozy-ps='PS_HIDE_KERNEL=1 ps -ao pid,ppid,pcpu,pmem,time,user,group,cmd --sort=+%cpu'
fi

if ! declare -F cozy-call  &>/dev/null ; then
  alias cozy-salt='sudo salt-call state.highstate --force-color --state-output=mixed -l error exclude=None,True,Clean'
fi

if ! declare -A cozy-render  &>/dev/null ; then
  alias cozy-render=cozy_render
fi


if ! declare -A cozy-persist-shell  &>/dev/null ; then
  alias cozy-persist-shell=cozy_persist_shell
fi