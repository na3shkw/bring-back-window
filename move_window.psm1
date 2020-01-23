Add-Type @'
    using System;
    using System.Runtime.InteropServices;

    public class __Win32 {
        [DllImport("user32.dll")]
        public static extern bool SetForegroundWindow(IntPtr hWnd);

        [DllImport("user32.dll")]
        public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);
    }
'@
Add-Type -AssemblyName System.Windows.Forms

function __MoveAndSetForeground(
    [IntPtr] $hwnd,
    [int] $x,
    [int] $y,
    [int] $width,
    [int] $height
){
    Write-Host($hwnd)
    Write-Host($x, $y)
    # # ウィンドウを最前面に
    # $null = [__Win32]::SetForegroundWindow($hwnd)
    # # ウィンドウ移動
    # $null = [__Win32]::MoveWindow($hwnd, $x, $y, $width, $height, $true)
}

class MoveWindow
{
    [System.Windows.Forms.Screen[]] $screens
    [String] $destScreen
    [hashtable] $dest = @{
        X = 0;
        Y = 0;
    }

    MoveWindow()
    {
        $this.screens = [System.Windows.Forms.Screen]::AllScreens
        $cursor = [System.Windows.Forms.Cursor]::Position
        # カーソルの位置を取得し、移動後のウィンドウサイズを決定
        foreach ($screen in $this.screens)
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
                    $this.destScreen = $screen.DeviceName
                    $this.dest.X = $cursor.X
                    $this.dest.Y = $cursor.Y
                    break
                }
            }
        }
    }

    [bool] ToVisibleArea(
        [IntPtr] $Hwnd,
        [int] $Left,
        [int] $Top,
        [int] $Width,
        [int] $Height
    ){
        [String] $fromScreen = ""
        foreach ($screen in $this.screens)
        {
            $bound = $screen.Bounds
            if ($bound.Left -le $Left -And $Left -le $bound.Right)
            {
                if ($bound.Top -le $Top -And $Top -le $bound.Bottom)
                {
                    $fromScreen = $screen.DeviceName
                    Write-Host(
                        $bound.Left, $Left, $bound.Right,
                        $bound.Top, $Top, $bound.Bottom,
                        $fromScreen
                    )
                    break
                }
            }
        }
        # 移動元と移動先のスクリーンが同じなら何もしない
        if ($this.destScreen -eq $fromScreen) {
            continue
        }
        # ウィンドウ移動&最前面に
        Write-Host($Hwnd.GetType().FullName)
        Write-Host($Hwnd)
        $null = __MoveAndSetForeground(
            [IntPtr]$Hwnd,
            [int]$this.dest.X,
            [int]$this.dest.Y,
            [int]$Width,
            [int]$Height
        )
        return $true
    }
}