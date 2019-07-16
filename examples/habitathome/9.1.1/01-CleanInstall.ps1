Set-ExecutionPolicy Bypass -Scope Process
. "${PSScriptRoot}\Util.ps1"

# Define asset repository (place where license.xml and sc packages exist)
$packageRepository = Join-Path $env:HOMEDRIVE -ChildPath "${env:HOMEPATH}\Downloads"

# Bypass initial issue with TLS
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# Install basic prerequisites
@(
  "tls/1.2/tls.json"                      # machine level adjustment
  "7zip/1900/7zip.json"                   # for habitathome.util
  "git/2.22.0/git.json"                   # for use in habitathome.util and this installer
  "nodejs/10.16.0/nodejs.json"            # for creative exchange live (SXA) [front-end dev work]
  "solr-openjdk/7.3.1/solr-openjdk.json"  # for SOLR
  "sqlexpress/2016SP1/sqlexpress.json"    # for sitecore
  "iis/iis.json"                          # for sitecore
  "urlrewrite/2.1/urlrewrite.json"        # for sitecore
  "webdeploy/3.6/webdeploy.json"          # for deploying sitecore
  "vsbuildtools/2019/vsbuildtools.json"   # for building habitathome.platform
  "dotnet-sdk/4.7.1/dotnet-sdk.json"      # for building habitathome.platform
) | ForEach-Object {
  $uri = "https://raw.githubusercontent.com/Brad-Christie-CI/sitecore-sif-snippets/master/src/${_}"
  $basename = [IO.Path]::GetFileName($_)
  Install-RemoteSitecoreConfiguration $uri *>&1 | Tee-Object "${PSScriptRoot}\${basename}.log"
}

# update in-session $env:PATH based on installs above
RefreshEnv

# Clone Sitecore.HabitatHome.Utilities
$habitatHomeUtil = Join-Path $PSScriptRoot -ChildPath "Sitecore.HabitatHome.Utilities"
GitCloneOrCleanRepository "https://github.com/Sitecore/Sitecore.HabitatHome.Utilities.git" $habitatHomeUtil

# Install Sitecore prerequisites
Try {
  Push-Location (Join-Path $habitatHomeUtil -ChildPath "Prerequisites")

  .\Install-SitecorePrerequisites.ps1 *>&1 | Tee-Object "${PSScriptRooot}\Install-SitecorePrerequisites.ps1.log"

  RefreshEnv
} Finally {
  Pop-Location
}

# Install Sitecore XP
Try {
  Push-Location (Join-Path $habitatHomeUtil -ChildPath "XP\install")

  .\set-installation-defaults.ps1 -packageRepository $PackageRepository *>&1 | Tee-Object "${PSScriptRooot}\set-installation-defaults.ps1.log"

  # adjust & execute overrides
  $c = Get-Content ".\set-installation-overrides.ps1.example"
  $c = $c | ForEach-Object { $_.Replace('$solr.url = "https://localhost:8721/solr"', '$solr.url = "https://localhost:8983/solr"') }
  $c = $c | ForEach-Object { $_.Replace('$solr.root = "c:\solr\solr-7.2.1"', '$solr.root = "${env:programData}\solr-7.3.1"') }
  $c = $c | ForEach-Object { $_.Replace("Solr-7.2.1", "solr-7.3.1") }
  $c = $c | ForEach-Object { $_.Replace('$solr.serviceName = "Solr-7.2.1"', '$solr.serviceName = "Solr-7.3.1"') }
  $c = $c | ForEach-Object { $_.Replace("Str0NgPA33w0rd!!", "PublicPW2019") }
  $c | Set-Content ".\set-installation-overrides.ps1"
  .\set-installation-overrides.ps1 *>&1 | Tee-Object "${PSScriptRooot}set-installation-overrides.ps1.log"

  $scCreds = @{ devSitecoreUsername = $env:DEV_SITECORE_USER ; devSitecorePassword = $env:DEV_SITECORE_PASSWORD }

  # run singledeveloper install
  .\install-singledeveloper.ps1 @scCreds *>&1 | Tee-Object "${PSScriptRooot}\install-singledeveloper.ps1.log"
  
  # run install-modules
  .\install-modules.ps1 @scCreds *>&1 | Tee-Object "${PSScriptRooot}\install-modules.ps1.log"

  # Publish Site
  # TODO: Leverage SPE remote
  $sitecoreLoginUrl = "https://{0}/sitecore/login" -f (Get-Content ".\configuration-xp0.json" | ConvertFrom-Json).settings.site.hostName
  Start-Process $sitecoreLoginUrl
  Read-Host -Prompt "Sitecore site must be published before continuing. Please do so, and press ENTER when finished."
} Finally {
  Pop-Location
}