###########################################################
# witchy, 110%                                            #
###########################################################

$ExecutionContext.SessionState.Applications

# ⚙️ path expansion:
$time = Join-Path (Split-Path -Parent $PROFILE.AllUsersCurrentHost) 'config.d' 'time.ps1'
$init = Join-Path (Split-Path -Parent $PROFILE.AllUsersCurrentHost) 'config.d' 'init.ps1'
$code = Join-Path (Split-Path -Parent $PROFILE.AllUsersCurrentHost) 'config.d' 'code.ps1'
$functions = Join-Path (Split-Path -Parent $PROFILE.AllUsersCurrentHost) 'config.d' 'functions.ps1'
$aliases = Join-Path (Split-Path -Parent $PROFILE.AllUsersCurrentHost) 'config.d' 'aliases.ps1'
$modules = Join-Path (Split-Path -Parent $PROFILE.AllUsersCurrentHost) 'config.d' 'modules.ps1'
$choco = Join-Path (Split-Path -Parent $PROFILE.AllUsersCurrentHost) 'config.d' 'choco.ps1'
$npm = Join-Path (Split-Path -Parent $PROFILE.AllUsersCurrentHost) 'config.d' 'npm.ps1'
$conda = Join-Path (Split-Path -Parent $PROFILE.AllUsersCurrentHost) 'config.d' 'conda.ps1'
$inshellisense = Join-Path (Split-Path -Parent $PROFILE.AllUsersCurrentHost) '.inshellisense' 'pwsh' 'init.ps1'
$starship = Join-Path (Split-Path -Parent $PROFILE.AllUsersCurrentHost) 'config.d' 'starship.ps1'


# ⚠️ required imports (order matters - time must load first):
. $time
. $init

# 🪺 optional imports:
. $functions
. $aliases

# ⌨️ evaluation:
$isInteractive = ($Host.UI.RawUI -ne $null) -or $false
$isVscode = ($env:TERM_PROGRAM -eq "vscode") -or $false
$opt_scripts = @()

# 🛠️ environment defaults:
$env:PWSH_LOG_LEVEL = "DEBUG"
$env:PWSH_TIMESTAMPS = $true
$env:PWSH_GLYPH = $true
$env:ENABLE_MODULES = $true
$env:ENABLE_CHOCOLATEY = $true
$env:ENABLE_NPM = $true
$env:ENABLE_INSHELLISENSE = $true
$env:ENABLE_CONDA = $true
$env:ENABLE_STARSHIP = $true
$env:ENABLE_CODE = $false

# Starship config path
$starshipConfigPath = Join-Path (Split-Path -Parent $PROFILE.AllUsersCurrentHost) 'starship.toml'
$env:STARSHIP_CONFIG = $starshipConfigPath
$ENV:STARSHIP_CACHE = "$HOME\AppData\Local\Temp"

# 📦 environment construction
if ($isVscode) {
    if ($env:ENABLE_CHOCOLATEY -eq $true) { $opt_scripts += $choco }
    if ($env:ENABLE_NPM -eq $true) { $opt_scripts += $npm }
    if ($env:ENABLE_CONDA -eq $true) { $opt_scripts += $conda }
    if ($env:ENABLE_CODE -eq $true) { $opt_scripts += $code }
    if ($env:ENABLE_STARSHIP -eq $true) { $opt_scripts += $starship }
}
elseif ($isInteractive) {
    if ($env:ENABLE_MODULES -eq $true) { $opt_scripts += $modules }
    if ($env:ENABLE_CHOCOLATEY -eq $true) { $opt_scripts += $choco }
    if ($env:ENABLE_NPM -eq $true) { $opt_scripts += $npm }
    if ($env:ENABLE_CONDA -eq $true) { $opt_scripts += $conda }
    if ($env:ENABLE_INSHELLISENSE -eq $true) { $opt_scripts += $inshellisense }
    if ($env:ENABLE_STARSHIP -eq $true) { $opt_scripts += $starship }
    if ($env:ENABLE_CODE -eq $true) { $opt_scripts += $code }
} else {
    $PSModuleAutoLoadingPreference = 'None'
}

# 🚀 load scripts:
Script-Loader $opt_scripts
