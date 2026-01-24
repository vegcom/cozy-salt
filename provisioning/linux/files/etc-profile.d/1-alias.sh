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
