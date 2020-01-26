Add-Type @'
    using System;
    using System.Runtime.InteropServices;

    public class Win32 {
        [DllImport("dwmapi.dll")]
        public static extern int DwmGetWindowAttribute(IntPtr hWnd, int dwAttribute, out RECT lpRect, int cbAttribute);

        [DllImport("user32.dll")]
        public static extern bool SetForegroundWindow(IntPtr hWnd);

        [DllImport("user32.dll")]
        public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);
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

# ウィンドウをカーソルのあるディスプレイに移動
function moveWindowToVisibleArea(
    [IntPtr] $Hwnd,
    [System.Windows.Forms.Screen[]] $screens,
    [System.Windows.Forms.Screen[]] $destScreen,
    [int] $Left,
    [int] $Top,
    [int] $Width,
    [int] $Height
){
    [String] $fromScreen = ""
    foreach ($screen in $screens)
    {
        $bound = $screen.Bounds
        if ($bound.Left -le $Left -And $Left -le $bound.Right)
        {
            if ($bound.Top -le $Top -And $Top -le $bound.Bottom)
            {
                $fromScreen = $screen.DeviceName
                break
            }
        }
    }
    # 移動元と移動先のスクリーンが同じ場合は何もしない
    if ($destScreen.DeviceName -eq $fromScreen) {
        return $false
    }
    # ウィンドウを最前面に
    $null = [Win32]::SetForegroundWindow($hwnd)
    # ウィンドウ移動
    $null = [Win32]::MoveWindow($hwnd, $destScreen.WorkingArea.X, $destScreen.WorkingArea.Y, $Width, $Height, $true)
    return $true
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

# カーソル位置と移動先の取得
[System.Windows.Forms.Screen[]] $destScreen
$screens = [System.Windows.Forms.Screen]::AllScreens
$cursor = [System.Windows.Forms.Cursor]::Position
# カーソルの位置を取得し、移動後のウィンドウサイズを決定
foreach ($screen in $screens)
{
    $bound = $screen.Bounds
    $left = $bound.Left
    $top = $bound.Top
    $right = $bound.Right
    $bottom = $bound.Bottom
    if ($left -lt $cursor.X -And $cursor.X -lt $right)
    {
        if ($top -lt $cursor.Y -And $cursor.Y -lt $bottom)
        {
            $destScreen = $screen
            break
        }
    }
}
$window = New-Object RECT
$stringbuilder = New-Object System.Text.StringBuilder 256
# カーソルのないスクリーンにあるウィンドウをすべて移動
foreach ($hwnd in $handles) {
    $null = [Win32]::DwmGetWindowAttribute(
        $hwnd,
        [DWMWATTR]::DWMWA_EXTENDED_FRAME_BOUNDS,
        [ref]$window,
        [System.Runtime.InteropServices.Marshal]::SizeOf($window)
    )
    $width = $window.Right - $window.Left
    $height = $window.Bottom - $window.Top
    $null = moveWindowToVisibleArea $hwnd $screens $destScreen $window.Left $window.Top $width $height
}
# エクスプローラウィンドウの移動
foreach ($app in $shellApps) {
    $null = moveWindowToVisibleArea $app.HWND $screens $destScreen $app.Left $app.Top $app.Width $app.Height
}
