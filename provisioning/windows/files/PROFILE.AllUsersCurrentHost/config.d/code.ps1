# Code
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
        logging "No code executable found in candidate paths: $($candidatePaths -join '; ')" "WARN"
    } else {
        Write-Host "WARN: No code executable found in candidate paths: $($candidatePaths -join '; ')"
    }
    return
}

if ($found.Count -gt 1) {
    if (Get-Command logging -ErrorAction SilentlyContinue) {
        logging "Multiple code executables found: $($found -join ', ') - using first: $($found[0])" "WARN"
    } else {
        Write-Host "WARN: Multiple code executables found: $($found -join ', ') - using first: $($found[0])"
    }
}

if ($found.Count -eq 0) {
    if (Get-Command logging -ErrorAction SilentlyContinue) {
        logging "No code executable found in candidate paths: $($candidatePaths -join '; ')" "WARN"
    } else {
        Write-Host "WARN: No code executable found in candidate paths: $($candidatePaths -join '; ')"
    }
    return
}

$env:CODE_EXE = $found[0]

# Code Insiders
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
        logging "No code insiders executable found in candidate paths: $($candidatePathsInsiders -join '; ')" "WARN"
    } else {
        Write-Host "WARN: No code insiders executable found in candidate paths: $($candidatePathsInsiders -join '; ')"
    }
    return
}

if ($foundInsiders.Count -gt 1) {
    if (Get-Command logging -ErrorAction SilentlyContinue) {
        logging "Multiple code insiders executables found: $($found -join ', ') - using first: $($found[0])" "WARN"
    } else {
        Write-Host "WARN: Multiple code insiders executables found: $($found -join ', ') - using first: $($found[0])"
    }
}

$env:CODE_INSIDERS_EXE = $foundInsiders[0]

if ($foundInsiders.Count -gt 1) {
    if (Get-Command logging -ErrorAction SilentlyContinue) {
        logging "Multiple code executables found: $($foundInsiders -join ', ') - using first: $($foundInsiders[0])" "WARN"
    } else {
        Write-Host "WARN: Multiple code executables found: $($foundInsiders -join ', ') - using first: $($foundInsiders[0])"
    }
}





# Eval code-insiders if present for code cmdline




if (Test-Path $codeInsidersPath) {
    logging "vscode insiders detected at: $codeInsidersPath" "DEBUG"
    try {
        code version use $codeInsidersPath --install-dir $codeInsidersPath 1>$null 2>$null
    } catch {
        logging "failed to set code version: $_" "WARN"
    }

    if ($env:TERM_PROGRAM -eq "vscode") {
        try {
            $shellIntegration = code -- --locate-shell-integration-path pwsh 1>$null 2>$null
            if ($shellIntegration -and (Test-Path $shellIntegration)) {
                . $shellIntegration
                logging "vscode shell integration loaded" "DEBUG"
            }
        } catch {
            logging "vscode shell integration failed: $_" "WARN"
        }
    }
} else {
    logging "vscode insiders not found at: $codeInsidersPath" "DEBUG"
}