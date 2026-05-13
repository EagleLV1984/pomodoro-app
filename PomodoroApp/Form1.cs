using Microsoft.Web.WebView2.WinForms;

namespace PomodoroApp;

public partial class Form1 : Form
{
    private WebView2 webView = null!;

    public Form1()
    {
        InitializeComponent();
        InitWebView();
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

        Load += async (_, _) =>
        {
            var htmlPath = Path.Combine(AppContext.BaseDirectory, "pomodoro.html");
            var url = "file:///" + htmlPath.Replace('\\', '/');
            await webView.EnsureCoreWebView2Async();

            webView.DefaultBackgroundColor = Color.FromArgb(0x10, 0x10, 0x18);

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
