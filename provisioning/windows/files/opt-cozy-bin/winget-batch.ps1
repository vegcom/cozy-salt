# Managed by Salt - DO NOT EDIT MANUALLY

param(
    [string]$WingetPath,
    [string[]]$Packages,
    [string]$Scope,
    [string]$RunAsUser,
    [bool]$SkipDeps,
    [bool]$Prerelease,
    [bool]$Force,
    [bool]$Upgrade
)

$success = @(0, -1978335212, -1978334963, -1978334973)
$results = @{}

foreach ($pkg in $Packages) {

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

    if (-not $Upgrade) { $args += "--no-upgrade" }
    if ($Prerelease)   { $args += "--include-prerelease" }
    if ($SkipDeps)     { $args += "--skip-dependencies" }
    if ($Force)        { $args += "--force" }

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
