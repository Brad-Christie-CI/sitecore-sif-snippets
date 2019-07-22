# escape=`

ARG RELEASEID=ltsc2016
ARG BASE=mcr.microsoft.com/windows/servercore:${RELEASEID}

FROM ${BASE} AS sitecoreinstallframework
SHELL ["powershell.exe", "-Command", "$ErrorActionPreference='Stop';$ProgressPreference='SilentlyContinue';"]

RUN Install-PackageProvider -Name 'NuGet' -Force ; `
    Install-Module -Name 'PowerShellGet' -Force ; `
    Register-PSRepository 'SitecoreGallery' -SourceLocation 'https://sitecore.myget.org/F/sc-powershell/api/v2' -InstallationPolicy Trusted ; `
    Install-Module 'SitecoreInstallFramework' -Repository 'SitecoreGallery'

WORKDIR /sif