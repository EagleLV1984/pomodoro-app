#!/usr/bin/env python3
"""番茄钟 - Python 版（跨平台 Windows/macOS/Linux）
依赖: pip install webview
"""
import webview
import os
import sys

# 读取同目录的 HTML 文件
script_dir = os.path.dirname(os.path.abspath(__file__))
html_path = os.path.join(script_dir, "pomodoro.html")

if not os.path.exists(html_path):
    print("错误: 找不到 pomodoro.html")
    sys.exit(1)

with open(html_path, "r", encoding="utf-8") as f:
    html = f.read()

class PomodoroAPI:
    """JS -> Python 桥接"""
    def __init__(self, window):
        self.window = window

    def alwaysOnTop(self, value):
        pass  # webview 暂不支持置顶切换

    def resizeWindow(self, width, height):
        if self.window:
            self.window.resize(width, height)

    def setDarkMode(self, value):
        pass  # webview 暂不支持

def on_loaded():
    # 注入桥接 JS
    api = PomodoroAPI(window)
    window.expose(api.alwaysOnTop)
    window.expose(api.resizeWindow)
    window.expose(api.setDarkMode)
    # 替换 HTML 中的 sendToHost 函数
    window.evaluate_js("""
        window.chrome = { webview: { postMessage: function(msg) {
            var obj = JSON.parse(msg);
            if (obj.type === 'alwaysOnTop') window.pywebview.api.alwaysOnTop(obj.value);
            if (obj.type === 'resizeWindow') window.pywebview.api.resizeWindow(obj.width, obj.height);
            if (obj.type === 'setDarkMode') window.pywebview.api.setDarkMode(obj.value);
        }}};
    """)

window = webview.create_window(
    title="番茄钟",
    html=html,
    width=420,
    height=612,
    min_size=(280, 400),
    resizable=True,
    frameless=False,
    easy_drag=False,
)

if __name__ == "__main__":
    webview.start(on_loaded, window)
