using System.Runtime.InteropServices;

namespace PomodoroApp;

#nullable disable
partial class Form1
{
    private System.ComponentModel.IContainer components = null!;
    private Button closeBtn = null!;
    private Button minimizeBtn = null!;
    private Button maximizeBtn = null!;
    private Panel titleBar = null!;
    private Label titleLabel = null!;

    [DllImport("dwmapi.dll")]
    private static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);

    protected override CreateParams CreateParams
    {
        get { var cp = base.CreateParams; cp.Style |= 0x00040000; return cp; }
    }

    private const int WM_NCHITTEST = 0x0084;
    private const int HTLEFT=10, HTRIGHT=11, HTTOP=12, HTBOTTOM=15;
    private const int HTTOPLEFT=13, HTTOPRIGHT=14, HTBOTTOMLEFT=16, HTBOTTOMRIGHT=17;
    private const int HTCAPTION = 2;

    protected override void WndProc(ref Message m)
    {
        if (m.Msg == WM_NCHITTEST)
        {
            var pt = PointToClient(new Point(m.LParam.ToInt32() & 0xFFFF, (m.LParam.ToInt32() >> 16) & 0xFFFF));
            int x = pt.X, y = pt.Y;
            const int edge = 6, corner = 16;
            if (x <= corner && y <= corner) m.Result = (IntPtr)HTTOPLEFT;
            else if (x >= ClientSize.Width - corner && y <= corner) m.Result = (IntPtr)HTTOPRIGHT;
            else if (x <= corner && y >= ClientSize.Height - corner) m.Result = (IntPtr)HTBOTTOMLEFT;
            else if (x >= ClientSize.Width - corner && y >= ClientSize.Height - corner) m.Result = (IntPtr)HTBOTTOMRIGHT;
            else if (x <= edge) m.Result = (IntPtr)HTLEFT;
            else if (x >= ClientSize.Width - edge) m.Result = (IntPtr)HTRIGHT;
            else if (y <= edge) m.Result = (IntPtr)HTTOP;
            else if (y >= ClientSize.Height - edge) m.Result = (IntPtr)HTBOTTOM;
            else if (y < 32 && x < ClientSize.Width - 130) m.Result = (IntPtr)HTCAPTION;
            else base.WndProc(ref m);
            return;
        }
        base.WndProc(ref m);
    }

    public void SetIcon()
    {
        try
        {
            var asm = System.Reflection.Assembly.GetExecutingAssembly();
            using var stream = asm.GetManifestResourceStream("PomodoroApp.appicon.ico");
            if (stream == null) return;
            // 写入临时文件再加载，避免压缩ICO流加载失败
            var tmp = Path.Combine(Path.GetTempPath(), "pomodoro_appicon.ico");
            using (var fs = File.Create(tmp)) { stream.CopyTo(fs); }
            Icon = new System.Drawing.Icon(tmp);
            try { File.Delete(tmp); } catch { }
        }
        catch { }
    }

    private void InitializeComponent()
    {
        components = new System.ComponentModel.Container();
        AutoScaleMode = AutoScaleMode.Font;
        FormBorderStyle = FormBorderStyle.None;
        StartPosition = FormStartPosition.CenterScreen;
        BackColor = Color.FromArgb(0xFD, 0xF2, 0xF2);
        ClientSize = new Size(400, 580);
        MinimumSize = new Size(280, 380);
        Text = "超坦番茄钟";
        Padding = new Padding(0);

        Load += (_, _) =>
        {
            int cornerPref = 2;
            DwmSetWindowAttribute(Handle, 33, ref cornerPref, 4);
        };
        Resize += (_, _) => UpdateMaximizeButtonText();

        titleBar = new Panel
        {
            Height = 32, Dock = DockStyle.Top,
            BackColor = Color.FromArgb(0xFD, 0xF2, 0xF2),
        };
        Controls.Add(titleBar);

        titleLabel = new Label
        {
            Text = "  超坦番茄钟",
            Font = new Font("Microsoft YaHei UI", 9f, FontStyle.Regular),
            ForeColor = Color.FromArgb(0x5D, 0x2E, 0x2E),
            AutoSize = true, Location = new Point(0, 7),
        };
        titleBar.Controls.Add(titleLabel);

        minimizeBtn = new Button
        {
            Text = "—", FlatStyle = FlatStyle.Flat,
            Font = new Font("Segoe UI Symbol", 8f, FontStyle.Regular),
            ForeColor = Color.FromArgb(0x9A, 0x9A, 0x9A),
            Size = new Size(42, 28),
            Location = new Point(ClientSize.Width - 130, 2),
            Anchor = AnchorStyles.Top | AnchorStyles.Right, Cursor = Cursors.Hand,
        };
        minimizeBtn.FlatAppearance.BorderSize = 0;
        minimizeBtn.FlatAppearance.MouseOverBackColor = Color.FromArgb(0xE8, 0xD5, 0xD5);
        minimizeBtn.MouseEnter += (_, _) => minimizeBtn.ForeColor = Color.FromArgb(0x5D, 0x2E, 0x2E);
        minimizeBtn.MouseLeave += (_, _) => minimizeBtn.ForeColor = Color.FromArgb(0x9A, 0x9A, 0x9A);
        minimizeBtn.Click += (_, _) => WindowState = FormWindowState.Minimized;
        titleBar.Controls.Add(minimizeBtn);

        maximizeBtn = new Button
        {
            Text = "□", FlatStyle = FlatStyle.Flat,
            Font = new Font("Segoe UI Symbol", 8f, FontStyle.Regular),
            ForeColor = Color.FromArgb(0x9A, 0x9A, 0x9A),
            Size = new Size(42, 28),
            Location = new Point(ClientSize.Width - 86, 2),
            Anchor = AnchorStyles.Top | AnchorStyles.Right, Cursor = Cursors.Hand,
        };
        maximizeBtn.FlatAppearance.BorderSize = 0;
        maximizeBtn.FlatAppearance.MouseOverBackColor = Color.FromArgb(0xE8, 0xD5, 0xD5);
        maximizeBtn.MouseEnter += (_, _) => maximizeBtn.ForeColor = Color.FromArgb(0x5D, 0x2E, 0x2E);
        maximizeBtn.MouseLeave += (_, _) => maximizeBtn.ForeColor = Color.FromArgb(0x9A, 0x9A, 0x9A);
        maximizeBtn.Click += (_, _) => { WindowState = WindowState == FormWindowState.Maximized ? FormWindowState.Normal : FormWindowState.Maximized; };
        titleBar.Controls.Add(maximizeBtn);

        closeBtn = new Button
        {
            Text = "✕", FlatStyle = FlatStyle.Flat,
            Font = new Font("Segoe UI", 9f, FontStyle.Regular),
            ForeColor = Color.FromArgb(0x9A, 0x9A, 0x9A),
            Size = new Size(42, 28),
            Location = new Point(ClientSize.Width - 42, 2),
            Anchor = AnchorStyles.Top | AnchorStyles.Right, Cursor = Cursors.Hand,
        };
        closeBtn.FlatAppearance.BorderSize = 0;
        closeBtn.FlatAppearance.MouseOverBackColor = Color.FromArgb(0xe8, 0x3e, 0x3e);
        closeBtn.FlatAppearance.MouseDownBackColor = Color.FromArgb(0xc0, 0x30, 0x30);
        closeBtn.MouseEnter += (_, _) => closeBtn.ForeColor = Color.White;
        closeBtn.MouseLeave += (_, _) => closeBtn.ForeColor = Color.FromArgb(0x9A, 0x9A, 0x9A);
        closeBtn.Click += (_, _) => Application.Exit();
        titleBar.Controls.Add(closeBtn);

        titleBar.DoubleClick += (_, _) => { WindowState = WindowState == FormWindowState.Maximized ? FormWindowState.Normal : FormWindowState.Maximized; };
        titleLabel.DoubleClick += (_, _) => { WindowState = WindowState == FormWindowState.Maximized ? FormWindowState.Normal : FormWindowState.Maximized; };
        titleBar.MouseDown += TitleBar_MouseDown;
        titleLabel.MouseDown += TitleBar_MouseDown;
    }

    private void UpdateMaximizeButtonText() { if (maximizeBtn != null) maximizeBtn.Text = WindowState == FormWindowState.Maximized ? "❐" : "□"; }

    private void TitleBar_MouseDown(object? sender, MouseEventArgs e)
    {
        if (e.Button == MouseButtons.Left) { ReleaseCapture(); SendMessage(Handle, 0xA1, 2, 0); }
    }

    [DllImport("user32.dll")] private static extern bool ReleaseCapture();
    [DllImport("user32.dll")] private static extern IntPtr SendMessage(IntPtr hWnd, int msg, int wParam, int lParam);
}
