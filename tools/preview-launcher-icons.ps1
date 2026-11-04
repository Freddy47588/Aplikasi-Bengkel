$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$projectRoot = Split-Path $PSScriptRoot -Parent
$outputDir = Join-Path $projectRoot 'build/visual-fidelity'
[System.IO.Directory]::CreateDirectory($outputDir) | Out-Null
$logo = [System.Drawing.Bitmap]::FromFile((Join-Path $projectRoot 'assets/branding/emblem-mockup.png'))
$legacy = [System.Drawing.Image]::FromFile((Join-Path $projectRoot 'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png'))
$background = [System.Drawing.ColorTranslator]::FromHtml('#F8FAFC')
$maxRadius = 0.0
for ($y = 0; $y -lt $logo.Height; $y++) {
  for ($x = 0; $x -lt $logo.Width; $x++) {
    if ($logo.GetPixel($x, $y).A -lt 64) { continue }
    $dx = ($x + 0.5 - $logo.Width/2) * 72 / $logo.Width
    $dy = ($y + 0.5 - $logo.Height/2) * 72 / $logo.Height
    $maxRadius = [Math]::Max($maxRadius, [Math]::Sqrt($dx*$dx + $dy*$dy))
  }
}
if ($maxRadius -gt 33) { throw "Foreground exceeds the 66dp safe circle: radius $maxRadius" }
$sheet = New-Object System.Drawing.Bitmap 960,320
$graphics = [System.Drawing.Graphics]::FromImage($sheet)
$graphics.Clear([System.Drawing.ColorTranslator]::FromHtml('#E2E8F0'))
$font = New-Object System.Drawing.Font 'Arial',14
$labels = @('Circle', 'Rounded square', 'Squircle', 'Legacy 192px')
for ($i = 0; $i -lt 4; $i++) {
  $tile = New-Object System.Drawing.Bitmap 216,216
  $g = [System.Drawing.Graphics]::FromImage($tile)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  if ($i -eq 0) { $path.AddEllipse(0,0,216,216) }
  elseif ($i -eq 1) {
    $path.AddArc(0,0,64,64,180,90); $path.AddArc(152,0,64,64,270,90)
    $path.AddArc(152,152,64,64,0,90); $path.AddArc(0,152,64,64,90,90); $path.CloseFigure()
  } elseif ($i -eq 2) {
    $points = for ($step=0; $step -lt 180; $step++) {
      $angle = $step * 2 * [Math]::PI / 180
      $cos = [Math]::Cos($angle); $sin = [Math]::Sin($angle)
      New-Object System.Drawing.PointF ([single](108 + 108*[Math]::Sign($cos)*[Math]::Sqrt([Math]::Abs($cos)))),([single](108 + 108*[Math]::Sign($sin)*[Math]::Sqrt([Math]::Abs($sin))))
    }
    $path.AddPolygon([System.Drawing.PointF[]]$points)
  } else { $path.AddRectangle((New-Object System.Drawing.Rectangle 0,0,216,216)) }
  $g.SetClip($path)
  $g.Clear($background)
  if ($i -eq 3) { $g.DrawImage($legacy,0,0,216,216) }
  else { $g.DrawImage($logo,0,0,216,216) }
  $graphics.DrawImage($tile,($i*240+12),24)
  $graphics.DrawString($labels[$i],$font,[System.Drawing.Brushes]::Black,[single]($i*240+12),[single]260)
  $g.Dispose(); $path.Dispose(); $tile.Dispose()
}
$sheet.Save((Join-Path $outputDir 'launcher-preview.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$graphics.Dispose(); $font.Dispose(); $sheet.Dispose(); $logo.Dispose(); $legacy.Dispose()
Write-Output "PASS: foreground radius $([Math]::Round($maxRadius,2))dp within 33dp safe circle."
