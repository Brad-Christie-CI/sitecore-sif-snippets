[CmdletBinding()]
Param(
  [Parameter()]
  [string]$SourcePath = ".\src"
  ,
  [Parameter()]
  [string[]]$Filter = @("*")
  ,
  [Parameter()]
  [string]$BaseImage = $null
)
Begin {
  $__eap = $ErrorActionPreference
  $ErrorActionPreference = "Stop"
  
  Get-Command "docker.exe" -CommandType "Application" | Out-Null
  
}
Process {
  If ([string]::IsNullOrWhiteSpace($BaseImage)) {
    $BaseImage = "mcr.microsoft.com/windows/servercore:{0}" -f (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ReleaseId
  }
  $baseImageTag = "{0}:latest" -f (Split-Path $PSScriptRoot -Leaf)
  $Dockerfile = @"
# escape=``
FROM ${BaseImage}
SHELL ["powershell.exe", "-Command", "`$ErrorActionPreference='Stop';`$ProgressPreference='SilentlyContinue';"]

# Update NuGet & Install SIF
RUN Add-WindowsFeature web-server ; ``
Install-PackageProvider -Name 'NuGet' -Force ; ``
Install-Module -Name 'PowerShellGet' -Force ; ``
Register-PSRepository 'SitecoreGallery' -SourceLocation 'https://sitecore.myget.org/F/sc-powershell/api/v2' -InstallationPolicy Trusted ; ``
Install-Module 'SitecoreInstallFramework' -Repository 'SitecoreGallery'

# Copy and run configuration
RUN New-Item c:\dev\ -ItemType Directory | Out-Null
WORKDIR /sif
"@
  Try {
    Write-Output "Building base image from ${BaseImage}...please wait"
    Write-Output "To show docker build output please include the -Verbose switch."
    $Dockerfile | docker build -t $baseImageTag --file - . | Write-Verbose
    If ($LASTEXITCODE -ne 0) {
      Throw "non-zero exit code ${LASTEXITCODE}"
    }
    Write-Output "BaseImage built successfully."
  } Catch {
    Write-Error "BaseImage build failure: $($_.Exception.Message)"
  }

  Get-Childitem "${SourcePath}\*" -Include "Dockerfile" -Recurse | ForEach-Object {
    $target = Split-Path (Split-Path $_.Directory -Parent) -Leaf
    $version = Split-Path $_.Directory -Leaf
    $tag = "${target}:${version}"

    $match = $Filter | ForEach-Object { $tag -like $_ -or $tag -like "${_}:*" }
    If ($match -notcontains $true) {
      Write-Output "Skipping ${tag} due to filter."
      Return
    } Else {
      Write-Output "Building ${tag}...please wait."
    }

    Try {
      docker build --tag $tag --build-arg BASE=${baseImageTag} $_.Directory | Write-Verbose
      If ($LASTEXITCODE -ne 0) {
        Throw "non-zero exit code ${LASTEXITCODE}."
      }
      Write-Output "${tag} built successfully."
    } Catch {
      Write-Warning "${tag} failed w/ error '$($_.Exception.Message)'"
    }
  }
}
End {
  $ErrorActionPreference = $__eap
}