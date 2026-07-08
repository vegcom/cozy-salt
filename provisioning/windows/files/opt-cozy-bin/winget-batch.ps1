# Managed by Salt - DO NOT EDIT MANUALLY

param(
    [string]$WingetPath,
    [string]$Packages,
    [string]$Scope,
    [string]$RunAsUser,
    [string]$SkipDeps = "false",
    [string]$Prerelease = "false",
    [string]$Force = "false",
    [string]$Upgrade = "false"
)

$PackageList = $Packages -split ','

$_SkipDeps   = $SkipDeps   -in @("true", "1")
$_Prerelease = $Prerelease -in @("true", "1")
$_Force      = $Force      -in @("true", "1")
$_Upgrade    = $Upgrade    -in @("true", "1")

# Removed -1978335212 from list
$success = @(0, -1978334963, -1978334973, -1978335226)
$results = @{}

foreach ($pkg in $PackageList) {

    # Skip if already installed
    $installed = Get-WinGetPackage | Where-Object { $_.Id -eq $pkg }
    if ($installed) {
        $results[$pkg] = @{
            ExitCode = 0
            Success  = $true
            Skipped  = $true
            Reason   = "AlreadyInstalled"
        }
        continue
    }

    # Build argument list dynamically
    $args = @("install", "--exact",
              "--accept-source-agreements", "--accept-package-agreements",
              "--ignore-warnings", "--disable-interactivity")

    if (-not $_Upgrade)    { $args += "--no-upgrade" }
    if ($_Prerelease)      { $args += "--include-prerelease" }
    if ($_SkipDeps)        { $args += "--skip-dependencies" }
    if ($_Force)           { $args += "--force" }

    if ($Scope -ne "") {
        $args += @("--scope", $Scope)
    }

    $args += $pkg

    if ($RunAsUser -and $RunAsUser -ne "") {
        # Build the command string
        $cmd = "& `"$WingetPath`" $($args -join ' ')"

        # Run system pwsh, but tell it to execute the command as that user
        Start-Process pwsh.exe -ArgumentList @(
            "-NoProfile",
            "-Command",
            $cmd
        ) -Wait -WorkingDirectory "C:\Users\$RunAsUser"
        $code = $LASTEXITCODE
    }
    else {
        & $WingetPath @args
        $code = $LASTEXITCODE
    }


    $results[$pkg] = @{
        ExitCode = $code
        Success  = ($success -contains $code)
        Skipped  = $false
    }
}

$results | ConvertTo-Json -Depth 4
exit 0
