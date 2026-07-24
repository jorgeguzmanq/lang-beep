# lang-beep-popup.ps1
# Muestra un popup breve, centrado y con bordes redondeados en cada monitor
# conectado, con el codigo de idioma (ej. "ENG"). Se lanza como proceso hijo
# independiente desde lang-beep.ps1 para no bloquear el bucle de deteccion.

param(
    [Parameter(Mandatory = $true)]
    [string]$Text
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Get-RoundedRegion([int]$width, [int]$height, [int]$radius) {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $radius * 2
    $path.AddArc(0, 0, $d, $d, 180, 90)
    $path.AddArc($width - $d, 0, $d, $d, 270, 90)
    $path.AddArc($width - $d, $height - $d, $d, $d, 0, 90)
    $path.AddArc(0, $height - $d, $d, $d, 90, 90)
    $path.CloseFigure()
    return New-Object System.Drawing.Region($path)
}

$forms = @()
$w = 160
$h = 100

foreach ($screen in [System.Windows.Forms.Screen]::AllScreens) {
    $form = New-Object System.Windows.Forms.Form
    $form.FormBorderStyle = 'None'
    $form.StartPosition   = 'Manual'
    $form.TopMost         = $true
    $form.ShowInTaskbar   = $false
    $form.BackColor       = [System.Drawing.Color]::FromArgb(32, 32, 32)
    $form.Size            = New-Object System.Drawing.Size($w, $h)
    $form.Opacity         = 0.92
    $form.Region          = Get-RoundedRegion $w $h 40

    $bounds = $screen.Bounds
    $x = $bounds.X + [int](($bounds.Width - $w) / 2)
    $y = $bounds.Y + [int](($bounds.Height - $h) / 2)
    $form.Location = New-Object System.Drawing.Point($x, $y)

    $label = New-Object System.Windows.Forms.Label
    $label.Text      = $Text
    $label.Font      = New-Object System.Drawing.Font('Segoe UI', 28, [System.Drawing.FontStyle]::Bold)
    $label.ForeColor = [System.Drawing.Color]::White
    $label.TextAlign = 'MiddleCenter'
    $label.Dock      = 'Fill'
    $form.Controls.Add($label)

    $forms += $form
    $form.Show()
}

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 800
$timer.Add_Tick({
    $timer.Stop()
    foreach ($f in $forms) { $f.Close() }
    [System.Windows.Forms.Application]::Exit()
})
$timer.Start()

[System.Windows.Forms.Application]::Run()
