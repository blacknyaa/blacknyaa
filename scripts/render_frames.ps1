Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "Stop"

Add-Type -ReferencedAssemblies System.Drawing @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class SoftBlob {
  public static Bitmap Make(int w, int h, int r, int g, int b, int maxA) {
    var bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb);
    var rect = new Rectangle(0, 0, w, h);
    var data = bmp.LockBits(rect, ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
    int n = Math.Abs(data.Stride) * h;
    byte[] buf = new byte[n];
    float cx = (w - 1) / 2f, cy = (h - 1) / 2f;
    float rx = w / 2f, ry = h / 2f;
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        float nx = (x - cx) / rx;
        float ny = (y - cy) / ry;
        float d = nx * nx + ny * ny;
        int a = 0;
        if (d < 1f) {
          float t = 1f - d;
          a = (int)(maxA * t * t);
          if (a > 255) a = 255;
        }
        int i = y * data.Stride + x * 4;
        buf[i] = (byte)b; buf[i+1] = (byte)g; buf[i+2] = (byte)r; buf[i+3] = (byte)a;
      }
    }
    Marshal.Copy(buf, 0, data.Scan0, n);
    bmp.UnlockBits(data);
    return bmp;
  }
}
"@

function New-Canvas($w, $h, $hex) {
  $bmp = New-Object System.Drawing.Bitmap $w, $h
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
  $g.Clear(([System.Drawing.ColorTranslator]::FromHtml($hex)))
  return @{ Bmp = $bmp; G = $g }
}

function Draw-ArcDots($g, $pts, $radius, $color) {
  $brush = New-Object System.Drawing.SolidBrush $color
  foreach ($p in $pts) {
    $g.FillEllipse($brush, $p.X - $radius, $p.Y - $radius, $radius * 2, $radius * 2)
  }
  $brush.Dispose()
}

function Bezier($p0, $p1, $p2, $n) {
  $list = @()
  for ($i = 0; $i -le $n; $i++) {
    $t = $i / $n
    $u = 1 - $t
    $x = $u*$u*$p0[0] + 2*$u*$t*$p1[0] + $t*$t*$p2[0]
    $y = $u*$u*$p0[1] + 2*$u*$t*$p1[1] + $t*$t*$p2[1]
    $list += [System.Drawing.PointF]::new([single]$x, [single]$y)
  }
  return $list
}

$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
if (-not (Test-Path (Join-Path $PSScriptRoot "..\assets"))) {
  $repo = Resolve-Path (Join-Path $PSScriptRoot "..")
} else {
  $repo = Resolve-Path (Join-Path $PSScriptRoot "..")
}
$assets = Join-Path $repo "assets"
$tmp = Join-Path $repo "scripts\_frames"
New-Item -ItemType Directory -Force -Path $assets, $tmp | Out-Null

