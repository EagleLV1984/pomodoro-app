# 番茄钟 Windows 安装包生成器
# 零依赖 — Windows 自带 IExpress 工具，运行此脚本即可生成 Setup.exe
# 使用方法: 先 dotnet publish，再运行此脚本

$ErrorActionPreference = "Stop"
$PublishDir = "..\publish"
$OutputDir = "..\publish\installer"
$AppName = "Pomodoro"
$AppTitle = "番茄钟"

# 确保发布目录存在
if (-not (Test-Path "$PublishDir\$AppName.exe")) {
    Write-Host "错误: 找不到 $PublishDir\$AppName.exe" -ForegroundColor Red
    Write-Host "请先运行: dotnet publish PomodoroApp.csproj -c Release -o ../publish" -ForegroundColor Yellow
    exit 1
}

# 准备安装文件
$null = New-Item -ItemType Directory -Force -Path $OutputDir

# === 方法 1: IExpress 自解压安装包 ===
Write-Host "=== 使用 Windows IExpress 生成安装包 ===" -ForegroundColor Green

$SEDFile = "$OutputDir\install.sed"
$TargetDir = "%USERPROFILE%\AppData\Local\Programs\$AppTitle"

@"
[Version]
Class=IEXPRESS
SEDVersion=3
[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=1
HideExtractAnimation=0
UseLongFileName=1
InsideCompressed=0
CAB_FixedSize=0
CAB_ResvCodeSigning=0
RebootMode=N
InstallPrompt="安装 $AppTitle`n`n将安装到: $TargetDir`n"
DisplayLicense=
FinishMessage="$AppTitle 已安装完成！`n可从开始菜单启动。"
TargetName=$OutputDir\${AppTitle}Setup.exe
FriendlyName=$AppTitle
AppLaunched=cmd /c "$TargetDir\$AppName.exe"
PostInstallCmd=cmd /c "powershell -Command `"`$ws=New-Object -ComObject WScript.Shell; `$sc=`$ws.CreateShortcut([Environment]::GetFolderPath('StartMenu')+'\Programs\$AppTitle.lnk'); `$sc.TargetPath='$TargetDir\$AppName.exe'; `$sc.Save()`""
AdminQuietInstCmd=
UserQuietInstCmd=
SourceFiles=$PublishDir\*
[SourceFiles]
SourceFiles0=$PublishDir\
[SourceFiles0]
%FILE0%=
"@ > $SEDFile

# 替换 SourceFiles 列表
$files = Get-ChildItem -Path $PublishDir -File | Where-Object { $_.Extension -ne ".pdb" }
$sedContent = Get-Content $SEDFile -Raw
$fileList = ""
$idx = 0
foreach ($f in $files) {
    $fileList += "$($f.Name)=`r`n"
}
$sedContent = $sedContent -replace '%FILE0%=', $fileList

# 写入最终 SED 文件（UTF-8 BOM）
[System.IO.File]::WriteAllText($SEDFile, $sedContent, [System.Text.Encoding]::ASCII)

Write-Host "SED 配置已生成: $SEDFile" -ForegroundColor Gray
Write-Host ""
Write-Host "==============================" -ForegroundColor Cyan
Write-Host " 接下来请手动操作:" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. 按 Win+R，输入 iexpress，回车" -ForegroundColor White
Write-Host "2. 选择: Create new Self Extraction Directive file" -ForegroundColor White
Write-Host "3. 选择: Extract files and run an installation command" -ForegroundColor White
Write-Host "4. 包名: 番茄钟" -ForegroundColor White
Write-Host "5. 不要确认提示 (No prompt)" -ForegroundColor White
Write-Host "6. 不要许可协议 (Do not display a license)" -ForegroundColor White
Write-Host "7. 添加打包文件: 浏览到 $PublishDir" -ForegroundColor White
Write-Host "8. 安装程序: $TargetDir\$AppName.exe" -ForegroundColor White
Write-Host "9. 安装后执行: 留空或创建快捷方式命令" -ForegroundColor White
Write-Host ""
Write-Host "--- 或者直接提取到 Program Files 的简化版 ---" -ForegroundColor DarkGray
Write-Host ""

# === 方法 2: 直接用 PowerShell 创建独立安装脚本 ===
Write-Host "=== 生成便携安装脚本 ===" -ForegroundColor Green

$SetupPs1 = "$OutputDir\安装番茄钟.ps1"
@"
# 番茄钟 一键安装
# 右键 → 使用 PowerShell 运行，或在终端: .\安装番茄钟.ps1

`$InstallDir = "`$env:LOCALAPPDATA\Programs\番茄钟"
Write-Host "正在安装 番茄钟 到 `$InstallDir..." -ForegroundColor Green

# 创建目录
New-Item -ItemType Directory -Force -Path `$InstallDir | Out-Null

# 复制自身同目录下的文件
`$ScriptDir = Split-Path -Parent `$MyInvocation.MyCommand.Path
Copy-Item "`$ScriptDir\*" -Destination `$InstallDir -Recurse -Force -Exclude "*.ps1","*.pdb"

# 开始菜单快捷方式
`$StartMenu = [Environment]::GetFolderPath('StartMenu') + '\Programs'
New-Item -ItemType Directory -Force -Path "`$StartMenu\番茄钟" | Out-Null
`$ws = New-Object -ComObject WScript.Shell
`$sc = `$ws.CreateShortcut("`$StartMenu\番茄钟\番茄钟.lnk")
`$sc.TargetPath = "`$InstallDir\Pomodoro.exe"
`$sc.WorkingDirectory = "`$InstallDir"
`$sc.Description = "番茄钟 - 专注计时器"
`$sc.Save()

# 桌面快捷方式
`$Desktop = [Environment]::GetFolderPath('Desktop')
`$sc2 = `$ws.CreateShortcut("`$Desktop\番茄钟.lnk")
`$sc2.TargetPath = "`$InstallDir\Pomodoro.exe"
`$sc2.WorkingDirectory = "`$InstallDir"
`$sc2.Description = "番茄钟 - 专注计时器"
`$sc2.Save()

Write-Host "✅ 安装完成！" -ForegroundColor Green
Write-Host "可从开始菜单或桌面快捷方式启动" -ForegroundColor White
Start-Sleep 3
"@ > $SetupPs1

Write-Host "安装脚本: $SetupPs1" -ForegroundColor White
Write-Host ""

# === 方法 3: 使用 Compress-Archive 打包便携版 ===
Write-Host "=== 生成便携版 ZIP ===" -ForegroundColor Green
$ZipFile = "$OutputDir\${AppTitle}Portable.zip"
Compress-Archive -Path "$PublishDir\*" -DestinationPath $ZipFile -Force
Write-Host "便携版: $ZipFile" -ForegroundColor White
Write-Host ""

# === 方法 4: 生成自解压安装包描述 ===
Write-Host "==============================" -ForegroundColor Cyan
Write-Host "  可用的安装方式" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  [推荐] 便携版: 解压 ${AppTitle}Portable.zip 到任意目录即可运行" -ForegroundColor Yellow
Write-Host "  双击 '安装番茄钟.ps1' 可一键安装（复制+创建快捷方式）" -ForegroundColor Yellow
Write-Host "  或用 IExpress 生成 .exe 安装包（运行: iexpress）" -ForegroundColor Yellow
Write-Host ""
Write-Host "生成的文件在: $OutputDir" -ForegroundColor White
