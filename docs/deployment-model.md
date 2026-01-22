# Deployment Model: Dynamic Git & Secrets

This document covers cozy-salt's hybrid deployment approach: static infrastructure via Salt states, dynamic configuration via git repos, and secrets management.

## Architecture Overview

```
cozy-salt (main repo)
├── Salt states (define infrastructure)
├── Provisioning files (generic, via git deployment)
└── Secrets pillar (gitignored, locally sourced)

External repos (fetched dynamically)
├── cozy-vim.git (per-user dotfiles)
├── cozy-pwsh.git (system PowerShell profile)
└── Starship-Twilite.git (shell prompt config)
```

## Dynamic Git Deployments

Instead of storing full configuration files in cozy-salt, we fetch them dynamically from external repos using Salt's `git.latest` module. This enables:

- **Independent updates**: Repos can be updated without modifying salt infrastructure
- **Lean repo**: cozy-salt stays focused on orchestration, not config storage
- **Per-user sync**: Deployments can be per-user (vim) or system-wide (pwsh)
- **Automatic fetch**: Changes trigger on next Salt highstate run

### cozy-vim.git

**Deployment**: Per-user `~/.vim` directory

**State**: `srv/salt/common/gitconfig.sls` (managed_users loop)

**How it works**:
```sls
deploy_vim_{{ username }}:
  git.latest:
    - name: https://github.com/vegcom/cozy-vim.git
    - target: {{ dotfiles.dotfile_path(user_home, '.vim') }}
    - user: {{ username }}
    - branch: main
```

**Update model**: Manual edits to cozy-vim.git repo, fetched on next highstate

**Ownership**: vegcom/cozy-vim.git

### cozy-pwsh.git

**Deployment**: System-wide `C:\Program Files\PowerShell\7` (Windows only)

**State**: `srv/salt/windows/profiles.sls`

**How it works**:
```sls
powershell_profile_files:
  git.latest:
    - name: https://github.com/vegcom/cozy-pwsh.git
    - target: {{ pwsh_profile_dir }}
    - branch: main
```

**Update model**: 
- Manual edits to cozy-pwsh.git
- OR automatic sync via Starship-Twilite webhook (see below)
- Fetched on next highstate

**Ownership**: vegcom/cozy-pwsh.git

### Starship-Twilite Integration

**How it works**:

1. **Starship-Twilite** (your shell prompt config repo)
   - `.github/workflows/notify.yml` triggers on `starship.toml` changes
   - Sends `repository_dispatch` webhook to cozy-pwsh with event type `update`

2. **cozy-pwsh** (PowerShell profile repo)
   - `.github/workflows/update-starship.yml` listens for the webhook
   - Downloads latest `starship.toml` from Starship-Twilite
   - Auto-commits and pushes if changed

3. **cozy-salt** (Salt infrastructure)
   - Fetches cozy-pwsh.git on next highstate
   - Deploys updated starship.toml to Windows systems

**Result**: Changes to Starship-Twilite automatically sync through cozy-pwsh → cozy-salt → Windows systems

## Pillar Configuration

Cozy-salt uses a hierarchical pillar system to manage configuration:
- **Global defaults**: `srv/pillar/linux/init.sls`, `srv/pillar/arch/init.sls`, `srv/pillar/windows/init.sls`
- **Hardware classes**: `srv/pillar/class/` (e.g., `galileo.sls` for Steam Deck)
- **Per-host overrides**: `srv/pillar/host/` (e.g., `hostname.sls` for specific machines)
- **Secrets** (gitignored): `srv/pillar/secrets/init.sls`
- **User config** (gitignored): `srv/pillar/common/users.sls`

### Example Files (Templates)

All example files are committed to the repo for reference. Copy and rename them to use:

1. **`srv/pillar/host/example.sls`** → Copy to `srv/pillar/host/YOUR_HOSTNAME.sls`
   - Per-host configuration overrides
   - Applied to single specific system (matched by minion_id)
   - Example: custom locales, disable features, enable capabilities

2. **`srv/pillar/class/example.sls`** → Copy to `srv/pillar/class/YOUR_CLASS.sls`
   - Hardware class configuration
   - Applied to all systems with matching grains (e.g., Steam Deck)
   - Example: Chaotic AUR for aarch64, SDDM config

3. **`srv/pillar/secrets/init.sls.example`** → Copy to `srv/pillar/secrets/init.sls`
   - Sensitive credentials (tokens, keys, passwords)
   - Gitignored - never committed
   - Edit with actual secrets after copying

4. **`srv/pillar/common/users.sls.example`** → Reference only
   - Shows user structure format
   - Actual users defined in `srv/pillar/common/users.sls` (gitignored)

### Configuration Hierarchy

Pillar values merge from bottom to top (later values override earlier):

1. `srv/pillar/linux/init.sls` (global Linux defaults)
2. `srv/pillar/arch/init.sls` or `windows/init.sls` (distro-specific)
3. `srv/pillar/class/CLASSNAME.sls` (hardware class)
4. `srv/pillar/host/HOSTNAME.sls` (per-host)

### Secrets Management

Sensitive information (tokens, credentials, API keys) are stored in a gitignored pillar file.

### Setup

1. **Create host-specific config** (optional):

   ```bash
   cp srv/pillar/host/example.sls srv/pillar/host/HOSTNAME.sls
   # Edit to override defaults for this host
   ```

2. **Create hardware class config** (optional):

   ```bash
   cp srv/pillar/class/example.sls srv/pillar/class/YOUR_CLASS.sls
   # Edit to configure for this hardware class
   ```

