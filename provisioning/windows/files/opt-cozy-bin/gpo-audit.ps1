# Parse Registry.pol (PowerShell 7 compatible)
function Read-RegistryPol {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        return @()
    }

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $pos = 0
    $results = @()

    # Registry.pol header is always "PReg" (0x50 0x52 0x65 0x67)
    if (-not ($bytes[0] -eq 0x50 -and $bytes[1] -eq 0x52)) {
        return @()
    }

    # Skip header (4 bytes)
    $pos = 4

    while ($pos -lt $bytes.Length) {
        # Read key name (null-terminated UTF-16)
        $key = ""
        while ($pos -lt $bytes.Length -and !($bytes[$pos] -eq 0 -and $bytes[$pos+1] -eq 0)) {
            $key += [char]([System.BitConverter]::ToUInt16($bytes, $pos))
            $pos += 2
        }
        $pos += 2

        if ($key -eq "") { break }

        # Value name
        $value = ""
        while ($pos -lt $bytes.Length -and !($bytes[$pos] -eq 0 -and $bytes[$pos+1] -eq 0)) {
            $value += [char]([System.BitConverter]::ToUInt16($bytes, $pos))
            $pos += 2
        }
        $pos += 2

        # Type (DWORD)
        $type = [System.BitConverter]::ToUInt32($bytes, $pos)
        $pos += 4

        # Data length (DWORD)
        $len = [System.BitConverter]::ToUInt32($bytes, $pos)
        $pos += 4

        # Data bytes
        $data = $bytes[$pos..($pos + $len - 1)]
        $pos += $len

        # Decode based on type
        switch ($type) {
            1 { $decoded = [System.Text.Encoding]::Unicode.GetString($data).TrimEnd([char]0) } # REG_SZ
            4 { $decoded = [System.BitConverter]::ToUInt32($data, 0) }                         # REG_DWORD
            default { $decoded = $data }
        }

        $results += [pscustomobject]@{
            Key   = $key
            Name  = $value
            Type  = $type
            Value = $decoded
        }
    }

    return $results
}

# Paths for Local GPO
$machinePol = "C:\Windows\System32\GroupPolicy\Machine\Registry.pol"
$userPol    = "C:\Windows\System32\GroupPolicy\User\Registry.pol"

$machine = Read-RegistryPol $machinePol
$user    = Read-RegistryPol $userPol

Write-Host "`n=== MACHINE POLICY CHANGES ===`n"
$machine | Format-Table -AutoSize

Write-Host "`n=== USER POLICY CHANGES ===`n"
$user | Format-Table -AutoSize
