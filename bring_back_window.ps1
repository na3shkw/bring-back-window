Add-Type @'
    using System;
    using System.Runtime.InteropServices;
    public class Win32 {
        [DllImport("user32.dll")]
        public static extern IntPtr GetForegroundWindow();
        
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
if ($null -eq $handles -Or $handles.Length -lt 2)
{
    return
}
# Zオーダーで2番目にあるウィンドウのハンドラ取得
$handle = EnumWindows | Where-Object { $handles.Contains($_) } | Select-Object -First 2
$hwnd = $handle[1]
# カーソルの位置を取得し、移動後のウィンドウサイズを決定
$cursor = [System.Windows.Forms.Cursor]::Position
foreach ($screen in [System.Windows.Forms.Screen]::AllScreens)
{
    $wa = $screen.WorkingArea
    $left = $wa.X
    $top = $wa.Y
    $right = $left + $wa.Width
    $bottom = $top + $wa.Height
    if ($left -lt $cursor.X -And $cursor.X -lt $right)
    {
        if ($top -lt $cursor.Y -And $cursor.Y -lt $bottom)
        {
            $width = $right - $cursor.X
            $height = $bottom - $cursor.Y
            break
        }
    }
}
# ウィンドウを最前面に
$null = [Win32]::SetForegroundWindow($hwnd)
# ウィンドウ移動
$null = [Win32]::MoveWindow($hwnd, $cursor.X, $cursor.Y, $width, $height, $true)
