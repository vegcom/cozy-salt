#!/bin/bash

# Kubeconfig agg
if [ -z "$BASH_VERSION" ] && [ -z "$ZSH_VERSION" ]; then
  return 1 2>/dev/null || exit 1
fi

if [ ! -z "${KUBECONFIG_DISCOVERED}" ]; then
  return 1 2>/dev/null || exit 1
fi

if [ -n "$ZSH_VERSION" ]; then
  zmodload zsh/pcre 2>/dev/null
  setopt local_options REMATCH_PCRE
else
  setopt local_options RE_MATCH_PCRE
fi

unset kubeconfig_discovered_short kubeconfig_discovered \
  kubeconfig_export kubeconfig_short_names

kubeconfig_discovered_short=()
kubeconfig_discovered=()
kubeconfig_short_names=()

kubeconfig_default="${HOME}/.kube/config"
kubeconfig_export=""

kubeconfig_loader_dbg=${kubeconfig_loader_dbg:-false}
kubeconfig_loader_quiet=${kubeconfig_loader_quiet:-true}
kubeconfig_loader_print=${kubeconfig_loader_print:-false}

if [[ "$kubeconfig_loader_dbg" =~ "^(1|(?i)true)$" ]]; then
  kubeconfig_loader_quiet=false
fi

while read -r cfg; do
  if [[ ! " ${kubeconfig_discovered[(r)$cfg]} " == " ${cfg} " ]]; then

    if [ -s "$cfg" ] && grep -q "apiVersion:" "$cfg" 2>/dev/null && grep -q "clusters:" "$cfg" 2>/dev/null; then
      emoji="🐛"
      msg="sourcing"
      is_valid=true
    else
      emoji="⚠️"
      msg="unsourcable"
      is_valid=false
    fi

    if [[ "$kubeconfig_loader_dbg" =~ "^([1]|(?i)true)$" ]]; then
      printf '[%s] %s %s\n' "${emoji}" "${msg}:" "${cfg#"${HOME}"/.kube/}" 2>/dev/null
    fi

    if [ "$is_valid" = true ]; then
      kubeconfig_discovered+=("${cfg}")
      kubeconfig_discovered_short+=("$(basename "${cfg}")")
    fi

  fi
done < <(find ~/.kube/config ~/.kube/configs/*.conf -maxdepth 1 -mindepth 0 -type f 2>/dev/null)

for _filtered in "${kubeconfig_discovered[@]}"; do

  emoji="⚠️"
  msg="unknown"
  ret="${_filtered}"

  {
    if [[ -z "${kubeconfig_export}" ]]; then
      kubeconfig_export="${ret}"
    else
      kubeconfig_export="${kubeconfig_export}:${ret}"
    fi
  } && {
    if [[ -s "${_filtered}" ]]; then
      emoji="👍"
      kubeconfig_short_names+=("${_filtered#"${HOME}"/.kube/}")
      _list=$(printf '%s\n' "${kubeconfig_short_names[@]}" | jq -RsCc 'split("\n") | map(select(length > 0)) | reduce .[] as $item ([[], {}]; if ($item | contains("/")) then ($item | split("/")) as $p | .[1][$p[0]] += [$p[1]] else .[0] += [$item] end) | if (.[1] | length > 0) then .[0] + [.[1]] else .[0] end' 2>/dev/null)
      msg="extending: kubeconfig_export:${#kubeconfig_short_names[@]} - ${_list}"
      true
    else
      emoji="❌"
      msg="failed"
      false
    fi
  }

  if [[ "$kubeconfig_loader_quiet" =~ "^(|(?i)false)$" ]] || [[ "${kubeconfig_loader_print}" =~ "^(|(?i)true)$" ]]; then
      printf '[%s] %s %s\n' "${emoji}" "${msg}" 2>/dev/null
  fi

done

export KUBECONFIG="${kubeconfig_export}"
export KUBECONFIG_DISCOVERED=1
