[CmdletBinding()]
Param(
  [Parameter(Position = 0)]
  [string[]]$Filter = @("*.json")
)
Begin {
  $eap = $ErrorActionPreference

  $ErrorActionPreference = "Stop"

  Get-Command docker -CommandType Application | Out-Null
}
Process {
  Get-ChildItem "${PSScriptRoot}\src\" -Include $Filter -Recurse | ForEach-Object {
    $Target = $_.FullName.Replace($PSScriptRoot, ".")
    $InstallParameters = @("-Path", $Target)
    $Dockerfile = @"
# escape=``
FROM mcr.microsoft.com/windows/servercore/iis:windowsservercore
SHELL ["powershell.exe", "-Command", "`$ErrorActionPreference='Stop';`$ProgressPreference='SilentlyContinue';"]

# Update NuGet & Install SIF
RUN Install-PackageProvider -Name 'NuGet' -Force ; ``
    Install-Module -Name 'PowerShellGet' -Force ; ``
    Register-PSRepository 'SitecoreGallery' -SourceLocation 'https://sitecore.myget.org/F/sc-powershell/api/v2' -InstallationPolicy Trusted ; ``
    Install-Module 'SitecoreInstallFramework' -Repository 'SitecoreGallery'

# Copy and run configuration
RUN New-Item c:\dev\ -ItemType Directory | Out-Null
WORKDIR /dev

COPY . .
RUN [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12 ; ``
    Install-SitecoreConfiguration $($InstallParameters -join " ")
"@

    $Dockerfile | & docker build --label config="${Target}" -f - .
    If ($LASTEXITCODE -ne 0) {
      Write-Error "'${Target}' failed."
    }
  }
}
End {
  $ErrorActionPreference = $eap
}