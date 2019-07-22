[CmdletBinding()]
Param(
  [Parameter()]
  [string[]]$Filter = @("*")
  ,
  [Parameter()]
  [AllowNull()]
  [Alias("BaseImage")]
  [string]$Base = $null
  ,
  [Parameter()]
  [string]$ReleaseId = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ReleaseId
  ,
  [Parameter()]
  [ValidatePattern("^\d+(?:\.\d+){,2}$")]
  [string]$SifVersion = "2.1.0"
)
Begin {
  $__eap = $ErrorActionPreference
  $__ia = $InformationPreference
  $__pp = $ProgressPreference

  $ErrorActionPreference = "Stop"
  $InformationPreference = "Continue"
  $ProgressPreference = "SilentlyContinue"

  $SourcePath = Join-Path $PSScriptRoot -ChildPath "src"

  Write-Information "To show docker build output please include the -Verbose switch."
}
Process {
  $docker = Get-Command "docker.exe" -CommandType "Application" -ErrorAction SilentlyContinue
  If ($null -eq $docker) {
    Throw "Docker.exe not found, unable to continue."
  }

  $Dockerfile = Join-Path $PSScriptRoot -ChildPath "Dockerfile"
  If (!(Test-Path $Dockerfile)) {
    Throw "Dockerfile not found, unable to continue."
  }

  If ([string]::IsNullOrWhiteSpace($Base)) {
    $Base = "mcr.microsoft.com/windows/servercore:${ReleaseId}"
  }
  $BaseTag = "sitecoreinstallframework:${SifVersion}-${releaseId}"
  
  $ExistingBase = & docker.exe images -q $BaseTag
  If ($null -eq $ExistingBase) {
    Write-Output "Building SIF image ${BaseTag}..."
    & docker.exe build `
      --tag $BaseTag `
      --build-arg "RELEASEID=${ReleaseId}" `
      --build-arg "BASE=${Base}" `
      --file $Dockerfile `
      $PSScriptRoot | Write-Verbose
    If ($LASTEXITCODE -ne 0) {
      Throw "Unable to build SIF base image, non-zero exit code: ${LASTEXITCODE}"
    }
  } Else {
    Write-Output "SIF image: ${BaseTag}"
  }

  Get-Childitem $SourcePath -Include "Dockerfile" -Recurse | ForEach-Object {
    $target = Split-Path (Split-Path $_.Directory -Parent) -Leaf
    $version = Split-Path $_.Directory -Leaf
    $tag = "${target}:${version}"

    $match = $Filter | ForEach-Object { $tag -like $_ -or $tag -like "${_}:*" }
    If ($match -notcontains $true) {
      Write-Output "Skipping ${tag} due to filter."
      Return
    }
    
    Write-Output "Building ${tag}..."
    Try {
      & docker.exe build `
        --tag $tag `
        --build-arg "BASE=${BaseTag}" `
        $_.Directory | Write-Verbose
      If ($LASTEXITCODE -ne 0) {
        Throw "non-zero exit code ${LASTEXITCODE}."
      }
      Write-Output "${tag} built successfully."
    } Catch {
      Write-Warning "${tag} failed, '$($_.Exception.Message)'"
    }
  }
}
End {
  $ErrorActionPreference = $__eap
  $InformationPreference = $__ia
  $ProgressPreference = $__pp
}