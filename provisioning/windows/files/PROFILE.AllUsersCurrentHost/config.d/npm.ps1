# NPM configuration and initialization
# NPM is typically provided by nvm-windows nodejs installation
# Sets up npm environment and registry configuration

try {
    # Candidate npm executables (from NVM nodejs installation)
    $candidatePaths = @(
        (Join-Path $env:NVM_SYMLINK 'npm.cmd'),
        (Join-Path $env:NVM_HOME 'nodejs' 'npm.cmd'),
        'C:\opt\nvm\nodejs\npm.cmd'
    )

    $found = @()
    foreach ($p in $candidatePaths) {
        if (Test-Path $p) { $found += (Get-Item -LiteralPath $p).FullName }
    }

    if ($found.Count -eq 0) {
        if (Get-Command logging -ErrorAction SilentlyContinue) {
            logging "No npm executable found in candidate paths" "DEBUG"
        }
        return
    }

    if ($found.Count -gt 1) {
        if (Get-Command logging -ErrorAction SilentlyContinue) {
            logging "Multiple npm executables found - using first: $($found[0])" "DEBUG"
        }
    }

    $env:NPM_EXE = $found[0]

    if (Get-Command logging -ErrorAction SilentlyContinue) {
        logging "npm found at: $env:NPM_EXE" "DEBUG"
    }
} catch {
    if (Get-Command logging -ErrorAction SilentlyContinue) {
        logging "Failed to initialize npm: $_" "WARN"
    }
}

# TODO: Add npm-specific logic here
# Examples:
# - Set npm registry configuration
# - Initialize npm authentication
# - Configure npm cache location
# - Set npm global prefix
# - Any other npm environment setup
