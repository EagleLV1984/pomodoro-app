@echo off
:: 番茄钟 - 桌面应用启动器
:: 使用 Edge WebView2 以无边框窗口模式运行

set "HTML_FILE=%~dp0pomodoro.html"

:: 优先使用 Edge（Chromium 内核，支持 WebView2）
where msedge >nul 2>nul
if %errorlevel% equ 0 (
    start "" msedge --app="file:///%HTML_FILE:\=/%" --window-size=420,640 --disable-extensions --disable-sync
    goto :end
)

:: 备选：Chrome
where chrome >nul 2>nul
if %errorlevel% equ 0 (
    start "" chrome --app="file:///%HTML_FILE:\=/%" --window-size=420,640
    goto :end
)

:: 都不行就用默认浏览器打开
start "" "%HTML_FILE%"

:end
