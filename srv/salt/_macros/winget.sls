{#- Winget scope resolution macro

Purpose: Replace the hand-maintained noscope package list with a live
lookup against cozy-winget's manifest server. Winget errors ("No
applicable installer found") if you pass --scope machine to a package
whose manifest never declared a machine-capable installer, so we need
to know, per package, what scope(s) it actually supports before we
decide whether to install it system-wide or per-user.

Classification, one tier deep:
  machine - installer declares machine scope -> install once, system
            winget.exe, --scope machine
  user    - no machine scope, but declares user scope -> install per
            logged-in user, --scope user
  none    - package declares no scope at all -> install per logged-in
            user, no --scope flag (winget picks its own default)

Queries winget-manifest's /v1/scopes endpoint once, batching every
package ID from the whole windows.winget pillar tree into a single
POST rather than one HTTP call per package.

Usage:
  {%- from '_macros/winget.sls' import classify_winget_scopes with context %}
  {%- set scopes = classify_winget_scopes(all_winget_package_ids) | load_json %}
  {%- set machine_pkgs = pkgs | select('in', scopes.machine) | list %}
  {%- set user_pkgs = pkgs | select('in', scopes.user) | list %}
  {%- set none_pkgs = pkgs | select('in', scopes.none) | list %}

If the manifest server is unreachable, falls back to treating every
package as machine-scoped, so a temporary outage never silently
strands packages - worst case a handful of --scope machine calls fail
loudly and show up as failed states instead of the render breaking. #}

{%- set _manifest_url = salt['pillar.get']('windows:winget:manifest_url', 'http://winget-manifest:8080') %}

{%- macro classify_winget_scopes(package_ids) -%}
  {%- set result = {'machine': [], 'user': [], 'none': []} -%}
  {%- if package_ids | length > 0 -%}
    {%- set payload = {'ids': package_ids | unique | list} | tojson -%}
    {%- set resp = salt['http.query'](
          _manifest_url ~ '/v1/scopes',
          method='POST',
          data=payload,
          header_dict={'Content-Type': 'application/json'},
          decode=True,
          decode_type='json',
          raise_error=False
        ) -%}
    {%- if resp and resp.get('dict') -%}
      {%- for pkg_id, info in resp['dict'].items() -%}
        {%- if info is mapping and info.get('SupportsMachine') -%}
          {%- do result['machine'].append(pkg_id) -%}
        {%- elif info is mapping and 'user' in (info.get('Scopes') or []) -%}
          {%- do result['user'].append(pkg_id) -%}
        {%- else -%}
          {%- do result['none'].append(pkg_id) -%}
        {%- endif -%}
      {%- endfor -%}
    {%- else -%}
      {%- do salt['log.warning']('winget.sls macro: could not reach manifest server at ' ~ _manifest_url ~ ', assuming all packages support machine scope') -%}
      {%- do result.update({'machine': package_ids | unique | list}) -%}
    {%- endif -%}
  {%- endif -%}
  {{ result | tojson }}
{%- endmacro -%}
