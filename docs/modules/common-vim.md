# Vim Configuration Deployment

Deploy vim configuration files and plugins.

## Location

- **State**: `srv/salt/common/vim.sls`
- **Include**: `common.init`

## Deploys

| Item            | Source                                                  |
| --------------- | ------------------------------------------------------- |
| .vim/ directory | `provisioning/common/.vim/` (plugins, autoload, colors) |
| .vimrc          | Symlink to config file in provisioning                  |

## Plugin Management

Includes:

- Pathogen (plugin loader)
- Sensible defaults (vim-sensible)
- Color schemes (monokai, solarized, etc.)
- Language-specific plugins (rust, python, javascript)
- Git integration (vim-fugitive)

## Usage

```bash
vim .vimrc        # Edit config
:Explore          # File explorer
:Git              # Git commands
:set number       # Line numbers
```

## Customization

Edit config in `provisioning/common/.vimrc`:

- Keybindings
- Color scheme
- Plugin settings
- Auto-indentation rules

## Notes

- Cross-platform (Linux, Windows, macOS)
- Deployed to home directory: ~/.vim, ~/.vimrc
- Symlink prevents duplication of large plugin dirs
- Changes to provisioning/common/.vim sync on next provision
