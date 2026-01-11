try {
    $chocolateyprofile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
    if (Test-Path "$chocolateyprofile") {
        Import-Module $chocolateyprofile -ErrorAction SilentlyContinue
        logging "chocolatey module loaded: $chocolateyprofile" "DEBUG"
    } else {
       logging "chocolatey module not found: $chocolateyprofile" "WARN"
    }
} catch {
    if (Get-Command logging -ErrorAction SilentlyContinue) {
        logging "Failed to initialize chocolatey: $_" "WARN"
    }
}