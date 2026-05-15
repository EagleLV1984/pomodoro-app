# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

基于 C# WinForms + WebView2 的桌面番茄钟应用，运行在 .NET 10 上。原生窗口框架提供无边框窗口、自定义标题栏、Win11 圆角以及拖拽支持。UI 为 HTML/CSS/JS 页面，通过 WebView2 控件渲染。

## 构建与发布

```bash
# 构建（Debug）
dotnet build PomodoroApp/PomodoroApp.csproj

# 发布为单文件自包含 exe
dotnet publish PomodoroApp/PomodoroApp.csproj -c Release -o publish
```

输出：`publish/Pomodoro.exe`（自包含 win-x64，目标机器无需安装 .NET 运行时）。

## 架构

```
PomodoroApp/
├── Program.cs              # 入口点，STAThread，Application.Run(Form1)
├── Form1.cs                # Form：嵌入 WebView2，启动时将嵌入的 HTML 资源提取到临时目录
├── Form1.Designer.cs       # 无边框窗口设置：自定义标题栏（32px）、关闭按钮、通过 DwmSetWindowAttribute 设置 Win11 暗色模式 + 圆角、通过 ReleaseCapture/SendMessage 实现窗口拖拽
├── pomodoro.html           # 完整番茄钟 UI（嵌入资源，运行时提取）
├── manifest.json           # PWA manifest（嵌入资源）
├── sw.js                   # Service Worker（嵌入资源）
└── PomodoroApp.csproj      # .NET 10、WinForms、WebView2、PublishSingleFile、EmbeddedResource
```

**关键设计决策：**
- HTML/CSS/JS 文件作为 `EmbeddedResource` 嵌入——运行时提取到 `%TEMP%/PomodoroApp/`，然后通过 `file:///` URL 加载到 WebView2
- 窗口无边框（`FormBorderStyle.None`），400×580px，深色主题（#101018）
- 标题栏拖拽使用 Win32 API：`ReleaseCapture` + `SendMessage(WM_NCLBUTTONDOWN, HTCAPTION)`
- Win11 视觉样式：`DwmSetWindowAttribute` 用于沉浸式暗色模式（attr 20）和圆角（attr 33）
- WebView2 中禁用开发者工具和右键菜单
- WebView2 权限设为全部允许（Notification API 需要）

## HTML/JS 计时器功能

- 三种模式：专注（25分钟）、短休（5分钟）、长休（15分钟）
- SVG 环形进度条，通过 `stroke-dashoffset` 动画
- 完成时通过 Web Audio API 播放提示音、闪光效果、Toast 通知
- Notification API 桌面通知
- 键盘快捷键：空格（开始/暂停）、1/2/3（切换模式）、R（重置）、S（跳过）
- 使用 localStorage 持久化番茄/今日计数，带日期重置逻辑
- 自动切换：专注 → 短休（每4次为长休），休息 → 专注
