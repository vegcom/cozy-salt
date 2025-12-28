# Install OpenSSH Server if missing
Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*' | Add-WindowsCapability -Online -Verbose

# Enable and start service
Set-Service -Name sshd -StartupType Automatic
Start-Service sshd

Write-Host "OpenSSH Server installed and started (default port 22)"
Write-Host "Configuration managed by Salt - see SECURITY.md for hardening"
