# sitecore-sif-snippets
Collection of one-off snippets for performing tasks on a server via Sitecore Install Framework (SIF).

## Example Usage

Setup a helper function:

```
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
```

Call helper function:

```
$config = "https://raw.githubusercontent.com/Brad-Christie-CI/sitecore-sif-snippets/master/src/tls/1.2/tls.json"
Install-RemoteSitecoreConfiguration $config
```

Need more control? Supply your own `-ScriptBlock`:

```
$config = "https://raw.githubusercontent.com/Brad-Christie-CI/sitecore-sif-snippets/master/src/tls/1.2/tls.json"
Install-RemoteSitecoreConfiguration $config -ScriptBlock {
  Install-SitecoreConfiguration -Path $_ -Verbose 
}
```

### TLS Handshake error?

Might have to temporarily enable TLS 1.2

```
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
```

From there, be sure to install `src/tls/1.2/tls.json` so it's enabled at the machine level.