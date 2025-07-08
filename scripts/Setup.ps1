function Initialize-CustomModules {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string] $ModuleRoot = (Join-Path -Path $PSScriptRoot -ChildPath "powershell"),

        [Parameter()]
        [switch] $Recurse
    )

    if (-not (Test-Path -Path $ModuleRoot)) {
        Write-Warning "Custom module root '$ModuleRoot' does not exist."
        return
    }

    # Ensure the path separator is correct for the platform
    $delimiter = [IO.Path]::PathSeparator
    if (-not ($Env:PSModulePath -split [regex]::Escape($delimiter) -contains $ModuleRoot)) {
        $Env:PSModulePath = "$Env:PSModulePath$delimiter$ModuleRoot"
        Write-Verbose "Added '$ModuleRoot' to PSModulePath"
    }

    if ($Recurse) {
        # Optionally import all nested modules (useful in development)
        Get-ChildItem -Path $ModuleRoot -Recurse -Filter *.psm1 | ForEach-Object {
            try {
                Import-Module $_.FullName -Force -ErrorAction Stop
                Write-Verbose "Imported module: $($_.FullName)"
            } catch {
                Write-Warning "Failed to import module '$($_.FullName)': $($_.Exception.Message)"
            }
        }
    }
}

Initialize-CustomModules -Recurse -Verbose