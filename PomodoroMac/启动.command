#!/bin/bash
# 番茄钟 一键编译 + 启动
# 放在 U 盘 PomodoroMac 文件夹里，双击即可

cd "$(dirname "$0")"
APP="./build/Pomodoro.app"

echo "========================================="
echo "        番 茄 钟 一 键 启 动"
echo "========================================="
echo ""

# 如果已编译好，直接运行
if [ -d "${APP}" ] && [ -f "${APP}/Contents/MacOS/Pomodoro" ]; then
    echo "✅ 检测到已编译版本，直接启动..."
    xattr -cr "${APP}" 2>/dev/null
    open "${APP}"
    exit 0
fi

# 源码存在则自动编译
if [ -f "main.swift" ] && [ -f "pomodoro.html" ]; then
    echo "🔨 首次使用，正在编译..."
    chmod +x build.sh 2>/dev/null
    ./build.sh
    echo ""
    if [ -d "${APP}" ]; then
        echo "✅ 编译成功！启动中..."
        xattr -cr "${APP}" 2>/dev/null
        open "${APP}"
        exit 0
    fi
fi

echo "❌ 找不到源码文件，请确保此脚本与 main.swift、pomodoro.html 在同一文件夹"
read -p "按回车退出..."
