# Check if starship is installed, install with winget if missing
if (-not (Get-Command starship -ErrorAction SilentlyContinue)) {
    logging "starship not found, installing with winget..." "INFO"
    try {
        winget install starship --silent --accept-source-agreements --accept-package-agreements | Out-Null
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        logging "starship installed successfully" "INFO"
    } catch {
        logging "failed to install starship: $_" "ERROR"
        return
    }
}

# Initialize starship prompt
try {
    Invoke-Expression (&starship init powershell)
} catch {
    logging "failed to initialize starship: $_" "ERROR"
}
