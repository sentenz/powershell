# Initialize a software development workspace on Windows.

Set-StrictMode -Version Latest

# Import Modules

Import-Module Dotenv -Force

# Internal Advanced Function

function Import-EnvironmentVariable {
    [CmdletBinding()]
    param ()

    begin {
        $FilePath = Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath ".env"
    }

    process {
        Read-Dotenv -FilePath $FilePath
        $Env:ENV = Get-Dotenv -VariableName "ENV"
    }

    end {
        Write-Verbose "Env:ENV = $Env:ENV"
    }
}

function Initialize-ScopeVariable {
    [CmdletBinding()]
    param ()

    begin {
        # See https://winget.ragerworks.com/ to search for winget packages
        $Script:WingetPackage = @(
            @{ Id = "ezwinports.make"        ; Info = "" },
            @{ Id = "Task.Task"              ; Info = "" },
            @{ Id = "Ninja-build.Ninja"      ; Info = "" },
            @{ Id = "Ccache.Ccache"          ; Info = "" },
            @{ Id = "Python.Python.3.12"     ; Info = "" },
            @{ Id = "7zip.7zip"              ; Info = "" }
        )

        $Script:PipPackage = @(
            @{
                Name    = "sbom"
                Version = "1.0.0"
                Url     = "https://__token__:$Env:PIP_ACCESS_TOKEN@gitlab.com/api/v4/groups/1012/-/packages/pypi/simple"
                Info    = ""
            }
        )

        $Script:Download = @(
            @{
                Description = "GCC-ARM Toolchain"
                Url         = "https://developer.arm.com/-/media/Files/downloads/gnu/14.2.rel1/binrel/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi.tar.xz"
                Version     = "14.2.rel1"
                Path        = Join-Path -Path $Env:USERPROFILE -ChildPath "AppData/Local/Programs/Tools/arm-gnu-toolchain"
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
                Path        = Join-Path -Path $Env:USERPROFILE -ChildPath "AppData/Local/Programs/Tools/sonar-scanner"
                Info        = ""
            }
        )
    }

    process { }

    end { }
}

function Install-WingetPackage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [array] $Packages
    )

    begin {
        # Ensure winget is available
        if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
            Write-Error "winget is not installed or not found in PATH."
            return
        }
    }

    process {
        # Install each package
        foreach ($pkg in $Packages) {
            $id = $pkg.Id

            try {
                Write-Verbose "Installing Winget package: $($id)"

                winget install --id=$id -e --source machine --accept-package-agreements --accept-source-agreements --silent
            } catch {
                Write-Warning "Failed to install package: $($id) - $($_.Exception.Message)"
            }
        }
    }

    end { }
}

function Install-PipPackage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [array]$Packages
    )

    begin {
        # Ensure pip is available
        if (-not (Get-Command pip -ErrorAction SilentlyContinue)) {
            Write-Error "pip is not installed or not found in PATH."
            return
        }

        # Ensure pip is up to date
        try {
            Write-Verbose "Upgrading pip to the latest version..."
            pip install --upgrade pip
        } catch {
            Write-Warning "Failed to upgrade pip - $($_.Exception.Message)"
        }
    }

    process {
        # Install each package
        foreach ($pkg in $Packages) {
            $name = $pkg.Name
            $version = $pkg.Version
            $url = $pkg.Url

            try {
                Write-Verbose "Installing Python package: $name"

                if ($version) {
                    pip install "$name==$version" --index-url $url --upgrade --no-user
                } else {
                    pip install $name --index-url $url --upgrade --no-user
                }
            } catch {
                Write-Warning "Failed to install package: $($name) - $($_.Exception.Message)"
            }
        }
    }

    end { }
}

