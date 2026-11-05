# enroll.ps1 - Enroll this host into cozy-salt via salt onedir bootstrap

$salt_master = Read-Host "Salt Master"
$minion_id = Read-Host "Minion ID"

$script = (Invoke-WebRequest -UseBasicParsing -Uri https://raw.githubusercontent.com/saltstack/salt-bootstrap/develop/salt-quick-start.ps1).Content
$sb = [scriptblock]::Create($script)
& $sb -master $salt_master -minion-name $minion_id
