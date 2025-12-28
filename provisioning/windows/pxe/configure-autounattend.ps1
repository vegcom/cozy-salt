# Configure autounattend.xml with custom variables
# Usage: .\configure-autounattend.ps1 -Username "myuser" -DisplayName "My User" -Password "SecureP@ss123" -SaltMaster "10.0.0.5"

param(
    [string]$Username = "cozy",
    [string]$DisplayName = "Cozy Admin",
    [string]$Password = "",
    [string]$SaltMaster = "",
    [string]$InputFile = "autounattend.xml",
    [string]$OutputFile = "autounattend.xml"
)

function ConvertTo-UnattendPassword {
    param(
        [string]$PlainPassword,
        [string]$Suffix
    )
    $passwordWithSuffix = $PlainPassword + $Suffix
    $bytes = [Text.Encoding]::Unicode.GetBytes($passwordWithSuffix)
    return [Convert]::ToBase64String($bytes)
}

Write-Host "Configuring autounattend.xml with:"
Write-Host "  Username: $Username"
Write-Host "  Display Name: $DisplayName"
if ($Password) {
    Write-Host "  Password: ******** (custom)"
} else {
    Write-Host "  Password: [keeping default - Admin@123]"
}
if ($SaltMaster) {
    Write-Host "  Salt Master: $SaltMaster"
}

# Read source file
$content = Get-Content $InputFile -Raw

# Replace username placeholders
$content = $content -replace '{{USERNAME}}', $Username
$content = $content -replace '{{DISPLAYNAME}}', $DisplayName

# Replace passwords if provided
if ($Password) {
    Write-Host "`nGenerating password hashes..."

    # Generate encoded passwords
    $adminPasswordEncoded = ConvertTo-UnattendPassword -PlainPassword $Password -Suffix "AdministratorPassword"
    $userPasswordEncoded = ConvertTo-UnattendPassword -PlainPassword $Password -Suffix "Password"

    # Replace Administrator password (first <AdministratorPassword> block)
    $content = $content -replace '(<AdministratorPassword>.*?<Value>)[^<]+(</Value>)', "`${1}$adminPasswordEncoded`${2}"

    # Replace LocalAccount password and AutoLogon password
    # Both use "Password" suffix, need to replace both occurrences
    $passwordPattern = '(<Password>.*?<Value>)[^<]+(</Value>)'
    $matches = [regex]::Matches($content, $passwordPattern)

    # Replace in reverse order to maintain positions
    for ($i = $matches.Count - 1; $i -ge 0; $i--) {
        $match = $matches[$i]
        $replacement = $match.Groups[1].Value + $userPasswordEncoded + $match.Groups[2].Value
        $content = $content.Substring(0, $match.Index) + $replacement + $content.Substring($match.Index + $match.Length)
    }

    Write-Host "  Administrator password: Updated"
    Write-Host "  User account password: Updated"
    Write-Host "  AutoLogon password: Updated"
}

# Save configured file
$content | Set-Content $OutputFile -Encoding UTF8

Write-Host "`nGenerated: $OutputFile"

# If Salt Master specified, update SetupComplete.ps1 default
if ($SaltMaster) {
    $setupScript = "SetupComplete.ps1"
    if (Test-Path $setupScript) {
        $setupContent = Get-Content $setupScript -Raw
        # Update the default value in the param block
        $setupContent = $setupContent -replace '\[string\]\$Master = \$env:SALT_MASTER \?\? "[^"]*"',
            "[string]`$Master = `$env:SALT_MASTER ?? `"$SaltMaster`""
        $setupContent | Set-Content $setupScript -Encoding UTF8
        Write-Host "Updated Salt Master default in $setupScript to: $SaltMaster"
    }
}

if (-not $Password) {
    Write-Host "`n[WARNING] Using default password 'Admin@123'"
    Write-Host "          Run script with -Password parameter to set a secure password"
}

Write-Host "`nTo set SALT_MASTER as environment variable during PXE boot:"
Write-Host '  Set in autounattend.xml FirstLogonCommands or use'
Write-Host "  [Environment]::SetEnvironmentVariable('SALT_MASTER', '$SaltMaster', 'Machine')"

Write-Host "`nDone! Deploy $OutputFile to your PXE server."
Write-Host "`nSecurity Checklist:"
Write-Host "  [$(if($Password){'X'}else{' '})] Custom password set"
Write-Host "  [$(if($SaltMaster -and $SaltMaster -ne 'salt.example.com'){'X'}else{' '})] Salt Master configured"
Write-Host "  [ ] Product key configured (optional)"
Write-Host "  [ ] Deployed to secure PXE server"
