# Permission Management

## The Problem

Files created with restrictive permissions (600) prevent Salt from reading configuration files, causing silent failures during state runs. This typically happens when:

- Creating files via text editors with restrictive umask
- Copying files from restricted directories
- Using scripts that don't set explicit permissions

## The Solution

Automated permission management via:

1. **scripts/fix-permissions.sh** - Manual permission fixing
2. **pre-commit hook** - Automatic validation before commits

## What Gets Fixed

| File Type | Permission | Reason |
|-----------|------------|--------|
| `*.sls` | 644 | Salt state files must be readable |
| `*.yml`, `*.yaml` | 644 | Configuration files must be readable |
| `*.sh` | 755 | Shell scripts must be executable |
| Directories | 755 | Must be searchable for Salt |

## Usage

### Automatic (Recommended)

The pre-commit hook runs automatically:

```bash
git add myfile.sls
git commit -m "add new state"
# Hook automatically fixes permissions before commit
```

### Manual

Run the script anytime:

```bash
./scripts/fix-permissions.sh
```

Output shows what was changed:

```
[fix-permissions] Fixing permissions in /path/to/cozy-salt
[1/4] Checking .sls files...
  → ./srv/salt/linux/install.sls (600 → 644)
[2/4] Checking .yml/.yaml files...
[3/4] Checking .sh files...
  → ./scripts/enrollment/install-linux-minion.sh (644 → 755)
[4/4] Checking critical directories...

✓ Fixed 2 file(s)
```

### CI/CD Integration

The GitHub Actions workflow runs permission checks on all PRs. Add to other CI systems:

```yaml
- name: Check Permissions
  run: ./scripts/fix-permissions.sh
```

## Troubleshooting

### Hook Not Running

Check if the hook is executable:

```bash
ls -l .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

### Skipping the Hook

To bypass (not recommended):

```bash
git commit --no-verify -m "message"
```

### Fresh Clone Setup

The hook is automatically created in `.git/hooks/` on clone. If missing:

```bash
cp scripts/git-hooks/pre-commit .git/hooks/
chmod +x .git/hooks/pre-commit
```

## Best Practices

1. Let the automation handle it - don't manually chmod files
2. Run `./scripts/fix-permissions.sh` if you see "Permission denied" errors
3. Commit the hook along with changes to keep team in sync
4. Never use `--no-verify` unless absolutely necessary

## Salt-Specific Notes

Salt master runs as UID 999 in Docker and needs:

- Read access (4) to all `.sls` and config files
- Execute access (1) on directories to traverse them
- No write access needed for normal operations

The permission scheme (644 for files, 755 for dirs) ensures Salt can read everything while maintaining security.
