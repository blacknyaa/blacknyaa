Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "Stop"
$repo = Resolve-Path (Join-Path $PSScriptRoot "..")
$assets = Join-Path $repo "assets"
$raw = [System.IO.File]::ReadAllText((Join-Path $PSScriptRoot "expertise.json"), [System.Text.Encoding]::UTF8)
$items = $raw | ConvertFrom-Json

function New-WideCard($file, $bgHex, $borderHex, $inkHex, $mutedHex, $title, $note) {
  $bmp = New-Object System.Drawing.Bitmap 520, 132
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
  $g.Clear([System.Drawing.Color]::Transparent)
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $path.AddArc(2, 2, 32, 32, 180, 90)
  $path.AddArc(484, 2, 32, 32, 270, 90)
  $path.AddArc(484, 96, 32, 32, 0, 90)
  $path.AddArc(2, 96, 32, 32, 90, 90)
  $path.CloseFigure()
  $fill = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml($bgHex))
  $pen = New-Object System.Drawing.Pen ([System.Drawing.ColorTranslator]::FromHtml($borderHex)), 2
  $g.FillPath($fill, $path)
  $g.DrawPath($pen, $path)
  $dot = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml($mutedHex))
  $g.FillEllipse($dot, 28, 36, 10, 10)
  $ft = New-Object System.Drawing.Font("Yu Gothic", 26, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
  $fn = New-Object System.Drawing.Font("Yu Gothic", 16, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
  $ink = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml($inkHex))
  $muted = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml($mutedHex))
  $g.DrawString($title, $ft, $ink, 52, 28)
  $g.DrawString($note, $fn, $muted, 52, 72)
  $bmp.Save((Join-Path $assets $file), [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose(); $bmp.Dispose(); $fill.Dispose(); $pen.Dispose(); $dot.Dispose(); $ink.Dispose(); $muted.Dispose()
  $ft.Dispose(); $fn.Dispose(); $path.Dispose()
}

$themes = @(
  @{ Name = "light"; Bg = "#F6F6F6"; Border = "#D5D5D5"; Ink = "#161616"; Muted = "#6E6E6E" },
  @{ Name = "dark"; Bg = "#161B22"; Border = "#30363D"; Ink = "#F0F3F6"; Muted = "#8B949E" }
)
foreach ($t in $themes) {
  foreach ($item in $items) {
    $file = "card-{0}-{1}.png" -f $item.id, $t.Name
    New-WideCard $file $t.Bg $t.Border $t.Ink $t.Muted $item.title $item.note
  }
}
Write-Host "EXPERTISE OK"
