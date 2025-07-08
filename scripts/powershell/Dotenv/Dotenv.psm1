
<#
.SYNOPSIS
    Imports environment variables from a specified file.

.DESCRIPTION
    Reads a file containing environment variables in the format `NAME=VALUE` and sets them in the current environment.

.PARAMETER FilePath
    The path to the file containing environment variables.

.EXAMPLE
    Read-Dotenv -FilePath "C:\path\to\.env"
#>
function Read-Dotenv {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    begin {
        if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
            Write-Error "Environment file '$FilePath' not found."
            return
        }
    }

    process {
        try {
            $vars = Get-Content -Path $FilePath | ForEach-Object {
                $key, $value = $_ -split "=", 2
                if ([string]::IsNullOrWhiteSpace($key) -or $key.Contains('#')) {
                    continue
                }
                [System.Collections.DictionaryEntry]::new($key.Trim(), $value.Trim())
            }

            $vars | ForEach-Object {
                [System.Environment]::SetEnvironmentVariable($_.Key, $_.Value)
                Write-Verbose "Set environment variable '$($_.Key)' to '$($_.Value)'"
            }
        } catch {
            Write-Error "In: $PSCommandPath Error: $_"
        }
    }
}

<#
.SYNOPSIS
    Retrieves the value of a specified environment variable.

.DESCRIPTION
    Gets the value of an environment variable. If the variable is not set, an error is thrown.

.PARAMETER VariableName
    The name of the environment variable to retrieve.

.OUTPUTS
    System.String
    The value of an specified environment variable.

.EXAMPLE
    $value = Get-Dotenv -VariableName "PATH"
#>
function Get-Dotenv {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$VariableName
    )

    process {
        try {
            [System.Environment]::GetEnvironmentVariable($VariableName)
            if (-not $?) {
                Write-Error "Environment variable '$VariableName' is not set."
                return
            }
        } catch {
            Write-Error "In: $PSCommandPath Error: $_"
        }
    }
}
