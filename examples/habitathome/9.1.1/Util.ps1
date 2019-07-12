# Uncomment to avoid being prompted later by HabitatHome utils & platform installers
# cake diurectly referenced DEV_SITECORE_*, but we hand it off to HabitatHome.Utils
#$env:DEV_SITECORE_USERNAME = "<dev.sitecore.net/username>"
#$env:DEV_SITECORE_PASSWORD = "<dev.sitecore.net/password>"

# branches to target when pulling from HabitatHome repos
$DefaultBranch = "release/9.1.1"

Function GitCloneOrCleanRepository {
  [CmdletBinding()]
  Param(
    [Parameter(Position = 0, Mandatory)]
    [string]$Repository
    ,
    [Parameter(Position = 1, Mandatory)]
    [ValidateScript({ Test-Path $_ -IsValid })]
    [string]$Destination
    ,
    [Parameter()]
    [string]$Branch = $DefaultBranch
  )
  Process {
    If (!(Test-Path $Destination -PathType Container)) {
      Try {
        git clone -b $Branch --single-branch $Repository $habitatHomeUtil
      } Catch {
        # --single-branch may not work; fallback just in case
        git clone $Repository $Destination
        git checkout $Branch
      }
    } Else {
      Try {
        Push-Location $Destination
        git fetch origin
        git reset --hard '@{u}'
        git clean -fxd
      } Finally {
        Pop-Location
      }
    }
  }
}

Function Install-RemoteSitecoreConfiguration {
  [CmdletBinding(SupportsShouldProcess)]
  Param(
    [Parameter(Position = 0, Mandatory, ValueFromPipeline)]
    [uri[]]$Uri
    ,
    [Parameter(Position = 1)]
    [scriptblock]$ScriptBlock = { Install-SitecoreConfiguration -Path $_ }
  )
  Process {
    $Uri | ForEach-Object {
      $config = Join-Path $env:TEMP -ChildPath ("{0}.json" -f (New-Guid).ToString("n"))
      If ($PSCmdlet.ShouldProcess("Download '${_}' to '${config}'")) {
        Invoke-WebRequest $_ -OutFile $config -UseBasicParsing
      }

      $ps = $null
      Try {
        If ($PSCmdlet.ShouldProcess("Execute install script")) {
          $ps = [powershell]::Create()
          [void]$ps.AddScript("param(`$_);$($ScriptBlock.ToString())")
          [void]$ps.AddParameter("_", $config)

          Return $ps.Invoke()
        }
      } Finally {
        If ($ps) {
          $ps.Dispose()
        }
        If ($PSCmdlet.ShouldProcess("Cleanup '${config}'") -and (Test-Path $config)) {
          Remove-Item $config -Force
        }
      }
    }
  }
}

Function RefreshEnv {
  [CmdletBinding()]
  Param()
  Process {
    $machinePath = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::Machine)
    $userPath = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::User)
    $processPath = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::Process)

    $env:PATH = $machinePath, $userPath, $processPath -join ([System.IO.Path]::PathSeparator)
  }
}