$W = 1200; $H = 420; $frames = 16
$font = $null
foreach ($name in @("Yu Gothic", "Yu Gothic UI", "Meiryo")) {
  try {
    $font = New-Object System.Drawing.Font($name, 40, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    if ($font.Name -eq $name -or $font.FontFamily.Name -match "Yu|Meiryo") { break }
  } catch {}
}
Write-Host "FONT $($font.Name)"

$themes = @(
  @{ Name = "light"; Bg = "#FFFFFF"; Blob = @(210,210,210); BlobA = 230; Line = "#CFCFCF"; Dot = "#B5B5B5"; Text = "#161616"; Accent = "#9A9A9A" },
  @{ Name = "dark";  Bg = "#0D1117"; Blob = @(48,54,61);   BlobA = 255; Line = "#30363D"; Dot = "#6E7681"; Text = "#F0F3F6"; Accent = "#8B949E" }
)

$blobL = [SoftBlob]::Make(520, 380, 210, 210, 210, 210)
$blobM = [SoftBlob]::Make(340, 260, 200, 200, 200, 180)
$blobS = [SoftBlob]::Make(220, 180, 190, 190, 190, 160)

foreach ($theme in $themes) {
  $ink = [System.Drawing.ColorTranslator]::FromHtml($theme.Text)
  $line = [System.Drawing.ColorTranslator]::FromHtml($theme.Line)
  $dot = [System.Drawing.ColorTranslator]::FromHtml($theme.Dot)
  $accent = [System.Drawing.ColorTranslator]::FromHtml($theme.Accent)
  $br = $theme.Blob
  if ($theme.Name -eq "dark") {
    $b1 = [SoftBlob]::Make(520, 380, 42, 48, 56, 255)
    $b2 = [SoftBlob]::Make(360, 280, 55, 62, 72, 255)
    $b3 = [SoftBlob]::Make(240, 190, 36, 42, 50, 255)
  } else {
    $b1 = $blobL; $b2 = $blobM; $b3 = $blobS
  }
  $curve = Bezier @(40, 250) @(280, 40) @(560, 160) 28
  $dots = Bezier @(760, 70) @(980, 30) @(1180, 150) 16
  for ($f = 0; $f -lt $frames; $f++) {
    $phase = [Math]::Sin(2 * [Math]::PI * $f / $frames)
    $phase2 = [Math]::Cos(2 * [Math]::PI * $f / $frames)
    $c = New-Canvas $W $H $theme.Bg
    $g = $c.G
    $g.DrawImage($b1, -120 + [int](18*$phase), 160 + [int](10*$phase2))
    $g.DrawImage($b2, 900 + [int](16*$phase2), -80 + [int](12*$phase))
    $g.DrawImage($b3, 980 + [int](10*$phase), 280 + [int](14*$phase2))
    $pen = New-Object System.Drawing.Pen $line, 2
    $g.DrawCurve($pen, $curve)
    $pen.Dispose()
    Draw-ArcDots $g $dots 3.2 $dot
    $ti = [int](([Math]::Sin([Math]::PI * $f / ($frames - 1))) * ($dots.Count - 1))
    if ($ti -lt 0) { $ti = 0 }
    $tp = $dots[$ti]
    $hb = New-Object System.Drawing.SolidBrush $accent
    $g.FillEllipse($hb, $tp.X - 7, $tp.Y - 7, 14, 14)
    $hb.Dispose()
    $circles = @(
      @{ X = 90; Y = 70; R = 18 },
      @{ X = 150; Y = 120; R = 7 },
      @{ X = 70; Y = 180; R = 5 },
      @{ X = 1080; Y = 200; R = 22 },
      @{ X = 1140; Y = 250; R = 8 },
      @{ X = 620; Y = 360; R = 6 }
    )
    $i = 0
    foreach ($cir in $circles) {
      $bob = [Math]::Sin(2 * [Math]::PI * $f / $frames + $i)
      $rr = $cir.R + 1.5 * $bob
      $pb = New-Object System.Drawing.Pen $accent, 1.6
      $g.DrawEllipse($pb, $cir.X - $rr + [int](6*$bob), $cir.Y - $rr, $rr*2, $rr*2)
      $pb.Dispose()
      $i++
    }
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = [System.Drawing.StringAlignment]::Center
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
    $brush = New-Object System.Drawing.SolidBrush $ink
    $rect1 = New-Object System.Drawing.RectangleF 80, 145, 1040, 64
    $rect2 = New-Object System.Drawing.RectangleF 80, 210, 1040, 64
    $line1 = "Web" + [char]0x30FB + [char]0x30B5 + [char]0x30A4 + [char]0x30C8 + [char]0x30FB + [char]0x30A2 + [char]0x30D7 + [char]0x30EA + " 170" + [char]0x4EF6 + [char]0x4EE5 + [char]0x4E0A
    $line2 = [char]0x30B7 + [char]0x30B9 + [char]0x30C6 + [char]0x30E0 + " 80" + [char]0x4EF6 + [char]0x4EE5 + [char]0x4E0A
    $g.DrawString($line1, $font, $brush, $rect1, $sf)
    $g.DrawString($line2, $font, $brush, $rect2, $sf)
    $brush.Dispose(); $sf.Dispose()
    $path = Join-Path $tmp ("hero-{0}-{1:d2}.bmp" -f $theme.Name, $f)
    $c.Bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Bmp)
    $g.Dispose(); $c.Bmp.Dispose()
  }
  # divider
  for ($f = 0; $f -lt $frames; $f++) {
    $c = New-Canvas $W 72 $theme.Bg
    $g = $c.G
    $pen = New-Object System.Drawing.Pen $line, 1.5
    $wave = @()
    for ($x = 0; $x -le $W; $x += 12) {
      $y = 36 + [Math]::Sin(($x / 90.0) + (2 * [Math]::PI * $f / $frames)) * 8
      $wave += [System.Drawing.PointF]::new([single]$x, [single]$y)
    }
    $g.DrawCurve($pen, $wave)
    $pen.Dispose()
    $db = New-Object System.Drawing.SolidBrush $dot
    for ($k = 0; $k -lt 9; $k++) {
      $shift = ($f * 18 + $k * 130) % ($W + 40) - 20
      $y = 36 + [Math]::Sin(($shift / 90.0) + (2 * [Math]::PI * $f / $frames)) * 8
      $rad = 3 + ($k % 3)
      $g.FillEllipse($db, $shift, $y - $rad, $rad * 2, $rad * 2)
    }
    $db.Dispose()
    $path = Join-Path $tmp ("div-{0}-{1:d2}.bmp" -f $theme.Name, $f)
    $c.Bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Bmp)
    $g.Dispose(); $c.Bmp.Dispose()
  }
  $b1.Dispose(); $b2.Dispose(); $b3.Dispose()
}

