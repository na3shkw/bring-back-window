Add-Type @'
    using System;
    using System.Text;
    using System.Runtime.InteropServices;

    public class Win32
    {
        [DllImport("user32.dll", SetLastError = true)]
        public static extern IntPtr GetDesktopWindow();

        [DllImport("user32.dll", SetLastError = true)]
        public static extern IntPtr GetWindow(IntPtr hWnd, GetWindowType uCmd);

        [DllImport("user32.dll")]
        public static extern IntPtr GetWindowText(IntPtr hWnd, System.Text.StringBuilder text, int count);
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

function EnumWindows
{
    $window = [Win32]::GetWindow([Win32]::GetDesktopWindow(), [GetWindowType]::GW_CHILD)
    while ($window -ne [IntPtr]::Zero)
    {
        $window
        $window = [Win32]::GetWindow($window, [GetWindowType]::GW_HWNDNEXT)
    }
}
$stringbuilder = New-Object System.Text.StringBuilder 256

$processes = Get-Process | Where-Object { $_.MainWindowHandle -ne 0 } | Foreach-Object {
    @{
        "Handle" = $_.MainWindowHandle
        "ProcessName" = $_.ProcessName
    }
}
$processes | Foreach-Object { Write-Host([String]$_.Handle + ": " + $_.ProcessName) }
if ($null -eq $processes -Or $processes.Length -lt 2)
{
    return
}
Write-Host("---")
$windows = EnumWindows
$hit = @()
foreach ($proc in $processes) {
    $hwnd = $proc.Handle
    $count = [Win32]::GetWindowText($hwnd, $stringbuilder, 256)
    if ($windows.Contains($hwnd)) {
        $index = [Array]::IndexOf($windows, $hwnd)
        $hit += $index
        if ([int]$count -eq 0) {
            $name = $proc.ProcessName
        } else {
            $name = $stringbuilder.ToString()
        }
        Write-Host($index, $hwnd, $name)
    }
}
Write-Host("---")
$i = 0
foreach ($hwnd in $windows) {
    $count = [Win32]::GetWindowText($hwnd, $stringbuilder, 256)
    if ($hit.Contains($i)) {
        $flag = "#"
    } else {
        $flag = " "
    }
    Write-Host($flag, $hwnd, $stringbuilder.ToString())
    $i++
}