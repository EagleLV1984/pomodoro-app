$desktop = [Environment]::GetFolderPath("Desktop")
$shortcutPath = Join-Path $desktop "Pomodoro.lnk"

$WshShell = New-Object -ComObject WScript.Shell
$shortcut = $WshShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "D:\FIRST-CC\publish\Pomodoro.exe"
$shortcut.WorkingDirectory = "D:\FIRST-CC\publish"
$shortcut.Description = "Pomodoro Timer"
$shortcut.Save()

Write-Host "Shortcut created: $shortcutPath"