# link buttons
$labels = @(
  @{ Id = "portfolio"; Text = ([char]0x30DD + [char]0x30FC + [char]0x30C8 + [char]0x30D5 + [char]0x30A9 + [char]0x30EA + [char]0x30AA) },
  @{ Id = "lancers"; Text = "Lancers" },
  @{ Id = "note"; Text = "note" },
  @{ Id = "qiita"; Text = "Qiita" },
  @{ Id = "zenn"; Text = "Zenn" },
  @{ Id = "youtrust"; Text = "YOUTRUST" }
)
$btnFont = New-Object System.Drawing.Font($font.FontFamily, 18, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
foreach ($theme in $themes) {
  $bg = [System.Drawing.ColorTranslator]::FromHtml($(if ($theme.Name -eq "light") { "#F4F4F4" } else { "#161B22" }))
  $border = [System.Drawing.ColorTranslator]::FromHtml($(if ($theme.Name -eq "light") { "#D0D0D0" } else { "#30363D" }))
  $ink = [System.Drawing.ColorTranslator]::FromHtml($theme.Text)
  foreach ($lab in $labels) {
    $bmp = New-Object System.Drawing.Bitmap 240, 64
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $g.Clear([System.Drawing.Color]::Transparent)
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddArc(1, 1, 40, 40, 180, 90)
    $path.AddArc(198, 1, 40, 40, 270, 90)
    $path.AddArc(198, 22, 40, 40, 0, 90)
    $path.AddArc(1, 22, 40, 40, 90, 90)
    $path.CloseFigure()
    $fill = New-Object System.Drawing.SolidBrush $bg
    $pen = New-Object System.Drawing.Pen $border, 2
    $g.FillPath($fill, $path)
    $g.DrawPath($pen, $path)
    $ab = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml($theme.Accent))
    $g.FillEllipse($ab, 22, 26, 12, 12)
    $tb = New-Object System.Drawing.SolidBrush $ink
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = [System.Drawing.StringAlignment]::Center
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
    $g.DrawString($lab.Text, $btnFont, $tb, (New-Object System.Drawing.RectangleF 40, 0, 180, 64), $sf)
    $out = Join-Path $assets ("btn-{0}-{1}.png" -f $lab.Id, $theme.Name)
    $bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose(); $fill.Dispose(); $pen.Dispose(); $ab.Dispose(); $tb.Dispose(); $sf.Dispose(); $path.Dispose()
  }
}
Write-Host "FRAMES OK"
