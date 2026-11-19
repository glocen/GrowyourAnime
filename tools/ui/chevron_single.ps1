# One chevron, white on alpha, for the game to tint: Normal's own mark (TR50, research's must-fix 3), beside Hard's two
# (LevelChevrons, AR29's B). Drawn in LevelChevrons' own stroke, fitted to it pixel by pixel (14 wide, round caps and
# join, its arms from (24.5, 56.5) to the apex at (63.5, 26) on a 128 canvas, 218 of 128 x 128 pixels off), and stood
# halfway between its two chevrons so it sits where they do.
#   powershell -NoProfile -File tools/ui/chevron_single.ps1 [-Out build/upload/ui/kit/ChevronSingle.png]
param([string]$Out = "build/upload/ui/kit/ChevronSingle.png")

Add-Type -AssemblyName System.Drawing
$side = 128
$width = 14
$end = New-Object System.Drawing.PointF 24.5, 56.5
$apexY = 26
$down = 17.5 # half the 35 between LevelChevrons' two

$image = New-Object System.Drawing.Bitmap $side, $side
$g = [System.Drawing.Graphics]::FromImage($image)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::Transparent)
$pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::White), $width
$pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
$pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
$pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
$points = [System.Drawing.PointF[]]@(
	(New-Object System.Drawing.PointF $end.X, ($end.Y + $down)),
	(New-Object System.Drawing.PointF (($side - 1) / 2), ($apexY + $down)),
	(New-Object System.Drawing.PointF (($side - 1) - $end.X), ($end.Y + $down))
)
$g.DrawLines($pen, $points)
$pen.Dispose()
$g.Dispose()
$path = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $Out))
New-Item -ItemType Directory -Force (Split-Path $path) | Out-Null
$image.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
$image.Dispose()
"wrote $Out"