function Clear-PipCache {
    [CmdletBinding()]
    param ()

    begin {
        # Ensure pip is available
        if (-not (Get-Command pip -ErrorAction SilentlyContinue)) {
            Write-Error "pip is not installed or not found in PATH."
            return
        }
    }

    process {
        try {
            Write-Verbose "Cleaning pip cache..."

            pip cache purge
        } catch {
            Write-Warning "Failed to purge pip cache - $($_.Exception.Message)"
        }
    }

    end { }
}

function Invoke-SetupDownload {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [array] $Downloads
    )

    begin { }

    process {
        foreach ($item in $Downloads) {
            $filename = Split-Path $item.Url -Leaf
            $filepath = $item.Path
            $url = $item.Url
            $description = $item.Description

            try {
                Write-Verbose "[$description] Downloading from $url"

                Invoke-WebRequest -Uri $url -OutFile $filename -ErrorAction Stop
            } catch {
                Write-Error "[$description] Failed to download: $($_.Exception.Message)"
                continue
            }

            switch -Wildcard ($filename) {
                "arm-gnu-toolchain-*.tar.xz" {
                    try {
                        if (-not (Test-Path -Path $filepath)) {
                            New-Item -ItemType Directory -Force -Path $filepath | Out-Null
                        }

                        tar -xf $filename -C $filepath --strip-components=1

                        $envPath = Join-Path -Path $filepath -ChildPath "bin"
                        if ($Env:Path -notlike "*${envPath}*") {
                            $Env:Path += ";$envPath"
                        }

                        Write-Verbose "[$description] Extracted to $filepath"
                    } catch {
                        Write-Error "[$description] Failed: $($_.Exception.Message)"
                    } finally {
                        if (Test-Path $filename) {
                            Remove-Item -Path $filename -Force -Recurse -ErrorAction Stop
                        }
                    }
                }

                "PowerShell-*.msi" {
                    try {
                        Start-Process msiexec.exe -Wait -ArgumentList "/i `"$filename`" /quiet"
                        Write-Verbose "[$description] Installed"
                    } catch {
                        Write-Error "[$description] Failed: $($_.Exception.Message)"
                    } finally {
                        if (Test-Path $filename) {
                            Remove-Item -Path $filename -Force -Recurse -ErrorAction Stop
                        }
                    }
                }

                "sonar-scanner-*.zip" {
                    try {
                        if (-not (Test-Path -Path $filepath)) {
                            New-Item -ItemType Directory -Force -Path $filepath | Out-Null
                        }

                        Expand-Archive -LiteralPath $filename -DestinationPath $filepath -Force

                        $source = Get-ChildItem -Path $filepath -Directory -Filter "sonar-scanner-*" | Select-Object -First 1
                        Get-ChildItem -Path $source.FullName -Force | ForEach-Object {
                            Copy-Item -Path $_.FullName -Destination $filepath -Recurse -Force -ErrorAction SilentlyContinue
                        }
                        Remove-Item -Path $source.FullName -Force -Recurse -ErrorAction Stop

                        $envPath = Join-Path -Path $filepath -ChildPath "bin"
                        if ($Env:Path -notlike "*${envPath}*") {
                            $Env:Path += ";$envPath"
                        }

                        Write-Verbose "[$description] Extracted and installed to $filepath"
                    } catch {
                        Write-Error "[$description] Failed: $($_.Exception.Message)"
                    } finally {
                        if (Test-Path $filename) {
                            Remove-Item -Path $filename -Force -Recurse -ErrorAction Stop
                        }
                    }
                }

                default {
                    Write-Warning "[$description] No handler for file: $filename"
                }
            }
        }
    }

    end { }
}

# Workflow

try {
    Import-EnvironmentVariable -Verbose
    Initialize-ScopeVariable
    Install-WingetPackage -Packages $Script:WingetPackage -Verbose
    Install-PipPackage -Packages $Script:PipPackage -Verbose
    Clear-PipCache
    Invoke-SetupDownload -Downloads $Script:Download -Verbose
} catch {
    Write-Error "In: $PSCommandPath Error: $_"
    $Host.SetShouldExit(1)
}
