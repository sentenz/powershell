# Initialize a software development workspace on Windows.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Import Modules

Import-Module Dotenv -Force
Import-Module Git -Force

# Internal Advanced Function

function Initialize-Scopes {
    [CmdletBinding()]
    param ()

    $Script:WingetPackages = @(
        @{ Id = "ezwinports.make"        ; Info = "" },
        @{ Id = "Git.Git"                ; Info = "" },
        @{ Id = "Git.GitLFS"             ; Info = "" },
        @{ Id = "Gpg4win.Gpg4win"        ; Info = "" },
        @{ Id = "jqlang.jq"              ; Info = "" },
        @{ Id = "Kitware.Ninja"          ; Info = "" },
        @{ Id = "ccache.ccache"          ; Info = "" },
        @{ Id = "Python.Python.3.12"     ; Info = "" },
        @{ Id = "dos2unix.dos2unix"      ; Info = "" },
        @{ Id = "7zip.7zip"              ; Info = "" },
        @{ Id = "GnuWin32.Wget"          ; Info = "" },
        @{ Id = "Microsoft.DotNet.SDK.8" ; Info = "" }
    )

    $Script:PipPackages = @(
        @{
            Name    = "sbom"
            Version = "1.0.0"
            Url     = "https://__token__:$Env:PIP_ACCESS_TOKEN@gitlab.com/api/v4/groups/1012/-/packages/pypi/simple"
            Info    = ""
        }
    )

    $Script:Downloads = @(
        @{
            Description = "GCC-ARM Toolchain"
            Url         = "https://developer.arm.com/-/media/Files/downloads/gnu/14.2.rel1/binrel/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi.tar.xz"
            Version     = "14.2.rel1"
            Path        = "C:\Tools\arm-gnu-toolchain"
            Info        = ""
        },
        @{
            Description = "PowerShell"
            Url         = "https://github.com/PowerShell/PowerShell/releases/download/v7.5.0/PowerShell-7.5.0-win-x64.msi"
            Version     = "7.5.0"
            Path        = ""
            Info        = ""
        },
        @{
            Description = "Sonar-Scanner CLI"
            Url         = "https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-7.1.0.4889-windows-x64.zip"
            Version     = "7.1.0.4889"
            Path        = "C:\Tools\sonarqube"
            Info        = ""
        }
    )
}

function New-EnvironmentVariables {
    [CmdletBinding()]
    param ()

    begin {
        $FilePath = Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath ".env"
    }

    process {
        Read-Dotenv -FilePath $FilePath
        $Env:PIP_ACCESS_TOKEN = Get-Dotenv -VariableName "PIP_ACCESS_TOKEN"
    }

    end {
        Write-Host "Env:PIP_ACCESS_TOKEN = $Env:PIP_ACCESS_TOKEN"
    }
}

function Install-Winget-Packages {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [array] $Packages
    )

    foreach ($pkg in $Packages) {
        $id = $pkg.Id

        Write-Host "Installing Winget package: $($id)"
        try {
            winget install --id $id --source winget --accept-package-agreements --accept-source-agreements --silent
        } catch {
            Write-Warning "Failed to install package: $($id) - $($_.Exception.Message)"
        }
    }
}

function Install-Pip-Packages {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [array]$Packages
    )

    # python.exe -m pip install --upgrade pip

    foreach ($pkg in $Packages) {
        $name = $pkg.Name
        $version = $pkg.Version
        $url = $pkg.Url

        Write-Host "Installing Python package: $name"
        try {
            if ($version) {
                pip install "$name==$version" --index-url $url
            } else {
                pip install $name --index-url $url
            }
        } catch {
            Write-Warning "Failed to install package: $($name) - $($_.Exception.Message)"
        }
    }
}

function Clear-Pip-Cache {
    [CmdletBinding()]
    param ()

    Write-Host "Cleaning pip cache..."
    try {
        pip cache purge
    } catch {
        Write-Warning "Failed to purge pip cache - $($_.Exception.Message)"
    }
}

function Invoke-Setup-Downloads {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [array] $DownloadItems
    )

    foreach ($item in $DownloadItems) {
        $filename = Split-Path $item.Url -Leaf
        $filepath = $item.Path
        $url = $item.Url
        $description = $item.Description

        Write-Host "[$description] Downloading from $url"
        try {
            Invoke-WebRequest -Uri $url -OutFile $filename -ErrorAction Stop
        } catch {
            Write-Error "[$description] Failed to download: $($_.Exception.Message)"
            continue
        }

        Write-Host "[$description] Download complete: $filename"

        switch -Wildcard ($filename) {
            "arm-gnu-toolchain-*.tar.xz" {
                if (Test-Path $filepath) {
                    New-Item -ItemType Directory -Force -Path $filepath | Out-Null
                }
                tar -xf $filename -C $filepath --strip-components=1
                Remove-Item $filename -Force
                Write-Host "[$description] Extracted to $filepath"
            }

            "PowerShell-*.msi" {
                Start-Process msiexec.exe -Wait -ArgumentList "/i `"$filename`" /quiet"
                Remove-Item $filename -Force
                Write-Host "[$description] Installed PowerShell"
            }

            "sonar-scanner-cli-*.zip" {
                if (Test-Path $filepath) {
                    New-Item -ItemType Directory -Force -Path $filepath | Out-Null
                }
                Expand-Archive -Path $filename -DestinationPath $filepath -Force
                Remove-Item $filename -Force
                $env:Path += ";$($filepath)\bin"
                Write-Host "[$description] Extracted and installed to $filepath"
            }

            default {
                Write-Warning "[$description] No handler for file: $filename"
            }
        }
    }
}

# Workflow

try {
    New-EnvironmentVariables
    Initialize-Scopes
    Install-Winget-Packages -Packages $Script:WingetPackages
    Install-Pip-Packages -Packages $Script:PipPackages
    Clear-Pip-Cache
    Invoke-Setup-Downloads -DownloadItems $Script:Downloads
} catch {
    Write-Error "In: $PSCommandPath Error: $_"
    $Host.SetShouldExit(1)
}
