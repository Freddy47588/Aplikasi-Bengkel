# Original BengkelKu emblem: hexagonal housing, six-tooth rotor and hex axle.
# Reproducible on Windows PowerShell; no network, external art or packages.
param([string]$Root = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$navy = '#1E3A5F'; $blue = '#2563EB'; $offWhite = '#F8FAFC'
$rotor = for ($i = 0; $i -lt 24; $i++) {
  $angle = ($i * 15 - 90) * [Math]::PI / 180
  $radius = if (($i % 4) -lt 2) { 17 } else { 13 }
  '{0},{1}' -f (50 + [Math]::Cos($angle)*$radius).ToString('0.####', [Globalization.CultureInfo]::InvariantCulture), (50 + [Math]::Sin($angle)*$radius).ToString('0.####', [Globalization.CultureInfo]::InvariantCulture)
}
$shapes = @(
  @{Color=$blue; Points='50,20 76,35 76,65 50,80 24,65 24,35'},
  @{Color=$navy; Points='50,27 70,38.5 70,61.5 50,73 30,61.5 30,38.5'},
  @{Color=$offWhite; Points=($rotor -join ' ')},
  @{Color=$navy; Points='50,42 57,46 57,54 50,58 43,54 43,46'}
)
function Save-Png([string]$Path, [int]$Size, [bool]$Opaque = $true, [bool]$Lockup = $false) {
  $full = Join-Path $Root $Path
  [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($full)) | Out-Null
  $height = if ($Lockup) { [int]($Size * 1.2) } else { $Size }
  $pixelFormat = if ($Opaque) { [Drawing.Imaging.PixelFormat]::Format24bppRgb } else { [Drawing.Imaging.PixelFormat]::Format32bppArgb }
  $bitmap = [Drawing.Bitmap]::new($Size, $height, $pixelFormat)
  $g = [Drawing.Graphics]::FromImage($bitmap)
  $g.SmoothingMode = 'AntiAlias'
  $g.Clear($(if ($Opaque) { [Drawing.ColorTranslator]::FromHtml($navy) } else { [Drawing.Color]::Transparent }))
  foreach ($shape in $shapes) {
    [Drawing.PointF[]]$points = @($shape.Points.Split(' ') | ForEach-Object {
      $xy = $_.Split(',')
      [Drawing.PointF]::new(([single]::Parse($xy[0],[Globalization.CultureInfo]::InvariantCulture)*$Size/100), ([single]::Parse($xy[1],[Globalization.CultureInfo]::InvariantCulture)*$Size/100))
    })
    $brush = [Drawing.SolidBrush]::new([Drawing.ColorTranslator]::FromHtml($shape.Color))
    $g.FillPolygon($brush, $points); $brush.Dispose()
  }
  if ($Lockup) {
    $font = [Drawing.Font]::new('Segoe UI', [single]($Size*.13), [Drawing.FontStyle]::Bold, [Drawing.GraphicsUnit]::Pixel)
    $format = [Drawing.StringFormat]::new(); $format.Alignment = 'Center'
    $g.DrawString('BengkelKu', $font, [Drawing.Brushes]::White, [Drawing.RectangleF]::new(0, [single]($Size*.88), $Size, [single]($Size*.25)), $format)
    $format.Dispose(); $font.Dispose()
  }
  $bitmap.Save($full, [Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose(); $bitmap.Dispose()
}
$svgShapes = ($shapes | ForEach-Object { '<polygon fill="' + $_.Color + '" points="' + $_.Points + '"/>' }) -join "`n"
$svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" role="img" aria-label="BengkelKu hex rotor">' + "`n$svgShapes`n</svg>"
[IO.Directory]::CreateDirectory((Join-Path $Root 'assets/branding')) | Out-Null
[IO.File]::WriteAllText((Join-Path $Root 'assets/branding/emblem.svg'), $svg)
Save-Png 'assets/branding/emblem.png' 512 $false
Save-Png 'assets/branding/launcher-master.png' 1024
Save-Png 'assets/branding/splash-lockup.png' 600 $false $true
$sizes = @{mdpi=48;hdpi=72;xhdpi=96;xxhdpi=144;xxxhdpi=192}
foreach ($density in $sizes.Keys) { Save-Png "android/app/src/main/res/mipmap-$density/ic_launcher.png" $sizes[$density] }
$catalog = Get-Content (Join-Path $Root 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json') -Raw | ConvertFrom-Json
foreach ($entry in $catalog.images) {
  $size = [int]([double]::Parse($entry.size.Split('x')[0], [Globalization.CultureInfo]::InvariantCulture) * [double]$entry.scale.Replace('x',''))
  Save-Png "ios/Runner/Assets.xcassets/AppIcon.appiconset/$($entry.filename)" $size
}
foreach ($scale in 1..3) {
  $suffix = if ($scale -eq 1) { '' } else { "@${scale}x" }
  Save-Png "ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage$suffix.png" (200*$scale) $false $true
}
Save-Png 'android/app/src/main/res/drawable-nodpi/splash_lockup.png' 600 $false $true
foreach ($density in $sizes.Keys) {
  $factor = $sizes[$density] / 48
  $bitmap = [Drawing.Bitmap]::new([int](200*$factor), [int](80*$factor))
  $g = [Drawing.Graphics]::FromImage($bitmap)
  $g.Clear([Drawing.Color]::Transparent)
  $g.TextRenderingHint = 'AntiAliasGridFit'
  $font = [Drawing.Font]::new('Segoe UI', [single](26*$factor), [Drawing.FontStyle]::Bold, [Drawing.GraphicsUnit]::Pixel)
  $format = [Drawing.StringFormat]::new(); $format.Alignment = 'Center'; $format.LineAlignment = 'Center'
  $g.DrawString('BengkelKu', $font, [Drawing.Brushes]::White, [Drawing.RectangleF]::new(0, 0, $bitmap.Width, $bitmap.Height), $format)
  $dir = Join-Path $Root "android/app/src/main/res/drawable-$density"
  [IO.Directory]::CreateDirectory($dir) | Out-Null
  $bitmap.Save((Join-Path $dir 'brand_wordmark.png'), [Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose(); $bitmap.Dispose(); $font.Dispose(); $format.Dispose()
}
$paths = ($shapes | ForEach-Object {
  $points = $_.Points.Split(' ')
  '<path android:fillColor="' + $_.Color + '" android:pathData="M' + ($points -join ' L') + ' Z"/>'
}) -join "`n"
$vector = '<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="100" android:viewportHeight="100">' + "`n$paths`n</vector>"
[IO.File]::WriteAllText((Join-Path $Root 'android/app/src/main/res/drawable/brand_emblem.xml'), $vector)
Write-Output 'Generated universal BengkelKu assets (Flutter, Android, iOS).'
