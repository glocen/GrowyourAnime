<#
Records a Studio window in real time for a fast moment's evidence: every picture
Windows composes, at the time it was composed, effects included, which a pose-by-pose replay can't draw.

It reads the window itself (Windows.Graphics.Capture, ffmpeg's gfxcapture), so what covers the window doesn't matter, and
it saves on the GPU's video block, which the game's rendering doesn't use. Free: Windows, an ffmpeg built with gfxcapture and an NVIDIA GPU, nothing else.

Run: powershell -NoProfile -File tools/capture/grab.ps1 build/captures/<piece>/<take>.mkv [-Seconds 8] [-Window <title>]
     [-Lossless] [-Rate 60]
Start it, then press. -Window is a regular expression on the window's title.

-Lossless is for a colour or a value that has to be measured: red, green and blue each keep a plane of their own, and on a
window of known colours no channel differed from a PNG of it. The default is 4:4:4 too, so a thin line keeps
its hue, but its numbers drift: about 3 levels in a thin line, up to 19 at a hard edge. -Rate takes fewer pictures a
second, for a series of still views.

Studio draws 60 fps only with its window in front, so the report at the end is
the take's real rate: a take meant for 60 that shows under about 58 is taken again. Then tools/capture/frames.ps1 puts
the moment on the 1/60 s grid.
#>
param(
    [Parameter(Mandatory = $true, Position = 0)][string]$Out,
    [double]$Seconds = 8,
    [string]$Window = "Roblox Studio",  # your place's window title
    [switch]$Lossless,
    [int]$Rate = 60
)

$ErrorActionPreference = "Stop"
$ffmpeg = if ($env:NL_FFMPEG) { $env:NL_FFMPEG } else { "ffmpeg" }
$ffprobe = if ($env:NL_FFMPEG) { Join-Path (Split-Path $env:NL_FFMPEG) "ffprobe" } else { "ffprobe" }

$folder = Split-Path $Out
if ($folder -and -not (Test-Path $folder)) { New-Item -ItemType Directory -Force $folder | Out-Null }

$source = "gfxcapture=window_title='$Window':max_framerate=${Rate}:capture_cursor=0,hwdownload,format=bgra"
$quality = if ($Lossless) { "-tune", "lossless", "-pix_fmt", "gbrp" } else { "-tune", "ull", "-rc", "constqp", "-qp", "18", "-pix_fmt", "yuv444p" }
& $ffmpeg -hide_banner -nostdin -loglevel error -y -f lavfi -i $source -t $Seconds -fps_mode passthrough `
    -c:v h264_nvenc -preset p1 @quality $Out
if ($LASTEXITCODE -ne 0) { throw "NL_GRAB: ffmpeg stopped with $LASTEXITCODE (is a window titled '$Window' open?)" }

# The report reads the file, not the wish: each packet's time is when Windows composed that picture.
$times = & $ffprobe -v error -select_streams v:0 -show_entries packet=pts_time -of csv=p=0 $Out |
    ForEach-Object { [double]($_.Trim().TrimEnd(",")) } | Sort-Object
if ($times.Count -lt 2) { throw "NL_GRAB: $Out holds $($times.Count) picture(s): the window drew nothing" }

$steps = for ($i = 1; $i -lt $times.Count; $i++) { [pscustomobject]@{ At = $times[$i - 1]; Ms = 1000 * ($times[$i] - $times[$i - 1]) } }
$span = $times[-1] - $times[0]
$sorted = $steps | Sort-Object Ms
$long = @($steps | Where-Object { $_.Ms -gt 25 })
$worst = $sorted[-1]
"NL_GRAB $Out"
"  {0} pictures in {1:N2} s: {2:N1} fps, the median step {3:N1} ms" -f $times.Count, $span, (($times.Count - 1) / $span), $sorted[[int]($sorted.Count / 2)].Ms
"  {0} steps over 25 ms, the longest {1:N1} ms at {2:N3} s" -f $long.Count, $worst.Ms, $worst.At
