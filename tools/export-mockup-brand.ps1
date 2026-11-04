$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$projectRoot = Split-Path $PSScriptRoot -Parent
$logo = [System.Drawing.Image]::FromFile((Join-Path $projectRoot 'assets/branding/emblem-mockup.png'))
$background = [System.Drawing.ColorTranslator]::FromHtml('#F8FAFC')

function Export-Logo([string]$RelativePath, [int]$Width, [int]$Height, [bool]$Opaque, [double]$Scale = 1) {
  $target = Join-Path $projectRoot $RelativePath
  [System.IO.Directory]::CreateDirectory((Split-Path $target -Parent)) | Out-Null
  $bitmap = New-Object System.Drawing.Bitmap $Width,$Height
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  if ($Opaque) { $graphics.Clear($background) }
  $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $side = [int]([Math]::Min($Width,$Height) * $Scale)
  $graphics.DrawImage($logo, [int](($Width-$side)/2), [int](($Height-$side)/2), $side, $side)
  $bitmap.Save($target, [System.Drawing.Imaging.ImageFormat]::Png)
  $graphics.Dispose()
  $bitmap.Dispose()
}

foreach ($density in @{mdpi=48; hdpi=72; xhdpi=96; xxhdpi=144; xxxhdpi=192}.GetEnumerator()) {
  Export-Logo "android/app/src/main/res/mipmap-$($density.Key)/ic_launcher.png" $density.Value $density.Value $true
}
Export-Logo 'android/app/src/main/res/drawable-nodpi/brand_emblem_mockup_image.png' 512 512 $false 1
Export-Logo 'android/app/src/main/res/drawable-nodpi/splash_lockup.png' 400 480 $false 0.65

$iconDir = Join-Path $projectRoot 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
foreach ($icon in (Get-Content -Raw (Join-Path $iconDir 'Contents.json') | ConvertFrom-Json).images) {
  $size = [int]([double]($icon.size.Split('x')[0]) * [double]($icon.scale.TrimEnd('x')))
  Export-Logo "ios/Runner/Assets.xcassets/AppIcon.appiconset/$($icon.filename)" $size $size $true
}
foreach ($scale in 1..3) {
  $suffix = if ($scale -eq 1) { '' } else { "@${scale}x" }
  Export-Logo "ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage$suffix.png" (200*$scale) (240*$scale) $false 0.65
}
$logo.Dispose()
