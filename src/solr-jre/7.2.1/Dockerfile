# escape=`
ARG BASE

FROM ${BASE} AS build
SHELL ["powershell.exe", "-Command", "$ErrorActionPreference='Stop';"]
COPY ./*.json ./
RUN [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 ; `
    Install-SitecoreConfiguration 'solr-jre.json' -Verbose *>&1 | Tee-Object 'build.log'

FROM build as test
SHELL ["powershell.exe", "-Command", "$ErrorActionPreference='Stop';"]
RUN node --version ; npm --version