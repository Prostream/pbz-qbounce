param(
    [ValidateSet('Install','DisableMod','DisableLoader')][string]$Action = 'Install',
    [Parameter(Mandatory=$true)][string]$GameRoot
)
$ErrorActionPreference = 'Stop'
$game = (Resolve-Path -LiteralPath $GameRoot).Path
$target = [IO.Path]::GetFullPath((Join-Path $game 'platform\steam'))
if (-not $target.StartsWith($game.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Target outside game root' }
$exe = Join-Path $target 'PBZ.exe'
if (-not (Test-Path -LiteralPath $exe)) { throw 'Real PBZ executable not found' }
if (Get-Process PBZ -ErrorAction SilentlyContinue) { throw 'Exit PBZ before installing or disabling' }
$loader = Join-Path $target 'dwmapi.dll'
$modList = Join-Path $target 'ue4ss\Mods\mods.txt'
if ($Action -eq 'DisableLoader') {
    $expected = (Get-FileHash -LiteralPath (Join-Path $PSScriptRoot 'build\platform\steam\dwmapi.dll')).Hash
    if ((Get-FileHash -LiteralPath $loader).Hash -ne $expected) { throw 'Loader changed; refusing to rename another installation' }
    Rename-Item -LiteralPath $loader -NewName 'dwmapi.dll.qbounce-disabled'
    Write-Output 'Loader disabled reversibly. No game resources changed.'
    return
}
if ($Action -eq 'DisableMod') {
    $contents = [IO.File]::ReadAllText($modList)
    $contents = [regex]::Replace($contents, '(?m)^PBZ_QBounce\s*:\s*1\s*$', 'PBZ_QBounce : 0')
    [IO.File]::WriteAllText($modList, $contents, [Text.UTF8Encoding]::new($false))
    Write-Output 'PBZ_QBounce disabled. Restart the game.'
    return
}
if ((Test-Path -LiteralPath $loader) -or (Test-Path -LiteralPath (Join-Path $target 'ue4ss'))) {
    throw 'An existing loader was found. No files overwritten; inspect it before merging.'
}
if ((Get-Item -LiteralPath $exe).VersionInfo.FileVersion -ne 'CL-301524_JKS-17219') {
    throw 'Game build differs from the inspected PBZ loader target. Recheck compatibility.'
}
$stage = Join-Path $PSScriptRoot 'build\platform\steam'
$manifest = Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'build\manifest.json') | ConvertFrom-Json
# Preflight every file and hash before writing anything into the game.
foreach ($prop in $manifest.PSObject.Properties) {
    $source = Join-Path $stage $prop.Name
    $dest = [IO.Path]::GetFullPath((Join-Path $target $prop.Name))
    if (-not $dest.StartsWith($target + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe manifest path' }
    if (Test-Path -LiteralPath $dest) { throw "Refusing overwrite: $dest" }
    if ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToLowerInvariant() -ne $prop.Value) { throw "Source hash mismatch: $source" }
}
# Install proxy last: an interrupted copy cannot activate an incomplete loader.
$ordered = @($manifest.PSObject.Properties | Where-Object Name -ne 'dwmapi.dll') + @($manifest.PSObject.Properties | Where-Object Name -eq 'dwmapi.dll')
foreach ($prop in $ordered) {
    $dest = Join-Path $target $prop.Name
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($dest)) | Out-Null
    Copy-Item -LiteralPath (Join-Path $stage $prop.Name) -Destination $dest
    if ((Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash.ToLowerInvariant() -ne $prop.Value) { throw "Installed hash mismatch: $dest" }
}
@{ installedAt = (Get-Date).ToString('o'); target=$target; files=$manifest } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'install-receipt.json') -Encoding UTF8
Write-Output "Installed and hash-verified $($ordered.Count) files into $target"
Write-Output 'Ready for in-game verification. F6 toggle, F7 strength, F8 reset, F9 diagnostics.'
