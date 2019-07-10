# escape=`
ARG BASE

FROM ${BASE} AS build
SHELL ["powershell.exe", "-Command", "$ErrorActionPreference='Stop';"]
COPY ./*.json ./
RUN Install-SitecoreConfiguration '7zip.json' -Verbose *>&1 | Tee-Object 'build.log'

FROM build as test
SHELL ["powershell.exe", "-Command", "$ErrorActionPreference='Stop';"]
RUN $testPath = Join-Path $env:ProgramFiles -ChildPath '7-Zip' ; `
    If (!(Test-Path $testPath)) { Write-Error "7-Zip installation path not found." }