$modulesToImport = @('Terminal-Icons', 'PSReadLine', 'Microsoft.WinGet.CommandNotFound')

logging "Importing: $($modulesToImport -join ', ')" "DEBUG"

foreach ($module in $modulesToImport) {
    logging "Importing: $module" "DEBUG"

    # Ensure installed
    (Get-InstalledModule -Name $module -ErrorAction SilentlyContinue`
    ||Install-Module -Scope AllUsers -AllowClobber -SkipPublisherCheck `
    -Force -Name $module -ErrorAction SilentlyContinue) 
    # Import module
    Import-Module -Scope Global -Force -Name $module
}
