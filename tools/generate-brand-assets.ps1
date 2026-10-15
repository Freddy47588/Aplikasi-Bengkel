# Reproducible geometric B mark. Run from repository root on Windows.
Add-Type -AssemblyName System.Drawing
function Write-Mark([string]$Path, [int]$Size) {
  $bitmap = [System.Drawing.Bitmap]::new($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.SmoothingMode = 'AntiAlias'
  $graphics.Clear([System.Drawing.Color]::FromArgb(15,23,42))
  $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(14,165,233))
  $white = [System.Drawing.Brushes]::White
  $graphics.FillEllipse($brush, [single]($Size*.14), [single]($Size*.14), [single]($Size*.72), [single]($Size*.72))
  $graphics.FillRectangle($white, [single]($Size*.34), [single]($Size*.29), [single]($Size*.09), [single]($Size*.42))
  $graphics.FillEllipse($white, [single]($Size*.37), [single]($Size*.29), [single]($Size*.27), [single]($Size*.24))
  $graphics.FillEllipse($white, [single]($Size*.37), [single]($Size*.47), [single]($Size*.29), [single]($Size*.24))
  $graphics.FillEllipse($brush, [single]($Size*.43), [single]($Size*.36), [single]($Size*.12), [single]($Size*.09))
  $graphics.FillEllipse($brush, [single]($Size*.43), [single]($Size*.55), [single]($Size*.12), [single]($Size*.09))
  $bitmap.Save([IO.Path]::GetFullPath($Path), [System.Drawing.Imaging.ImageFormat]::Png)
  $graphics.Dispose(); $bitmap.Dispose(); $brush.Dispose()
}
$androidSizes = @{mdpi=48;hdpi=72;xhdpi=96;xxhdpi=144;xxxhdpi=192}
foreach ($density in $androidSizes.Keys) { Write-Mark "android/app/src/main/res/mipmap-$density/ic_launcher.png" $androidSizes[$density] }
$catalog = Get-Content ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json -Raw | ConvertFrom-Json
foreach ($entry in $catalog.images) { $size = [int]([double]($entry.size.Split('x')[0]) * [double]($entry.scale.Replace('x',''))); Write-Mark "ios/Runner/Assets.xcassets/AppIcon.appiconset/$($entry.filename)" $size }
foreach ($scale in 1..3) { $suffix = if ($scale -eq 1) { '' } else { "@${scale}x" }; Write-Mark "ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage$suffix.png" (96*$scale) }
