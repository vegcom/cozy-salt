# Add if missing
Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*' | Add-WindowsCapability -Online -Verbose

# Enable/start service
Set-Service -Name sshd -StartupType Automatic
Start-Service sshd

# Set port 22 (edit config if needed; assumes default)
$configPath = "$env:ProgramData\ssh\sshd_config"
if (Test-Path $configPath) {
    (Get-Content $configPath) -replace '^#?Port\s+\d+', 'Port 22' | Set-Content $configPath
    Restart-Service sshd
}

Write-Host "OpenSSH enabled on port 22. Test: ssh localhost -p 22"
