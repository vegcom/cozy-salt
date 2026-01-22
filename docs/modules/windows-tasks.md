# Windows Scheduled Tasks

Windows scheduled tasks import from XML files for automation: WSL autostart, port forwarding, etc.

## Location

- **State**: `srv/salt/windows/tasks.sls`
- **Include**: `windows.init`
- **Task XMLs**: `provisioning/windows/tasks/`

## Configured Tasks

| Task | Purpose |
|------|---------|
| WSL autostart | Auto-start WSL services on Windows boot |
| Docker port forward | Expose Docker daemon to host network |
| Ollama port forward | Kubernetes API access from host |
| OpenWebUI forward | Web UI port exposure |

## Deployment Process

1. Deploy XML file to `C:\Windows\Temp\{name}.xml`
2. Use `schtasks /create` to import from XML
3. Run only when XML changes (onchanges requisite)

## XML Location

Source XML files:
- `provisioning/windows/tasks/wsl_autostart.xml`
- `provisioning/windows/tasks/docker_registry_port_forward.xml`
- `provisioning/windows/tasks/ollama_port_forward.xml`
- `provisioning/windows/tasks/open_webui_port_forward.xml`

## Task Management

```cmd
schtasks /list         REM List all tasks
schtasks /run /tn "\Cozy\TaskName"  REM Run task
schtasks /delete /tn "\Cozy\TaskName" REM Delete
```

## Notes

- Tasks grouped under `\Cozy\` namespace
- Uses XML import for reproducibility
- Runs with system privileges
- WSL tasks run at startup (not user login)
- Port forwards require elevated privileges
