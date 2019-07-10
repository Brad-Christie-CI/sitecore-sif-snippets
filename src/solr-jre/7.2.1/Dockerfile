# escape=`
ARG BASE

FROM ${BASE} AS build
SHELL ["powershell.exe", "-Command", "$ErrorActionPreference='Stop';"]
COPY ./*.json ./
RUN [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 ; `
    Install-SitecoreConfiguration 'solr-jre.json' -Verbose *>&1 | Tee-Object 'build.log'

FROM build as test
SHELL ["powershell.exe", "-Command", "$ErrorActionPreference='Stop';"]
RUN Get-Service 'solr-7.3.1' ; `
    # just needs a little break starting up
    Start-Sleep 5 ; `
    Invoke-WebRequest 'https://localhost:8983/solr/' -UseBasicParsing | Select-Object 'StatusCode', 'StatusDescription'