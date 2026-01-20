# Conda initialize

# conda config --set changeps1 False
# starship config conda.ignore_base false


# Candidate conda executables to check (expand $HOME for user installs)
$candidatePaths = @(
    'C:\opt\miniforge3\Scripts\conda.exe'
    (Join-Path $HOME 'miniforge3\Scripts\conda.exe')
)

$found = @()
foreach ($p in $candidatePaths) {
    if (Test-Path $p) { $found += (Get-Item -LiteralPath $p).FullName }
}

if ($found.Count -eq 0) {
    if (Get-Command logging -ErrorAction SilentlyContinue) {
        logging "No conda executable found in candidate paths: $($candidatePaths -join '; ')" "WARN"
    } else {
        Write-Host "WARN: No conda executable found in candidate paths: $($candidatePaths -join '; ')"
    }
    return
}

if ($found.Count -gt 1) {
    if (Get-Command logging -ErrorAction SilentlyContinue) {
        logging "Multiple conda executables found: $($found -join ', ') - using first: $($found[0])" "WARN"
    } else {
        Write-Host "WARN: Multiple conda executables found: $($found -join ', ') - using first: $($found[0])"
    }
}

$env:CONDA_EXE = $found[0]

# Initialize conda for PowerShell
try {
    $hook = (& $env:CONDA_EXE shell.powershell hook) | Out-String
    if ($hook) { Invoke-Expression $hook }
    if (Get-Command logging -ErrorAction SilentlyContinue) { logging "Initialized conda from $env:CONDA_EXE" "DEBUG" }
} catch {
    if (Get-Command logging -ErrorAction SilentlyContinue) { logging "Failed to initialize conda from $env:CONDA_EXE - $_" "ERROR" } else { Write-Host "ERROR: Failed to initialize conda from $env:CONDA_EXE - $_" }
}
