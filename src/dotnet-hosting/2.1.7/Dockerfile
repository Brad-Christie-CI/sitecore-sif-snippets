# escape=`
ARG BASE

FROM ${BASE} AS build
SHELL ["powershell.exe", "-Command", "$ErrorActionPreference='Stop';"]
COPY ./*.json ./
RUN Install-SitecoreConfiguration 'dotnet-hosting.json' -Verbose *>&1 | Tee-Object 'build.log'

FROM build as test
SHELL ["powershell.exe", "-Command", "$ErrorActionPreference='Stop';"]
RUN Get-Package | Select-Object 'Name', 'Version'