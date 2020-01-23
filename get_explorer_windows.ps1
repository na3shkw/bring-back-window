Add-Type @'
    using System;
    using System.Runtime.InteropServices;

    public class Win32
    {
        [DllImport("user32.dll")]
        public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);
    }
'@

$shellApps = New-Object -com "Shell.Application"
$shellApps = $shellApps.windows() | select-object -Property Top, Left, Width, Height, HWND

foreach ($sa in $shellApps) {
    $sa.HWND
    $null = [Win32]::MoveWindow(
        $sa.HWND, 100, 100, $sa.Width, $sa.Height, $true
    )
}