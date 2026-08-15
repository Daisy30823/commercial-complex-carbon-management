param(
    [string]$WarPath = "target\commercial-complex-carbon.war"
)

$ErrorActionPreference = "Stop"
$pattern = '课程设计|模拟|功能验收|临时测试|测试综合体|测试建筑|测试区域|测试商户|测试节点|测试设备|demo|test-|acc-|仅供本地课程答辩使用'
$sourceFiles = Get-ChildItem "src\main" -Recurse -File |
    Where-Object { $_.Extension -in '.jsp','.js','.java','.html','.css' -and $_.FullName -notmatch '\\vendor\\' }
$sourceHits = @($sourceFiles | Select-String -Pattern $pattern -CaseSensitive:$false)

$warHits = @()
if (Test-Path $WarPath) {
    $tempRoot = Join-Path ([IO.Path]::GetTempPath()) ("carbon-war-scan-" + [guid]::NewGuid())
    New-Item -ItemType Directory -Path $tempRoot | Out-Null
    try {
        $zipPath = Join-Path $tempRoot 'application.zip'
        Copy-Item -LiteralPath $WarPath -Destination $zipPath
        Expand-Archive -LiteralPath $zipPath -DestinationPath (Join-Path $tempRoot 'expanded')
        $warFiles = Get-ChildItem (Join-Path $tempRoot 'expanded') -Recurse -File |
            Where-Object { $_.Extension -in '.jsp','.js','.html','.css' -and $_.FullName -notmatch '\\vendor\\' }
        $warHits = @($warFiles | Select-String -Pattern $pattern -CaseSensitive:$false)
    } finally {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}

Write-Host "源码用户可见痕迹：$($sourceHits.Count) 处"
Write-Host "WAR 用户可见痕迹：$($warHits.Count) 处"
if ($sourceHits.Count -gt 0) { $sourceHits | Format-Table Path,LineNumber,Line -AutoSize }
if ($warHits.Count -gt 0) { $warHits | Format-Table Path,LineNumber,Line -AutoSize }
if ($sourceHits.Count -gt 0 -or $warHits.Count -gt 0) { exit 1 }
