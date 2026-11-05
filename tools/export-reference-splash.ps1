param([string]$Source = 'docs/screenshots/visual-fidelity/splash-native.png')
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$projectRoot = Split-Path $PSScriptRoot -Parent
$scene = [System.Drawing.Image]::FromFile((Join-Path $projectRoot $Source))

function Export-Scene([string]$RelativePath, [int]$Width, [int]$Height) {
  $target = Join-Path $projectRoot $RelativePath
  [System.IO.Directory]::CreateDirectory((Split-Path $target -Parent)) | Out-Null
  $bitmap = New-Object System.Drawing.Bitmap $Width,$Height
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.Clear([System.Drawing.ColorTranslator]::FromHtml('#174B96'))
  $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $graphics.DrawImage($scene, 0, 0, $Width, $Height)
  $bitmap.Save($target, [System.Drawing.Imaging.ImageFormat]::Png)
  $graphics.Dispose()
  $bitmap.Dispose()
}

Export-Scene 'android/app/src/main/res/drawable-nodpi/splash_scene.png' 780 1648
foreach ($scale in 1..3) {
  $suffix = if ($scale -eq 1) { '' } else { "@${scale}x" }
  Export-Scene "ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage$suffix.png" (390*$scale) (824*$scale)
}
$scene.Dispose()

$logo = [System.Drawing.Bitmap]::FromFile((Join-Path $projectRoot 'assets/branding/emblem-mockup.png'))
$inverse = New-Object System.Drawing.Bitmap 512,512
for ($y = 0; $y -lt 512; $y++) {
  for ($x = 0; $x -lt 512; $x++) {
    $pixel = $logo.GetPixel($x, $y)
    $alpha = [int][Math]::Round([Math]::Max(0, [Math]::Min(255, 1.5*$pixel.A - 0.75*$pixel.R - 0.75*$pixel.G)))
    $inverse.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($alpha, 255, 255, 255))
  }
}
$inverse.Save((Join-Path $projectRoot 'android/app/src/main/res/drawable-nodpi/splash_emblem_white.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$inverse.Dispose()
$logo.Dispose()
