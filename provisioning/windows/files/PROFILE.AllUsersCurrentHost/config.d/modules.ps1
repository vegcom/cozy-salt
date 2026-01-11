$modulesToImport = @('Terminal-Icons', 'PSReadLine', 'Microsoft.WinGet.CommandNotFound')

logging "Importing: $($modulesToImport -join ', ')" "DEBUG"

foreach ($module in $modulesToImport) {
    logging "Importing: $module" "DEBUG"

    try {
        # Import module with error handling
        Import-Module -Scope Global -Force -Name $module -ErrorAction Stop
        logging "Imported: $module" "DEBUG"
    } catch {
        # Silently ignore already-registered subsystems
        if ($_.Exception.Message -match "already registered|already imported|FeedbackProvider") {
            logging "Module $module already loaded, skipping" "DEBUG"
        } else {
            logging "Failed to import $module - $_" "WARN"
        }
    }
}
