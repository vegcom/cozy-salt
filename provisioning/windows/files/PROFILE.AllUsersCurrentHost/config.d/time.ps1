$script:timeMarkers = @{}

function Mark-Time {
    <#.SYNOPSIS Starts timing for a named marker #>
    param([string]$name = "default")
    $script:timeMarkers[$name] = [System.Diagnostics.Stopwatch]::StartNew()
}
