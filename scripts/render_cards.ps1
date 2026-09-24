Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "Stop"
$repo = Resolve-Path (Join-Path $PSScriptRoot "..")
$assets = Join-Path $repo "assets"

function U([int[]]$codes) { -join ($codes | ForEach-Object { [char]$_ }) }

$jp = @{
  Public = (U 0x516C,0x958B,0x30EA,0x30DD,0x30B8,0x30C8,0x30EA)
  Private = (U 0x975E,0x516C,0x958B)
  PrivateNote = (U 0x672C,0x4EBA,0x306E,0x307F)
  Stars = (U 0x30B9,0x30BF,0x30FC)
  StarsNote = (U 0x516C,0x958B,0x30EA,0x30DD,0x30B8,0x30C8,0x30EA)
  Span = (U 0x5229,0x7528,0x671F,0x9593)
  SpanValue = ("7" + (U 0x5E74) + "4" + (U 0x30F6,0x6708))
  Since = ("2019" + (U 0x5E74) + "4" + (U 0x6708) + "30" + (U 0x65E5) + (U 0x958B,0x59CB))
  Default = (U 0x30C7,0x30D5,0x30A9,0x30EB,0x30C8)
  Silver = (U 0x30B7,0x30EB,0x30D0,0x30FC)
  Earned = (U 0x7372,0x5F97,0x6E08,0x307F)
  Count = (U 0x4EF6)
  Pr = (U 0x30D7,0x30EB,0x30EA,0x30AF,0x30A8,0x30B9,0x30C8)
  Quick = (U 0x3059,0x3070,0x3084,0x3044,0x30AF,0x30ED,0x30FC,0x30BA)
  Pair = (U 0x5171,0x540C,0x30B3,0x30DF,0x30C3,0x30C8)
  Brain = (U 0x63A1,0x7528,0x3055,0x308C,0x305F,0x56DE,0x7B54)
}

function New-Card($file, $bgHex, $borderHex, $inkHex, $mutedHex, $kicker, $value, $note) {
  $bmp = New-Object System.Drawing.Bitmap 320, 168
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
  $g.Clear([System.Drawing.Color]::Transparent)
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $path.AddArc(2, 2, 36, 36, 180, 90)
  $path.AddArc(280, 2, 36, 36, 270, 90)
  $path.AddArc(280, 128, 36, 36, 0, 90)
  $path.AddArc(2, 128, 36, 36, 90, 90)
  $path.CloseFigure()
  $fill = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml($bgHex))
  $pen = New-Object System.Drawing.Pen ([System.Drawing.ColorTranslator]::FromHtml($borderHex)), 2
  $g.FillPath($fill, $path)
  $g.DrawPath($pen, $path)
  $dot = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml($mutedHex))
  $g.FillEllipse($dot, 28, 28, 10, 10)
  $fk = New-Object System.Drawing.Font("Yu Gothic", 16, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
  $fv = New-Object System.Drawing.Font("Yu Gothic", 36, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
  $fn = New-Object System.Drawing.Font("Yu Gothic", 14, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
  $ink = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml($inkHex))
  $muted = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml($mutedHex))
  $g.DrawString($kicker, $fk, $muted, 48, 22)
  $g.DrawString($value, $fv, $ink, 26, 58)
  $g.DrawString($note, $fn, $muted, 28, 118)
  $bmp.Save((Join-Path $assets $file), [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose(); $bmp.Dispose(); $fill.Dispose(); $pen.Dispose(); $dot.Dispose(); $ink.Dispose(); $muted.Dispose()
  $fk.Dispose(); $fv.Dispose(); $fn.Dispose(); $path.Dispose()
}

$themes = @(
  @{ Name = "light"; Bg = "#F6F6F6"; Border = "#D5D5D5"; Ink = "#161616"; Muted = "#8A8A8A" },
  @{ Name = "dark"; Bg = "#161B22"; Border = "#30363D"; Ink = "#F0F3F6"; Muted = "#8B949E" }
)

foreach ($t in $themes) {
  $n = $t.Name
  New-Card "card-public-$n.png" $t.Bg $t.Border $t.Ink $t.Muted $jp.Public "30" (U 0x516C,0x958B)
  New-Card "card-private-$n.png" $t.Bg $t.Border $t.Ink $t.Muted $jp.Private ([string][char]0x2014) $jp.PrivateNote
  New-Card "card-stars-$n.png" $t.Bg $t.Border $t.Ink $t.Muted $jp.Stars "116" $jp.StarsNote
  New-Card "card-span-$n.png" $t.Bg $t.Border $t.Ink $t.Muted $jp.Span $jp.SpanValue $jp.Since
  New-Card "card-shark-$n.png" $t.Bg $t.Border $t.Ink $t.Muted "Pull Shark" $jp.Default ("16" + $jp.Count + "  /  " + $jp.Pr)
  New-Card "card-quick-$n.png" $t.Bg $t.Border $t.Ink $t.Muted "Quickdraw" $jp.Earned ("8" + $jp.Count + "  /  " + $jp.Quick)
  New-Card "card-pair-$n.png" $t.Bg $t.Border $t.Ink $t.Muted "Pair Extraordinaire" $jp.Default ("1" + $jp.Count + (U 0x301C) + "  /  " + $jp.Pair)
  New-Card "card-brain-$n.png" $t.Bg $t.Border $t.Ink $t.Muted "Galaxy Brain" $jp.Silver ("16" + $jp.Count + (U 0x301C) + "  /  " + $jp.Brain)
}
Write-Host "CARDS OK"
