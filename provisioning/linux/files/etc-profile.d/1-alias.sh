#!/bin/sh
# Managed by Salt - DO NOT EDIT MANUALLY

# We silence known edge cases
if ! command -v append_path 1>/dev/null 2>/dev/null ; then
  alias append_path=safe_append_path
	export append_path
fi

if ! command -v _comp_deprecate_func  1>/dev/null 2>/dev/null ; then
  alias _comp_deprecate_func=safe_comp_deprecate_func
fi

if ! command -v _comp_deprecate_var  1>/dev/null 2>/dev/null ; then
  alias _comp_deprecate_var=safe_comp_deprecate_var
fi

# we provide custom tooling
if ! command -v cozy-ps  1>/dev/null 2>/dev/null ; then
  alias cozy-ps='PS_HIDE_KERNEL=1 ps -ao pid,ppid,pcpu,pmem,time,user,group,cmd --sort=-%cpu'
fi

if ! command -v cozy-salt  1>/dev/null 2>/dev/null ; then
  alias cozy-salt='sudo salt-call state.highstate --force-color --state-output=mixed -l error exclude=None,True,Clean'
fi

if ! command -v cozy-render  1>/dev/null 2>/dev/null ; then
  alias cozy-render=cozy_render
fi

if ! command -v cozy-persist-shell  1>/dev/null 2>/dev/null ; then
  alias cozy-persist-shell=cozy_persist_shell
fi
