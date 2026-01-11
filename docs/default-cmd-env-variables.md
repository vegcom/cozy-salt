# Default cmd.run Environment Variables - Implementation Guide

**Status**: Planning | **Task**: Create Jinja macro for Windows cmd.run with standard env

---

## Overview

Standardize Windows environment variables across all `cmd.run` state calls by creating a reusable Jinja macro. This eliminates repetition and ensures consistent tool paths (NVM_HOME, NVM_SYMLINK, CONDA_HOME, etc.) throughout the salt configuration.

---

## Problem Statement

Currently, Windows states that use `cmd.run` and depend on custom tool installations must manually set environment variables:

```sls
test_nvm:
  cmd.run:
    - name: |
        set "NVM_HOME=%USERPROFILE%\.nvm"
        set "NVM_SYMLINK=%ProgramFiles%\nodejs"
        set "CONDA_HOME=%ProgramFiles%\miniforge"
        nvm install lts
```

This leads to:
- **Code duplication** across multiple states
- **Inconsistent paths** if environment variables change
- **Maintenance burden** when adding new tools
- **Fragility** if paths diverge between states

---

## Implementation Options

### Option 1: Jinja Macro in `srv/salt/macros/windows.sls` (RECOMMENDED)

**Pros:**
- Cleanest approach, DRY principle
- Single source of truth for Windows tool paths
- Easy to extend with new environment variables
- States import and use simply

**Cons:**
- Requires all states to import the macro

**Implementation:**

```jinja
{%- macro win_cmd(command, env_vars=None) %}
{%- set default_env = {
  'NVM_HOME': '%USERPROFILE%\.nvm',
  'NVM_SYMLINK': '%ProgramFiles%\nodejs',
  'CONDA_HOME': '%ProgramFiles%\miniforge'
} %}
{%- set merged_env = default_env.update(env_vars or {}) %}
{%- set env_block = [] %}
{%- for key, value in default_env.items() %}
  {%- do env_block.append('set "' + key + '=' + value + '"') %}
{%- endfor %}
{{ env_block | join('\n') }}
{{ command }}
{%- endmacro %}
```

**Usage in states:**

```sls
{%- from "macros/windows.sls" import win_cmd %}

test_nvm:
  cmd.run:
    - name: |
        {{ win_cmd('nvm install lts') }}
```

---

### Option 2: Custom State Module

**Pros:**
- More powerful, can add validation/error handling
- Native Salt integration

**Cons:**
- More complex to maintain
- Overkill for simple variable wrapping
- Requires module installation/reload

**File location:** `srv/salt/_modules/win_cmd.py`

---

### Option 3: Pillar-based Defaults with Jinja Filters

**Pros:**
- Variables in pillar, flexible per-minion customization
- No macro import needed if using default filters

**Cons:**
- Less DRY, more verbose in states
- Harder to track defaults

**Usage pattern:**

```sls
test_nvm:
  cmd.run:
    - name: |
        set "NVM_HOME={{ salt['pillar.get']('windows:nvm_home', '%USERPROFILE%\.nvm') }}"
        set "NVM_SYMLINK={{ salt['pillar.get']('windows:nvm_symlink', '%ProgramFiles%\nodejs') }}"
        nvm install lts
```

---

## Recommended Implementation Steps

### Phase 1: Create Macro Structure

1. **Create file** `srv/salt/macros/windows.sls`:
   - Define `win_cmd` macro with default environment variables
   - Support optional override of variables
   - Document usage and available variables

2. **Define default variables**:
   ```yaml
   NVM_HOME: %USERPROFILE%\.nvm
   NVM_SYMLINK: %ProgramFiles%\nodejs
   CONDA_HOME: %ProgramFiles%\miniforge
   ```
   - Add RUST_HOME, PYTHON_HOME if needed
   - Cross-reference with `provisioning/packages.sls` installation paths

3. **Create test state** `srv/salt/test/win-cmd-macro.sls`:
   - Test basic macro usage
   - Test environment variable expansion
   - Test command execution with macro

### Phase 2: Identify & Refactor Existing States

1. **Search for existing cmd.run patterns**:
   ```bash
   grep -Hnr "cmd.run" srv/salt/ | grep -i "set.*=" | grep -i "nvm\|conda\|rust"
   ```

2. **Catalog states that need refactoring**:
   - Document which states set NVM_HOME, CONDA_HOME, etc.
   - Note any custom environment variables per state
   - Prioritize high-impact states

3. **Refactor in stages**:
   - Update imports: Add `{%- from "macros/windows.sls" import win_cmd %}`
   - Replace manual `set` commands with macro calls
   - Test after each change
   - Verify with `make test-windows`

### Phase 3: Extend Macro (Future)

- Add `win_cmd_shell` variant for PowerShell
- Support environment variable overrides per-call
- Add debugging mode that echoes all variables

---

## Testing Strategy

**Unit tests** (in `tests/`):
- Verify macro expands correctly
- Verify environment variables are set
- Test with and without overrides

**Integration tests**:
- Run full Windows highstate with refactored states
- Verify NVM, Conda, and other tools are accessible after state
- Check `$env:NVM_HOME` resolves correctly in subsequent commands

**Verification commands**:
```powershell
# After state runs, verify env vars are available
echo $env:NVM_HOME
echo $env:CONDA_HOME
nvm --version  # Should work without path prefix
conda --version  # Should work
```

---

## Impact Analysis

**Files to update**:
- Create: `srv/salt/macros/windows.sls`
- Modify: Any state with hardcoded Windows environment variables
- Modify: `srv/salt/top.sls` (if macro needs state inclusion)
- Modify: CONTRIBUTING.md (document macro usage for contributors)

**Breaking changes**: None (existing states continue to work)

**Performance impact**: Negligible (Jinja macro compilation is one-time)

---

## Success Criteria

- [x] Macro file created and documented
- [ ] At least 3 existing states refactored to use macro
- [ ] Tests pass: `make test-windows`
- [ ] No regression in Windows state application
- [ ] CONTRIBUTING.md updated with macro usage guide
- [ ] TODO.md updated with completion date

---

## References

- Salt Jinja documentation: https://docs.saltproject.io/en/latest/topics/jinja/
- Windows environment variables: https://ss64.com/nt/set.html
- Related TODO task: "Windows Environment Refresh" (add `refreshenv` after state completion)
