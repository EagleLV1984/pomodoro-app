using Microsoft.Web.WebView2.WinForms;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text.Json;

namespace PomodoroApp;

public partial class Form1 : Form
{
    private WebView2 webView = null!;

    // 阻止屏幕休眠
    [DllImport("kernel32.dll")]
    private static extern uint SetThreadExecutionState(uint esFlags);
    private const uint ES_CONTINUOUS = 0x80000000;
    private const uint ES_SYSTEM_REQUIRED = 0x00000001;
    private const uint ES_DISPLAY_REQUIRED = 0x00000002;

    public Form1()
    {
        InitializeComponent();
        SetIcon();
        InitWebView();
        // 保持屏幕常亮
        SetThreadExecutionState(ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED);
        FormClosing += (_, _) => SetThreadExecutionState(ES_CONTINUOUS);
    }

    private static void ExtractEmbeddedResources(string targetDir)
    {
        var assembly = Assembly.GetExecutingAssembly();
        var names = assembly.GetManifestResourceNames();
        foreach (var name in names)
        {
            if (!name.StartsWith("PomodoroApp.")) continue;
            var fileName = name["PomodoroApp.".Length..];
            var targetPath = Path.Combine(targetDir, fileName);
            using var stream = assembly.GetManifestResourceStream(name);
            if (stream is null) continue;
            using var fs = File.Create(targetPath);
            stream.CopyTo(fs);
        }
    }

    private void InitWebView()
    {
        webView = new WebView2
        {
            Location = new Point(0, 32),
            Size = new Size(ClientSize.Width, ClientSize.Height - 32),
            Anchor = AnchorStyles.Top | AnchorStyles.Bottom | AnchorStyles.Left | AnchorStyles.Right,
        };
        Controls.Add(webView);

        // 窗口大小改变时同步 WebView2 尺寸
        Resize += (_, _) =>
        {
            webView.Size = new Size(ClientSize.Width, ClientSize.Height - 32);
        };

        Load += async (_, _) =>
        {
            var dataDir = Path.Combine(Path.GetTempPath(), "PomodoroApp");
            Directory.CreateDirectory(dataDir);
            ExtractEmbeddedResources(dataDir);

            // 检测用户自定义背景图：如果 exe 同目录有 pomodoro.png，覆盖默认的
            var exeDir = AppContext.BaseDirectory;
            var userPng = Path.Combine(exeDir, "pomodoro.png");
            var tempPng = Path.Combine(dataDir, "pomodoro.png");
            if (File.Exists(userPng))
            {
                File.Copy(userPng, tempPng, true);
            }

            var htmlPath = Path.Combine(dataDir, "pomodoro.html");
            var url = "file:///" + htmlPath.Replace('\\', '/');
            await webView.EnsureCoreWebView2Async();

            webView.DefaultBackgroundColor = Color.FromArgb(0xFD, 0xF2, 0xF2);

            webView.CoreWebView2.WebMessageReceived += OnWebMessageReceived;
            webView.CoreWebView2.DocumentTitleChanged += OnDocumentTitleChanged;

            webView.CoreWebView2.Navigate(url);
            webView.CoreWebView2.Settings.AreDevToolsEnabled = false;
            webView.CoreWebView2.Settings.AreDefaultContextMenusEnabled = false;
        };

        webView.CoreWebView2InitializationCompleted += (_, _) =>
        {
            webView.CoreWebView2.PermissionRequested += (_, args) =>
            {
                args.State = Microsoft.Web.WebView2.Core.CoreWebView2PermissionState.Allow;
            };
        };
    }

    private void OnWebMessageReceived(object? sender, Microsoft.Web.WebView2.Core.CoreWebView2WebMessageReceivedEventArgs e)
    {
        try
        {
            using var doc = JsonDocument.Parse(e.WebMessageAsJson);
            var type = doc.RootElement.GetProperty("type").GetString();
            switch (type)
            {
                case "alwaysOnTop":
                    var topMost = doc.RootElement.TryGetProperty("value", out var vTop) && vTop.GetBoolean();
                    this.BeginInvoke(() => this.TopMost = topMost);
                    break;

                case "resizeWindow":
                    var w = doc.RootElement.GetProperty("width").GetInt32();
                    var h = doc.RootElement.GetProperty("height").GetInt32();
                    this.BeginInvoke(() =>
                    {
                        this.ClientSize = new Size(w, h);
                        this.CenterToScreen();
                    });
                    break;

                case "setDarkMode":
                    var dark = doc.RootElement.TryGetProperty("value", out var vDark) && vDark.GetBoolean();
                    this.BeginInvoke(() =>
                    {
                        int useDarkMode = dark ? 1 : 0;
                        DwmSetWindowAttribute(this.Handle, 20, ref useDarkMode, 4);
                    });
                    break;
            }
        }
        catch { /* 忽略非法消息 */ }
    }

    private void OnDocumentTitleChanged(object? sender, object? e)
    {
        this.BeginInvoke(() =>
        {
            var t = webView.CoreWebView2.DocumentTitle ?? "超坦番茄钟";
            var parts = t.Split('|');
            titleLabel!.Text = "  " + (parts.Length > 1 ? parts[0].Trim() + " - 工作时间" : t);
        });
    }

    // DwmSetWindowAttribute 在 Form1.Designer.cs 中定义，此处复用

    protected override void Dispose(bool disposing)
    {
        if (disposing)
        {
            webView?.Dispose();
            components?.Dispose();
        }
        base.Dispose(disposing);
    }
}
