$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$projectRoot = Split-Path $PSScriptRoot -Parent
$files = @(Get-ChildItem -LiteralPath (Join-Path $projectRoot 'assets/illustrations') -Filter '*.png')
$files += Get-Item -LiteralPath (Join-Path $projectRoot 'assets/branding/emblem-mockup.png')
foreach ($file in $files) {
  $limit = if ($file.Name -eq 'wave.png') { 1296 } elseif ($file.Name -eq 'splash-vehicles.png') { 1152 } elseif ($file.Name -eq 'emblem-mockup.png') { 512 } else { 864 }
  $source = [System.Drawing.Image]::FromFile($file.FullName)
  if ($source.Width -le $limit) { $source.Dispose(); continue }
  $height = [int][Math]::Round($source.Height * $limit / $source.Width)
  $bitmap = New-Object System.Drawing.Bitmap $limit,$height
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
  $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $attributes = New-Object System.Drawing.Imaging.ImageAttributes
  $attributes.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)
  $destination = New-Object System.Drawing.Rectangle 0,0,$limit,$height
  $graphics.DrawImage($source, $destination, 0, 0, $source.Width, $source.Height, [System.Drawing.GraphicsUnit]::Pixel, $attributes)
  $source.Dispose()
  $temporary = $file.FullName + '.optimized.png'
  $bitmap.Save($temporary, [System.Drawing.Imaging.ImageFormat]::Png)
  $graphics.Dispose()
  $attributes.Dispose()
  $bitmap.Dispose()
  Move-Item -LiteralPath $temporary -Destination $file.FullName -Force
  Write-Output "$($file.Name): $limit x $height"
}
