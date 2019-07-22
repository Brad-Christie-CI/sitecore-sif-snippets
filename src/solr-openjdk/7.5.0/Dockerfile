# escape=`
ARG BASE

FROM ${BASE} AS build
SHELL ["powershell.exe", "-Command", "$ErrorActionPreference='Stop';"]
COPY ./*.json ./
RUN [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 ; `
    Install-SitecoreConfiguration 'solr-openjdk.json' -Verbose *>&1 | Tee-Object 'build.log'

FROM build as test
SHELL ["powershell.exe", "-Command", "$ErrorActionPreference='Stop';"]
RUN Get-Service 'solr-7.5.0' ; `
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 ; `
    Start-Sleep -Seconds 15 ; `
    Invoke-WebRequest 'https://localhost:8983/solr/' -UseBasicParsing | Select-Object 'StatusCode', 'StatusDescription'