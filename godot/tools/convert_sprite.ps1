Add-Type -AssemblyName System.Drawing
function Convert-UnitSprite([string]$src, [string]$dst, [int]$threshold = 22, [int]$size = 256) {
  $bmp = New-Object System.Drawing.Bitmap $src
  $out = New-Object System.Drawing.Bitmap $bmp.Width, $bmp.Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  for ($y = 0; $y -lt $bmp.Height; $y++) {
    for ($x = 0; $x -lt $bmp.Width; $x++) {
      $c = $bmp.GetPixel($x, $y)
      $lum = [int]((0.299*$c.R)+(0.587*$c.G)+(0.114*$c.B))
      if ($lum -le $threshold) {
        $out.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0,0,0,0))
      } else {
        $a = 255
        if ($lum -lt ($threshold + 20)) { $a = [Math]::Max(0,[Math]::Min(255,[int](255.0*($lum-$threshold)/20.0))) }
        $out.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($a, $c.R, $c.G, $c.B))
      }
    }
  }
  $minX=$out.Width;$minY=$out.Height;$maxX=0;$maxY=0
  for ($y=0;$y -lt $out.Height;$y++){ for($x=0;$x -lt $out.Width;$x++){ if($out.GetPixel($x,$y).A -gt 10){ if($x -lt $minX){$minX=$x}; if($y -lt $minY){$minY=$y}; if($x -gt $maxX){$maxX=$x}; if($y -gt $maxY){$maxY=$y} } } }
  if ($maxX -lt $minX) { throw "empty sprite $src" }
  $pad=18; $minX=[Math]::Max(0,$minX-$pad); $minY=[Math]::Max(0,$minY-$pad); $maxX=[Math]::Min($out.Width-1,$maxX+$pad); $maxY=[Math]::Min($out.Height-1,$maxY+$pad)
  $w=$maxX-$minX+1; $h=$maxY-$minY+1; $side=[Math]::Max($w,$h)
  $square = New-Object System.Drawing.Bitmap $side,$side,([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g=[System.Drawing.Graphics]::FromImage($square); $g.Clear([System.Drawing.Color]::Transparent)
  $g.DrawImage($out,[int](($side-$w)/2),[int](($side-$h)/2),(New-Object System.Drawing.Rectangle $minX,$minY,$w,$h),[System.Drawing.GraphicsUnit]::Pixel); $g.Dispose()
  $final = New-Object System.Drawing.Bitmap $size,$size,([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g2=[System.Drawing.Graphics]::FromImage($final); $g2.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g2.Clear([System.Drawing.Color]::Transparent); $g2.DrawImage($square,0,0,$size,$size); $g2.Dispose()
  $final.Save($dst,[System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose(); $out.Dispose(); $square.Dispose(); $final.Dispose()
  Write-Output "OK $dst"
}
