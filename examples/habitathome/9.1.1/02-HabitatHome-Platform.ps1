Set-ExecutionPolicy Bypass -Scope Process
. "${PSScriptRoot}\Util.ps1"

# Clone Sitecore.HabitatHome.Platform
$habitatHomePlatform = Join-Path $PSScriptRoot -ChildPath "Sitecore.HabitatHome.Platform"
GitCloneOrCleanRepository "https://github.com/Sitecore/Sitecore.HabitatHome.Platform.git" $habitatHomePlatform

# Update Cake
Try {
  Push-Location $habitatHomePlatform

  $c = Get-Content ".\cake-config.json" | ConvertFrom-Json
  $c.ProjectFolder = $habitatHomePlatform
  $c.DeployFolder = Join-Path $PSScriptRoot -ChildPath "deploy"
  $c | ConvertTo-Json | Set-Content ".\cake-config.json"

  $buildArgs = @{
    Verbosity = "diagnostic"
  }
  Try {
    .\build.ps1 @buildArgs *>&1 | Tee-Object ".\build.log"
  } Catch {
    If ($_.Exception.Message -like "*Sync-Unicorn*") {
      "Retrying Post-Build..." | Add-Content ".\build.log"
      .\build.ps1 @buildArgs -Target "Post-Deploy" *>&1 | Tee-Object ".\build.log" -Append
    } Else {
      Throw
    }
  }
  #$msbuild = "C:/Program Files (x86)/Microsoft Visual Studio/2017/BuildTools/MSBuild/15.0/Bin/amd64/MSBuild.exe"
  #& $msbuild /v:minimal /p:Configuration="Debug" /p:Platform="Any CPU" /target:Clean,Rebuild /restore "HabitatHome.sln"
} Finally {
  Pop-Location
}