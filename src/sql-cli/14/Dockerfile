# escape=`
ARG BASE

FROM microsoft/mssql-server-windows-express:2017 AS build
SHELL ["powershell.exe", "-Command", "$ErrorActionPreference='Stop';"]
ENV ACCEPT_EULA=Y
ARG SIF_VERSION=2.1.0
RUN Install-PackageProvider -Name 'NuGet' -Force ; `
    Install-Module -Name 'PowerShellGet' -Force ; `
    Register-PSRepository 'SitecoreGallery' -SourceLocation 'https://sitecore.myget.org/F/sc-powershell/api/v2' -InstallationPolicy Trusted ; `
    Install-Module 'SitecoreInstallFramework' -RequiredVersion $env:SIF_VERSION -Repository 'SitecoreGallery'
WORKDIR /sif
COPY ./*.json ./
RUN Install-SitecoreConfiguration 'sql-cli.json' -Verbose *>&1 | Tee-Object 'build.log'

FROM build as test
SHELL ["powershell.exe", "-Command", "$ErrorActionPreference='Stop';"]
RUN Get-Package 'Microsoft Command Line Utilities 13 for SQL Server'