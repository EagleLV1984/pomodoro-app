using System.Runtime.InteropServices;

namespace PomodoroApp;

#nullable disable
partial class Form1
{
    private System.ComponentModel.IContainer components = null!;
    private Button closeBtn = null!;
    private Panel titleBar = null!;

    [DllImport("dwmapi.dll")]
    private static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);

    private void InitializeComponent()
    {
        components = new System.ComponentModel.Container();
        AutoScaleMode = AutoScaleMode.Font;

        // Frameless, modern window
        FormBorderStyle = FormBorderStyle.None;
        StartPosition = FormStartPosition.CenterScreen;
        BackColor = Color.FromArgb(0x10, 0x10, 0x18);
        ClientSize = new Size(400, 580);
        Text = "番茄钟";
        Padding = new Padding(0);

        // Enable Win11 rounded corners + shadow
        Load += (_, _) =>
        {
            int useDarkMode = 1;
            int cornerPref = 2; // DWMWCP_ROUND
            DwmSetWindowAttribute(Handle, 20, ref useDarkMode, 4);  // DWMWA_USE_IMMERSIVE_DARK_MODE
            DwmSetWindowAttribute(Handle, 33, ref cornerPref, 4);    // DWMWA_WINDOW_CORNER_PREFERENCE
        };

        // Title bar
        titleBar = new Panel
        {
            Height = 32,
            Dock = DockStyle.Top,
            BackColor = Color.FromArgb(0x10, 0x10, 0x18),
        };
        Controls.Add(titleBar);

        // Title label
        var titleLabel = new Label
        {
            Text = "  番茄钟",
            Font = new Font("Microsoft YaHei UI", 9f, FontStyle.Regular),
            ForeColor = Color.FromArgb(0xaa, 0xaa, 0xbb),
            AutoSize = true,
            Location = new Point(0, 7),
        };
        titleBar.Controls.Add(titleLabel);

        // Close button
        closeBtn = new Button
        {
            Text = "✕",
            FlatStyle = FlatStyle.Flat,
            Font = new Font("Segoe UI", 9f, FontStyle.Regular),
            ForeColor = Color.FromArgb(0x88, 0x88, 0x99),
            Size = new Size(40, 28),
            Location = new Point(ClientSize.Width - 42, 2),
            Anchor = AnchorStyles.Top | AnchorStyles.Right,
            Cursor = Cursors.Hand,
        };
        closeBtn.FlatAppearance.BorderSize = 0;
        closeBtn.FlatAppearance.MouseOverBackColor = Color.FromArgb(0xe8, 0x3e, 0x3e);
        closeBtn.FlatAppearance.MouseDownBackColor = Color.FromArgb(0xc0, 0x30, 0x30);
        closeBtn.MouseEnter += (_, _) => closeBtn.ForeColor = Color.White;
        closeBtn.MouseLeave += (_, _) => closeBtn.ForeColor = Color.FromArgb(0x88, 0x88, 0x99);
        closeBtn.Click += (_, _) => Application.Exit();
        titleBar.Controls.Add(closeBtn);

        // Enable dragging on the title bar
        titleBar.MouseDown += TitleBar_MouseDown;
        titleLabel.MouseDown += TitleBar_MouseDown;
    }

    private void TitleBar_MouseDown(object? sender, MouseEventArgs e)
    {
        if (e.Button == MouseButtons.Left)
        {
            ReleaseCapture();
            SendMessage(Handle, 0xA1, 2, 0); // WM_NCLBUTTONDOWN, HTCAPTION
        }
    }

    [DllImport("user32.dll")]
    private static extern bool ReleaseCapture();
    [DllImport("user32.dll")]
    private static extern IntPtr SendMessage(IntPtr hWnd, int msg, int wParam, int lParam);
}
