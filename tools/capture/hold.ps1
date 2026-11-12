# Keeps a Studio in front for N seconds: the terminal takes the front back about a second after each bring-forward, and behind it Studio draws 15 fps.
# Start it in Edit, before the Run, and let it outlast the take: it parks the cursor as it starts, and a hold running out can turn the view.
# The cursor is parked on the game view's centre first, so activating a locked-cursor window gives the camera no turn.
# ViewX and ViewY: logical pixels from the window's top left to the game view's centre. These fit this PC's Studio (2561x1601 at 150%), measured 2026-11-12.
param([double]$Seconds = 20, [string]$Window = "Roblox Studio", [int]$ViewX = 707, [int]$ViewY = 559)
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class H {
  [StructLayout(LayoutKind.Sequential)] public struct R { public int L, T, Rr, B; }
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern void keybd_event(byte k, byte s, uint f, UIntPtr e);
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out R r);
}
"@
$h = (Get-Process | Where-Object { $_.MainWindowTitle -like "*$Window*" } | Select-Object -First 1).MainWindowHandle
$r = New-Object H+R
[void][H]::GetWindowRect($h, [ref]$r)
$cx = $r.L + $ViewX
$cy = $r.T + $ViewY
"window $($r.L),$($r.T) to $($r.Rr),$($r.B); cursor to $cx,$cy"
[void][H]::SetCursorPos($cx, $cy)
$end = (Get-Date).AddSeconds($Seconds)
$lost = 0
while ((Get-Date) -lt $end) {
  if ([H]::GetForegroundWindow() -ne $h) {
    $lost += 1
    [void][H]::SetCursorPos($cx, $cy)
    [H]::keybd_event(0x12, 0, 0, [UIntPtr]::Zero)
    [H]::keybd_event(0x12, 0, 2, [UIntPtr]::Zero)
    [void][H]::SetForegroundWindow($h)
  }
  Start-Sleep -Milliseconds 100
}
"lost the front $lost times"