3. **Create secrets pillar** (required, locally):

   ```bash
   cp srv/pillar/secrets/init.sls.example srv/pillar/secrets/init.sls
   # Edit with actual secrets
   chmod 600 srv/pillar/secrets/init.sls
   ```

4. **Set environment variables** (for local development/testing):

   ```bash
   cp .env.example .env
   # Edit with actual token
   chmod 600 .env
   ```

### File Structure

**`srv/pillar/secrets/init.sls.example`** (committed):
```yaml
# Secrets configuration (EXAMPLE - rename to init.sls and fill with actual values)
# This file should NOT be committed to git - see .gitignore

github:
  access_token: your_github_pat_token_here
```

**`srv/pillar/secrets/init.sls`** (gitignored, locally created):
```yaml
github:
  access_token: ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**`.env.example`** (committed):
```bash
# Environment configuration (EXAMPLE - copy to .env and fill with actual values)
PROJECT_ACCESS_TOKEN=your_github_pat_token_here
```

**`.env`** (gitignored, locally created):
```bash
PROJECT_ACCESS_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### Access in Salt States

**From pillar** (recommended for deployment):
```sls
{% set github_token = salt['pillar.get']('github:access_token', '') %}

deploy_from_repo:
  git.latest:
    - name: https://{{ github_token }}@github.com/vegcom/private-repo.git
    - target: /opt/deployment
```

**From environment** (for local scripts/tests):
```bash
source .env
curl -H "Authorization: token $PROJECT_ACCESS_TOKEN" \
  https://api.github.com/repos/vegcom/cozy-pwsh/dispatches
```

### Security Considerations

1. **Never commit secrets**: Use `.gitignore` entries
   - `srv/pillar/secrets/init.sls`
   - `.env`
   - `.env.local`

2. **File permissions**: Restrict access
   ```bash
   chmod 600 srv/pillar/secrets/init.sls .env
   ```

3. **Rotate tokens regularly**: GitHub PAT expiration, access revocation

4. **Use least privilege**: Create separate tokens for different operations
   - Narrow scopes (repo access only, not org admin)
   - Limited expiration windows

5. **Salt master security**: Pillar data is available to all minions; use pillar matching if needed:
   ```sls
   'role:deployment':
     - match: pillar
     - secrets  # Only deploy targets get secrets
   ```

## Deployment Flow

### Dynamic Git Deployment (git.latest)

```
External repo change (cozy-vim, cozy-pwsh, Starship-Twilite)
    ↓
Next Salt highstate run (automated or manual)
    ↓
salt://state references git.latest
    ↓
Git.latest clones/pulls latest branch
    ↓
Files deployed to target (system-wide or per-user)
    ↓
Updated configuration active
```

### Webhook Workflow (Starship-Twilite → cozy-pwsh)

```
Push to Starship-Twilite/main (starship.toml change)
    ↓
notify.yml triggers on path filter
    ↓
Sends repository_dispatch webhook to cozy-pwsh
    ↓
update-starship.yml receives webhook
    ↓
Downloads latest starship.toml from Starship-Twilite
    ↓
Detects changes (git add + git diff --cached)
    ↓
If changed: commit and push to cozy-pwsh/main
    ↓
Next Salt highstate fetches cozy-pwsh.git
    ↓
Updated starship.toml deploys to Windows systems
```

## Troubleshooting

### Git deployment fails with "cannot find URL"

**Cause**: SSH key not configured or HTTPS token not available

**Fix**: 
- Use HTTPS URL with token: `https://token@github.com/owner/repo.git`
- Or configure SSH key for git user (minion runs as uid 999)

### Webhook never triggers

**Cause**: Event type mismatch or token permissions

**Check**:
1. Secret name matches: `TARGET_REPO` in Starship-Twilite
2. Token has `repo` scope
3. Webhook delivery logs in Settings → Webhooks

### Secrets not available in state

**Cause**: Pillar not loaded or file doesn't exist

**Fix**:
1. Create `srv/pillar/secrets/init.sls` from `.example`
2. Run `salt '*' saltutil.refresh_pillar`
3. Verify: `salt '*' pillar.get github:access_token`

## Related Documentation

- **Pillar examples**:
  - `srv/pillar/host/example.sls` - Per-host configuration template
  - `srv/pillar/class/example.sls` - Hardware class template
  - `srv/pillar/secrets/init.sls.example` - Secrets template
  - `srv/pillar/common/users.sls.example` - User configuration reference
- **Git deployments**: Salt [git.latest](https://docs.saltproject.io/salt/user-guide/en/latest/reference/modules/salt.modules.git.html) documentation
- **Pillar data**: Salt [pillar system](https://docs.saltproject.io/salt/user-guide/en/latest/topics/pillar/) documentation
- **Secrets management**: See TODO for lightweight alternatives to Vault (secrets management solution pending)
- **Workflow automation**: GitHub [repository_dispatch](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#repository_dispatch) event type

## See Also

- `CONTRIBUTING.md` - Dynamic deployments table (vim, pwsh)
- `provisioning/windows/README.md` - PowerShell profile deployment details
- `srv/salt/common/gitconfig.sls` - Vim deployment implementation
- `srv/salt/windows/profiles.sls` - PowerShell profile deployment implementation
- `srv/salt/linux/dist/config-pacman.sls` - Arch repo and Chaotic AUR configuration
- `srv/salt/linux/config-locales.sls` - System locale deployment
