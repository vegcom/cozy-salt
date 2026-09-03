# Managed by Salt - DO NOT EDIT MANUALLY

param(
    [string]$WingetPath,
    [string]$Packages,
    [string]$Scope,
    [string]$SkipDeps = "false",
    [string]$Force = "false",
    [string]$Upgrade = "false"
)

$PackageList = $Packages -split ','

$_SkipDeps   = $SkipDeps   -in @("true", "1")
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
    $wingetArgs = @("install", "--exact",
              "--accept-source-agreements", "--accept-package-agreements",
              "--ignore-warnings", "--disable-interactivity")

    if (-not $_Upgrade)    { $wingetArgs += "--no-upgrade" }
    if ($_SkipDeps)        { $wingetArgs += "--skip-dependencies" }
    if ($_Force)           { $wingetArgs += "--force" }

    if ($Scope -ne "") {
        $wingetArgs += @("--scope", $Scope)
    }

    $wingetArgs += $pkg

    & $WingetPath @wingetArgs
    $code = $LASTEXITCODE

    $results[$pkg] = @{
        ExitCode = $code
        Success  = ($success -contains $code)
        Skipped  = $false
    }
}

$results | ConvertTo-Json -Depth 4
exit 0
