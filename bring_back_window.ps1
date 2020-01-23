using module ./move_window.psd1
Add-Type @'
    using System;
    using System.Text;
    using System.Runtime.InteropServices;

    public class Win32 {
        [DllImport("dwmapi.dll")]
        public static extern int DwmGetWindowAttribute(IntPtr hWnd, int dwAttribute, out RECT lpRect, int cbAttribute);

        [DllImport("user32.dll")]
        public static extern IntPtr GetWindowText(IntPtr hWnd, System.Text.StringBuilder text, int count);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern IntPtr GetDesktopWindow();

        [DllImport("user32.dll", SetLastError = true)]
        public static extern IntPtr GetWindow(IntPtr hWnd, GetWindowType uCmd);

        [DllImport("user32.dll")]
        public static extern bool SetForegroundWindow(IntPtr hWnd);

        [DllImport("user32.dll")]
        public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);
    }

    public enum GetWindowType : uint
    {
        GW_HWNDFIRST = 0,
        GW_HWNDLAST = 1,
        GW_HWNDNEXT = 2,
        GW_HWNDPREV = 3,
        GW_OWNER = 4,
        GW_CHILD = 5,
        GW_ENABLEDPOPUP = 6
    }

    public struct RECT
    {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }

    public enum DWMWATTR : uint
    {
        DWMWA_EXTENDED_FRAME_BOUNDS = 9
    }
'@
Add-Type -AssemblyName System.Windows.Forms

# トップレベルウィンドウのハンドルをZオーダー順に列挙
function EnumWindows
{
    $window = [Win32]::GetWindow([Win32]::GetDesktopWindow(), [GetWindowType]::GW_CHILD)
    while ($window -ne [IntPtr]::Zero)
    {
        $window
        $window = [Win32]::GetWindow($window, [GetWindowType]::GW_HWNDNEXT)
    }
}
# ウィンドウタイトルが空でないプロセスハンドラを取得
$handles = Get-Process | Where-Object { $_.MainWindowTitle -ne "" } | Foreach-Object { $_.MainWindowHandle }
if ($null -eq $handles)
{
    return
}
# Explorerウィンドウの取得
$shellApps = New-Object -com "Shell.Application"
$shellApps = $shellApps.windows() | select-object -Property Top, Left, Width, Height, HWND
# Zオーダーで2番目にあるウィンドウのハンドラ取得
# $handle = EnumWindows | Where-Object { $handles.Contains($_) } | Select-Object -First 2
# $hwnd = $handle[1]
$window = New-Object RECT
$moveWindow = New-Object -TypeName "MoveWindow"
$stringbuilder = New-Object System.Text.StringBuilder 256
# カーソルのないスクリーンにあるウィンドウをすべて移動
foreach ($hwnd in $handles) {
    # $null = [Win32]::GetWindowRect($hwnd, [ref]$window)
    $null = [Win32]::DwmGetWindowAttribute(
        $hwnd,
        [DWMWATTR]::DWMWA_EXTENDED_FRAME_BOUNDS,
        [ref]$window,
        [System.Runtime.InteropServices.Marshal]::SizeOf($window)
    )
    $count = [Win32]::GetWindowText($hwnd, $stringbuilder, 256)
    if ([int]$count -gt 0 ) {
        $name = $stringbuilder.ToString()
    } else {
        $name = Get-Process | Where-Object { $_.MainWindowHandle -eq $hwnd }
        $name = $name.ProcessName
    }
    Write-Host([String]$name + ": (" + [String]$window.Left + ", " + [String]$window.Top + ")")
    Write-Host($hwnd)
    $null = $moveWindow.ToVisibleArea(
        $hwnd,
        $window.Left,
        $window.Top,
        $window.Right - $window.Left,
        $window.Bottom - $window.Top
    )
}
