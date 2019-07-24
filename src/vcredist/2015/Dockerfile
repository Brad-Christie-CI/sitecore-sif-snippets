# escape=`
ARG BASE

FROM ${BASE} AS build
SHELL ["powershell.exe", "-Command", "$ErrorActionPreference='Stop';"]
COPY ./*.json ./
RUN Install-SitecoreConfiguration 'vcredist.json' -Verbose *>&1 | Tee-Object 'build.log'

FROM build as test
SHELL ["powershell.exe", "-Command", "$ErrorActionPreference='Stop';"]
RUN Get-Package 'Microsoft Visual C++ 2015 Redistributable * - 14.0.24212'