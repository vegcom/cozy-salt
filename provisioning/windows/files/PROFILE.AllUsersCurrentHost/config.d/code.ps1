# VS Code
$candidatePaths = @(
    (Join-Path $env:PROGRAMFILES "Microsoft VS Code/Code.exe"),
    (Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code/Code.exe")
)

$found = @()
foreach ($p in $candidatePaths) {
    if (Test-Path $p) { $found += (Get-Item -LiteralPath $p).FullName }
}

if ($found.Count -eq 0) {
    if (Get-Command logging -ErrorAction SilentlyContinue) {
        logging "No VS Code executable found" "DEBUG"
    }
    return
}

if ($found.Count -gt 1) {
    if (Get-Command logging -ErrorAction SilentlyContinue) {
        logging "Multiple VS Code executables found - using first: $($found[0])" "WARN"
    }
}

$env:CODE_EXE = $found[0]

# VS Code Insiders
$candidatePathsInsiders = @(
    (Join-Path $env:PROGRAMFILES "Microsoft VS Code Insiders/Code - Insiders.exe"),
    (Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code Insiders/Code - Insiders.exe")
)

$foundInsiders = @()
foreach ($p in $candidatePathsInsiders) {
    if (Test-Path $p) { $foundInsiders += (Get-Item -LiteralPath $p).FullName }
}

if ($foundInsiders.Count -eq 0) {
    if (Get-Command logging -ErrorAction SilentlyContinue) {
        logging "VS Code Insiders not found" "DEBUG"
    }
    return
}

if ($foundInsiders.Count -gt 1) {
    if (Get-Command logging -ErrorAction SilentlyContinue) {
        logging "Multiple VS Code Insiders executables found - using first: $($foundInsiders[0])" "WARN"
    }
}

$env:CODE_INSIDERS_EXE = $foundInsiders[0]

# Load shell integration if running in VS Code
if ($env:TERM_PROGRAM -eq "vscode") {
    try {
        $shellIntegration = & $env:CODE_EXE --locate-shell-integration-path pwsh 2>$null
        if ($shellIntegration -and (Test-Path $shellIntegration)) {
            . $shellIntegration
            if (Get-Command logging -ErrorAction SilentlyContinue) {
                logging "VS Code shell integration loaded" "DEBUG"
            }
        }
    } catch {
        if (Get-Command logging -ErrorAction SilentlyContinue) {
            logging "VS Code shell integration failed: $_" "WARN"
        }
    }
}
