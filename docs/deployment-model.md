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

## Pillar Configuration & Secrets

Pillar configuration, examples, and setup instructions are documented in:

- **README.md** - Pillar hierarchy and user management overview
- **CONTRIBUTING.md** - Template examples and per-host/user setup instructions
- Example files in `srv/pillar/`:
  - [`host/example.sls`](../srv/pillar/host/example.sls) - Per-host configuration template
  - [`class/example.sls`](../srv/pillar/class/example.sls) - Hardware class template
  - [`secrets/init.sls.example`](../srv/pillar/secrets/init.sls.example) - Secrets template
  - [`users/demo.sls`](../srv/pillar/users/demo.sls) - User configuration template
  - [`common/users.sls.example`](../srv/pillar/common/users.sls.example) - User structure reference

### Secrets Management

Sensitive information (tokens, credentials, API keys) are stored in a gitignored pillar file.

**Security considerations**:

1. **Never commit secrets**: Use `.gitignore` for `srv/pillar/secrets/init.sls`, `.env`, `.env.local`
2. **File permissions**: `chmod 600` on all secret files
3. **Rotate tokens regularly**: GitHub PAT expiration, access revocation
4. **Use least privilege**: Separate tokens for different operations with narrow scopes
5. **Salt master security**: Restrict pillar access via pillar matching if needed

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
