Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName WindowsBase

$script:outputDir   = Join-Path $env:USERPROFILE "Desktop\NativefierApps"
$script:useNpx      = $false
$script:historyFile = Join-Path $env:USERPROFILE ".nativefier_gui_history.log"
$script:setupOK     = $false

function Invoke-Cmd {
    param([string]$Exe, [string[]]$CmdArgs)
    try {
        $found = Get-Command $Exe -ErrorAction SilentlyContinue
        if (-not $found) {
            return [pscustomobject]@{ Output = ''; Exit = 99; Err = "$Exe not found in PATH" }
        }
        $pi                        = [Diagnostics.ProcessStartInfo]::new()
        $pi.FileName               = $found.Source
        $pi.Arguments              = ($CmdArgs -join ' ')
        $pi.UseShellExecute        = $false
        $pi.RedirectStandardOutput = $true
        $pi.RedirectStandardError  = $true
        $pi.CreateNoWindow         = $true
        $p   = [Diagnostics.Process]::Start($pi)
        $out = $p.StandardOutput.ReadToEnd()
        $err = $p.StandardError.ReadToEnd()
        $p.WaitForExit()
        return [pscustomobject]@{ Output = $out.Trim(); Exit = $p.ExitCode; Err = $err.Trim() }
    } catch {
        return [pscustomobject]@{ Output = ''; Exit = 99; Err = $_.Exception.Message }
    }
}

function Get-InstallState {
    $node = Invoke-Cmd 'node'       @('--version')
    $npm  = Invoke-Cmd 'npm'        @('--version')
    $nat  = Invoke-Cmd 'nativefier' @('--version')
    $npx  = Invoke-Cmd 'npx'        @('--version')
    return @{
        NodeOK        = ($node.Exit -eq 0)
        NodeVer       = $node.Output
        NpmOK         = ($npm.Exit -eq 0)
        NpmVer        = $npm.Output
        NativefierOK  = ($nat.Exit -eq 0)
        NativefierVer = $nat.Output
        NpxOK         = ($npx.Exit -eq 0)
    }
}

function Show-Setup {

    [xml]$xaml = @'
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    Height="520" Width="600"
    WindowStartupLocation="CenterScreen"
    ResizeMode="NoResize"
    WindowStyle="None"
    AllowsTransparency="True"
    Background="Transparent">
  <Border CornerRadius="16" Background="#0F0F1A">
    <Border.Effect>
      <DropShadowEffect BlurRadius="30" ShadowDepth="0" Opacity="0.6"/>
    </Border.Effect>
    <Grid>
      <Grid.RowDefinitions>
        <RowDefinition Height="40"/>
        <RowDefinition Height="*"/>
      </Grid.RowDefinitions>

      <Border Grid.Row="0" Background="#16162A" CornerRadius="16,16,0,0" Name="dragBar">
        <Grid>
          <TextBlock Text="NativefierGUI - Setup" Foreground="#888"
                     VerticalAlignment="Center" Margin="16,0,0,0" FontSize="12"/>
          <Button Name="btnClose" Content="X"
                  HorizontalAlignment="Right" Margin="0,0,8,0"
                  Background="Transparent" Foreground="#888"
                  BorderThickness="0" FontSize="14" Cursor="Hand"
                  Width="30" Height="30"/>
        </Grid>
      </Border>

      <Grid Grid.Row="1" Margin="40,10,40,30">

        <StackPanel Name="p1">
          <TextBlock Text="&#x26A1;" FontSize="50"
                     HorizontalAlignment="Center" Margin="0,15,0,5"/>
          <TextBlock Text="Welcome to NativefierGUI"
                     Foreground="White" FontSize="22" FontWeight="Bold"
                     HorizontalAlignment="Center"/>
          <TextBlock Text="Convert any website into a desktop app"
                     Foreground="#888" FontSize="13"
                     HorizontalAlignment="Center" Margin="0,4,0,20"/>
          <Border Background="#1A1A2E" CornerRadius="12" Padding="20" Margin="0,0,0,20">
            <StackPanel>
              <TextBlock Text="Do you have Nativefier installed?"
                         Foreground="White" FontSize="15" FontWeight="SemiBold"
                         HorizontalAlignment="Center" Margin="0,0,0,6"/>
              <TextBlock Text="Click Yes and we will verify it. Click No and we will install everything for you."
                         Foreground="#888" FontSize="12" HorizontalAlignment="Center"
                         TextWrapping="Wrap" TextAlignment="Center"/>
            </StackPanel>
          </Border>
          <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
            <Button Name="btnYesNat" Content="Yes, I have it"
                    Padding="28,12" Margin="0,0,10,0"
                    Background="#7C3AED" Foreground="White"
                    FontSize="14" FontWeight="SemiBold"
                    BorderThickness="0" Cursor="Hand"/>
            <Button Name="btnNoNat" Content="No, install for me"
                    Padding="28,12" Background="#2D2D5E" Foreground="White"
                    FontSize="14" FontWeight="SemiBold"
                    BorderThickness="0" Cursor="Hand"/>
          </StackPanel>
        </StackPanel>

        <StackPanel Name="p2" Visibility="Collapsed" VerticalAlignment="Center">
          <TextBlock Name="iEmo" Text="&#x23F3;" FontSize="50"
                     HorizontalAlignment="Center" Margin="0,0,0,10"/>
          <TextBlock Name="iTitle" Text="Checking..."
                     Foreground="White" FontSize="22" FontWeight="Bold"
                     HorizontalAlignment="Center" Margin="0,0,0,8"/>
          <TextBlock Name="iStatus" Text="Please wait..."
                     Foreground="#888" FontSize="13"
                     HorizontalAlignment="Center"
                     Margin="0,0,0,16" TextWrapping="Wrap"
                     TextAlignment="Center" MaxWidth="460"/>
          <ProgressBar Name="pBar" Height="6" Margin="30,0,30,12"
                       IsIndeterminate="True"
                       Foreground="#7C3AED" Background="#2D2D5E"
                       BorderThickness="0"/>
          <TextBlock Name="iLog" Text=""
                     Foreground="#666" FontSize="11"
                     HorizontalAlignment="Center"
                     TextWrapping="Wrap" FontFamily="Consolas"
                     Margin="0,4,0,0" MaxWidth="460"
                     TextAlignment="Center"/>
          <Button Name="btnBack" Content="Go Back"
                  Visibility="Collapsed"
                  Margin="0,20,0,0" Padding="24,10"
                  Background="#2D2D5E" Foreground="White"
                  BorderThickness="0" Cursor="Hand"
                  FontSize="13" HorizontalAlignment="Center"/>
        </StackPanel>

        <StackPanel Name="p3" Visibility="Collapsed">
          <TextBlock Text="&#x1F4E6;" FontSize="50"
                     HorizontalAlignment="Center" Margin="0,15,0,5"/>
          <TextBlock Text="Node.js Not Found"
                     Foreground="White" FontSize="22" FontWeight="Bold"
                     HorizontalAlignment="Center"/>
          <TextBlock Text="Node.js and npm are required. We can install them for you."
                     Foreground="#888" FontSize="13"
                     HorizontalAlignment="Center" Margin="0,4,0,16"
                     TextWrapping="Wrap" TextAlignment="Center"/>
          <Border Background="#1A1A2E" CornerRadius="12" Padding="16" Margin="0,0,0,20">
            <TextBlock Name="diagText"
                       Foreground="#AAA" FontSize="12"
                       FontFamily="Consolas" TextWrapping="Wrap"
                       TextAlignment="Center" HorizontalAlignment="Center"/>
          </Border>
          <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
            <Button Name="btnInstNode" Content="Install Node.js automatically"
                    Padding="24,12" Margin="0,0,10,0"
                    Background="#7C3AED" Foreground="White"
                    FontSize="13" FontWeight="SemiBold"
                    BorderThickness="0" Cursor="Hand"/>
            <Button Name="btnOpenNode" Content="Download manually"
                    Padding="20,12" Background="#2D2D5E" Foreground="White"
                    FontSize="13" BorderThickness="0" Cursor="Hand"/>
          </StackPanel>
        </StackPanel>

      </Grid>
    </Grid>
  </Border>
</Window>
'@

    $sw = [Windows.Markup.XamlReader]::Load([Xml.XmlNodeReader]::new($xaml))

    $sw.FindName('dragBar').Add_MouseLeftButtonDown({ $sw.DragMove() })
    $sw.FindName('btnClose').Add_Click({ $sw.Close() })

    $p1       = $sw.FindName('p1')
    $p2       = $sw.FindName('p2')
    $p3       = $sw.FindName('p3')
    $iEmo     = $sw.FindName('iEmo')
    $iTitle   = $sw.FindName('iTitle')
    $iStatus  = $sw.FindName('iStatus')
    $iLog     = $sw.FindName('iLog')
    $pBar     = $sw.FindName('pBar')
    $btnBack  = $sw.FindName('btnBack')
    $diagText = $sw.FindName('diagText')

    $btnBack.Add_Click({
        $p2.Visibility = 'Collapsed'
        $p3.Visibility = 'Collapsed'
        $p1.Visibility = 'Visible'
    })

    $doRefresh = {
        $sw.Dispatcher.Invoke([Action]{}, 'Background')
    }

    $doProgress = {
        param([string]$Title, [string]$Status, [string]$Log)
        $p1.Visibility        = 'Collapsed'
        $p3.Visibility        = 'Collapsed'
        $p2.Visibility        = 'Visible'
        $btnBack.Visibility   = 'Collapsed'
        $iEmo.Text            = [char]0x23F3
        $iTitle.Text          = $Title
        $iStatus.Text         = $Status
        $iLog.Text            = $Log
        $pBar.IsIndeterminate = $true
        & $doRefresh
    }

    $doDone = {
        param([string]$Title, [string]$Status)
        $iEmo.Text            = [char]0x2705
        $iTitle.Text          = $Title
        $iStatus.Text         = $Status
        $iLog.Text            = ''
        $pBar.IsIndeterminate = $false
        $pBar.Value           = 100
        & $doRefresh
    }

    $doErr = {
        param([string]$Title, [string]$Msg, [string]$Detail)
        $iEmo.Text            = [char]0x274C
        $iTitle.Text          = $Title
        $iStatus.Text         = $Msg
        $iLog.Text            = $Detail
        $pBar.IsIndeterminate = $false
        $pBar.Value           = 0
        $btnBack.Visibility   = 'Visible'
        & $doRefresh
    }

    $doInstallNativefier = {
        & $doProgress 'Installing Nativefier...' 'Running npm install -g nativefier' 'This can take 1-3 minutes...'

        $r = Invoke-Cmd 'npm' @('install', '-g', 'nativefier')

        if ($r.Exit -eq 0) {
            $check = Invoke-Cmd 'nativefier' @('--version')
            if ($check.Exit -eq 0) {
                $script:setupOK = $true
                & $doDone 'All Done!' "Nativefier $($check.Output) is ready"
                Start-Sleep -Seconds 1
                $sw.Close()
            } else {
                $npxCheck = Invoke-Cmd 'npx' @('nativefier', '--version')
                if ($npxCheck.Exit -eq 0) {
                    $script:useNpx  = $true
                    $script:setupOK = $true
                    & $doDone 'Done (using npx)!' "Nativefier $($npxCheck.Output) ready via npx"
                    Start-Sleep -Seconds 1
                    $sw.Close()
                } else {
                    & $doErr 'Installed But Not in PATH' `
                        'Nativefier was installed but cannot be found.' `
                        'Please close this app and restart your PC, then try again.'
                }
            }
        } else {
            & $doErr 'npm install Failed' `
                'Could not install nativefier via npm.' `
                $r.Err
        }
    }

    $sw.FindName('btnYesNat').Add_Click({
        & $doProgress 'Checking your system...' 'Looking for nativefier, node, npm...' ''

        $state = Get-InstallState

        if ($state.NativefierOK) {
            $script:setupOK = $true
            & $doDone 'Ready to go!' "Nativefier $($state.NativefierVer) found"
            Start-Sleep -Milliseconds 900
            $sw.Close()
            return
        }

        $iLog.Text = 'nativefier not in PATH, trying npx...'
        & $doRefresh

        $npxR = Invoke-Cmd 'npx' @('nativefier', '--version')
        if ($npxR.Exit -eq 0 -and $npxR.Output -ne '') {
            $script:useNpx  = $true
            $script:setupOK = $true
            & $doDone 'Ready (via npx)!' "Nativefier $($npxR.Output) found via npx"
            Start-Sleep -Milliseconds 900
            $sw.Close()
            return
        }

        if ($state.NpmOK) {
            & $doInstallNativefier
        } elseif ($state.NodeOK) {
            & $doErr 'npm Not Found' `
                "Node.js $($state.NodeVer) is installed but npm is missing." `
                'Please reinstall Node.js from nodejs.org (npm is included with it).'
        } else {
            $diagText.Text = "node      : not found`nnpm       : not found`nnativefier: not found"
            $p2.Visibility = 'Collapsed'
            $p3.Visibility = 'Visible'
        }
    })

    $sw.FindName('btnNoNat').Add_Click({
        & $doProgress 'Checking your system...' 'Scanning for Node.js and npm...' ''

        $state = Get-InstallState

        if ($state.NpmOK) {
            & $doInstallNativefier
        } elseif ($state.NodeOK) {
            & $doErr 'npm Not Found' `
                "Node.js $($state.NodeVer) found but npm is not working." `
                'Reinstall Node.js from nodejs.org to fix npm.'
        } else {
            $diagText.Text = "node      : not found`nnpm       : not found`n`nWe will install Node.js and Nativefier for you."
            $p2.Visibility = 'Collapsed'
            $p3.Visibility = 'Visible'
        }
    })

    $sw.FindName('btnInstNode').Add_Click({
        & $doProgress 'Downloading Node.js...' 'Fetching installer from nodejs.org' ''
        try {
            $arch = if ([Environment]::Is64BitOperatingSystem) { 'x64' } else { 'x86' }
            $url  = "https://nodejs.org/dist/v20.11.0/node-v20.11.0-$arch.msi"
            $msi  = Join-Path $env:TEMP 'node_setup.msi'

            $iLog.Text = "Downloading Node.js $arch installer..."
            & $doRefresh

            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $url -OutFile $msi -UseBasicParsing

            $iStatus.Text = 'Installing Node.js...'
            $iLog.Text    = 'Running installer, this takes a minute...'
            & $doRefresh

            Start-Process msiexec.exe -ArgumentList "/i `"$msi`" /passive /norestart" -Wait
            Remove-Item $msi -Force -ErrorAction SilentlyContinue

            $env:PATH = [Environment]::GetEnvironmentVariable('PATH', 'Machine') + ';' +
                        [Environment]::GetEnvironmentVariable('PATH', 'User')
            Start-Sleep -Seconds 3

            $nodeCheck = Invoke-Cmd 'node' @('--version')
            $npmCheck  = Invoke-Cmd 'npm'  @('--version')

            if ($nodeCheck.Exit -ne 0 -or $npmCheck.Exit -ne 0) {
                & $doErr 'PATH Not Updated' `
                    'Node.js installed but is not in PATH yet.' `
                    'Please restart your PC and run this app again.'
                return
            }

            $iLog.Text = "Node $($nodeCheck.Output) and npm $($npmCheck.Output) ready"
            & $doRefresh
            Start-Sleep -Milliseconds 800

            & $doInstallNativefier

        } catch {
            & $doErr 'Download Failed' `
                'Could not download the Node.js installer.' `
                $_.Exception.Message
        }
    })

    $sw.FindName('btnOpenNode').Add_Click({
        Start-Process 'https://nodejs.org/en/download'
    })

    $sw.ShowDialog() | Out-Null
    return $script:setupOK
}

function Show-Main {

    [xml]$xaml = @'
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    Height="720" Width="920"
    WindowStartupLocation="CenterScreen"
    ResizeMode="CanResize"
    WindowStyle="None"
    AllowsTransparency="True"
    Background="Transparent"
    MinWidth="750" MinHeight="550">
  <Border CornerRadius="16" Background="#0F0F1A"
          BorderBrush="#2A2A4A" BorderThickness="1">
    <Border.Effect>
      <DropShadowEffect BlurRadius="40" ShadowDepth="0" Opacity="0.5"/>
    </Border.Effect>
    <Grid>
      <Grid.RowDefinitions>
        <RowDefinition Height="44"/>
        <RowDefinition Height="*"/>
      </Grid.RowDefinitions>

      <Border Grid.Row="0" Background="#12122A"
              CornerRadius="16,16,0,0" Name="dragBar">
        <Grid>
          <StackPanel Orientation="Horizontal"
                      Margin="16,0,0,0" VerticalAlignment="Center">
            <TextBlock Text="&#x26A1;" FontSize="16" Margin="0,0,8,0"/>
            <TextBlock Text="NativefierGUI"
                       Foreground="White" FontWeight="Bold" FontSize="13"/>
            <TextBlock Text="  v2.0"
                       Foreground="#555" FontSize="11" VerticalAlignment="Center"/>
          </StackPanel>
          <StackPanel Orientation="Horizontal"
                      HorizontalAlignment="Right" Margin="0,0,6,0">
            <Button Name="btnMin" Content="_"
                    Background="Transparent" Foreground="#888"
                    BorderThickness="0" Width="40" Height="40"
                    FontSize="16" Cursor="Hand"/>
            <Button Name="btnClose" Content="X"
                    Background="Transparent" Foreground="#888"
                    BorderThickness="0" Width="40" Height="40"
                    FontSize="13" Cursor="Hand"/>
          </StackPanel>
        </Grid>
      </Border>

      <Grid Grid.Row="1">
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="190"/>
          <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>

        <Border Grid.Column="0" Background="#12122A">
          <StackPanel Margin="8,20,8,8">
            <Button Name="t0" Content="  Build App"
                    Background="#1A1A3E" Foreground="White"
                    HorizontalContentAlignment="Left"
                    Padding="14,11" Margin="4,2"
                    BorderThickness="0" Cursor="Hand" FontSize="13"/>
            <Button Name="t1" Content="  Advanced"
                    Background="Transparent" Foreground="#8888AA"
                    HorizontalContentAlignment="Left"
                    Padding="14,11" Margin="4,2"
                    BorderThickness="0" Cursor="Hand" FontSize="13"/>
            <Button Name="t2" Content="  History"
                    Background="Transparent" Foreground="#8888AA"
                    HorizontalContentAlignment="Left"
                    Padding="14,11" Margin="4,2"
                    BorderThickness="0" Cursor="Hand" FontSize="13"/>
            <Button Name="t3" Content="  Settings"
                    Background="Transparent" Foreground="#8888AA"
                    HorizontalContentAlignment="Left"
                    Padding="14,11" Margin="4,2"
                    BorderThickness="0" Cursor="Hand" FontSize="13"/>
            <Button Name="t4" Content="  About"
                    Background="Transparent" Foreground="#8888AA"
                    HorizontalContentAlignment="Left"
                    Padding="14,11" Margin="4,2"
                    BorderThickness="0" Cursor="Hand" FontSize="13"/>
          </StackPanel>
        </Border>

        <ScrollViewer Grid.Column="1" VerticalScrollBarVisibility="Auto">
          <Grid Margin="30,24,30,24">

            <StackPanel Name="pg0">
              <TextBlock Text="Build Desktop App"
                         Foreground="White" FontSize="26" FontWeight="Bold"
                         Margin="0,0,0,4"/>
              <TextBlock Text="Enter a URL and configure your app below"
                         Foreground="#888" FontSize="13" Margin="0,0,0,26"/>

              <TextBlock Text="WEBSITE URL" Foreground="#888"
                         FontSize="11" FontWeight="Bold" Margin="0,0,0,6"/>
              <TextBox Name="txtUrl" Background="#16213E" Foreground="White"
                       FontSize="14" Padding="12,10"
                       BorderBrush="#2D2D5E" BorderThickness="1"
                       Margin="0,0,0,16" CaretBrush="White"/>

              <TextBlock Text="APP NAME" Foreground="#888"
                         FontSize="11" FontWeight="Bold" Margin="0,0,0,6"/>
              <TextBox Name="txtName" Background="#16213E" Foreground="White"
                       FontSize="14" Padding="12,10"
                       BorderBrush="#2D2D5E" BorderThickness="1"
                       Margin="0,0,0,16" CaretBrush="White"/>

              <TextBlock Text="ICON (optional .ico or .png)" Foreground="#888"
                         FontSize="11" FontWeight="Bold" Margin="0,0,0,6"/>
              <Grid Margin="0,0,0,16">
                <Grid.ColumnDefinitions>
                  <ColumnDefinition Width="*"/>
                  <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <TextBox Name="txtIcon" Background="#16213E" Foreground="White"
                         FontSize="14" Padding="12,10"
                         BorderBrush="#2D2D5E" BorderThickness="1"
                         CaretBrush="White"/>
                <Button Name="btnIco" Content="Browse" Grid.Column="1"
                        Background="#2D2D5E" Foreground="White"
                        Padding="16,10" BorderThickness="0"
                        Cursor="Hand" Margin="8,0,0,0" FontSize="13"/>
              </Grid>

              <TextBlock Text="OUTPUT FOLDER" Foreground="#888"
                         FontSize="11" FontWeight="Bold" Margin="0,0,0,6"/>
              <Grid Margin="0,0,0,24">
                <Grid.ColumnDefinitions>
                  <ColumnDefinition Width="*"/>
                  <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <TextBox Name="txtOut" Background="#16213E" Foreground="White"
                         FontSize="14" Padding="12,10"
                         BorderBrush="#2D2D5E" BorderThickness="1"
                         CaretBrush="White"/>
                <Button Name="btnOut" Content="Browse" Grid.Column="1"
                        Background="#2D2D5E" Foreground="White"
                        Padding="16,10" BorderThickness="0"
                        Cursor="Hand" Margin="8,0,0,0" FontSize="13"/>
              </Grid>

              <Button Name="btnBuild" Content="BUILD APP"
                      Background="#7C3AED" Foreground="White"
                      FontSize="16" FontWeight="Bold"
                      Padding="20,14" BorderThickness="0"
                      Cursor="Hand" Margin="0,0,0,20"/>

              <Border Name="logBox" Background="#1A1A2E" CornerRadius="10"
                      Padding="16" Visibility="Collapsed">
                <StackPanel>
                  <Grid Margin="0,0,0,8">
                    <TextBlock Text="BUILD OUTPUT" Foreground="#666"
                               FontSize="11" FontWeight="Bold"
                               VerticalAlignment="Center"/>
                    <Button Name="btnCopyLog" Content="Copy Log"
                            HorizontalAlignment="Right"
                            Background="#2D2D5E" Foreground="#AAA"
                            Padding="10,4" BorderThickness="0"
                            Cursor="Hand" FontSize="11"/>
                  </Grid>
                  <TextBox Name="txtLog" Background="Transparent"
                           Foreground="#10B981" FontFamily="Consolas"
                           FontSize="12" TextWrapping="Wrap"
                           IsReadOnly="True" BorderThickness="0"
                           MaxHeight="300" VerticalScrollBarVisibility="Auto"
                           AcceptsReturn="True"/>
                </StackPanel>
              </Border>
            </StackPanel>

            <StackPanel Name="pg1" Visibility="Collapsed">
              <TextBlock Text="Advanced Options"
                         Foreground="White" FontSize="26" FontWeight="Bold"
                         Margin="0,0,0,4"/>
              <TextBlock Text="Applied to your next build"
                         Foreground="#888" FontSize="13" Margin="0,0,0,26"/>

              <Border Background="#1A1A2E" CornerRadius="12"
                      Padding="20" Margin="0,0,0,16">
                <StackPanel>
                  <TextBlock Text="WINDOW SIZE" Foreground="#7C3AED"
                             FontSize="12" FontWeight="Bold" Margin="0,0,0,10"/>
                  <Grid Margin="0,0,0,8">
                    <Grid.ColumnDefinitions>
                      <ColumnDefinition Width="*"/>
                      <ColumnDefinition Width="16"/>
                      <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <StackPanel>
                      <TextBlock Text="WIDTH" Foreground="#888"
                                 FontSize="11" Margin="0,0,0,4"/>
                      <TextBox Name="txtW" Text="1280"
                               Background="#16213E" Foreground="White"
                               Padding="10,8" BorderBrush="#2D2D5E"
                               BorderThickness="1" CaretBrush="White"/>
                    </StackPanel>
                    <StackPanel Grid.Column="2">
                      <TextBlock Text="HEIGHT" Foreground="#888"
                                 FontSize="11" Margin="0,0,0,4"/>
                      <TextBox Name="txtH" Text="800"
                               Background="#16213E" Foreground="White"
                               Padding="10,8" BorderBrush="#2D2D5E"
                               BorderThickness="1" CaretBrush="White"/>
                    </StackPanel>
                  </Grid>
                  <CheckBox Name="chkMax" Content="Start Maximized"
                            Foreground="#AAA" FontSize="13"
                            Margin="0,6" Cursor="Hand"/>
                  <CheckBox Name="chkFull" Content="Start Fullscreen"
                            Foreground="#AAA" FontSize="13"
                            Margin="0,4" Cursor="Hand"/>
                </StackPanel>
              </Border>

              <Border Background="#1A1A2E" CornerRadius="12"
                      Padding="20" Margin="0,0,0,16">
                <StackPanel>
                  <TextBlock Text="BEHAVIOR" Foreground="#7C3AED"
                             FontSize="12" FontWeight="Bold" Margin="0,0,0,10"/>
                  <CheckBox Name="chkSingle" Content="Single Instance"
                            Foreground="#AAA" FontSize="13"
                            Margin="0,4" Cursor="Hand" IsChecked="True"/>
                  <CheckBox Name="chkTray" Content="Minimize to Tray"
                            Foreground="#AAA" FontSize="13"
                            Margin="0,4" Cursor="Hand"/>
                  <CheckBox Name="chkInsecure" Content="Ignore SSL Errors"
                            Foreground="#AAA" FontSize="13"
                            Margin="0,4" Cursor="Hand"/>
                  <CheckBox Name="chkNoCtx" Content="Disable Right-Click Menu"
                            Foreground="#AAA" FontSize="13"
                            Margin="0,4" Cursor="Hand"/>
                  <CheckBox Name="chkNoDev" Content="Disable DevTools"
                            Foreground="#AAA" FontSize="13"
                            Margin="0,4" Cursor="Hand"/>
                </StackPanel>
              </Border>

              <Border Background="#1A1A2E" CornerRadius="12" Padding="20">
                <StackPanel>
                  <TextBlock Text="CUSTOM USER AGENT" Foreground="#7C3AED"
                             FontSize="12" FontWeight="Bold" Margin="0,0,0,8"/>
                  <TextBox Name="txtUA" Background="#16213E" Foreground="White"
                           Padding="10,8" BorderBrush="#2D2D5E"
                           BorderThickness="1" CaretBrush="White"/>
                </StackPanel>
              </Border>
            </StackPanel>

            <StackPanel Name="pg2" Visibility="Collapsed">
              <TextBlock Text="Build History"
                         Foreground="White" FontSize="26" FontWeight="Bold"
                         Margin="0,0,0,20"/>
              <Border Background="#1A1A2E" CornerRadius="12"
                      Padding="20" Margin="0,0,0,12">
                <TextBox Name="txtHist" Background="Transparent"
                         Foreground="#AAA" FontFamily="Consolas" FontSize="12"
                         IsReadOnly="True" BorderThickness="0"
                         TextWrapping="Wrap" MinHeight="300"
                         AcceptsReturn="True"
                         VerticalScrollBarVisibility="Auto"/>
              </Border>
              <Button Name="btnClrH" Content="Clear History"
                      Background="#EF4444" Foreground="White"
                      Padding="18,10" BorderThickness="0"
                      Cursor="Hand" HorizontalAlignment="Left" FontSize="13"/>
            </StackPanel>

            <StackPanel Name="pg3" Visibility="Collapsed">
              <TextBlock Text="Settings"
                         Foreground="White" FontSize="26" FontWeight="Bold"
                         Margin="0,0,0,20"/>
              <Border Background="#1A1A2E" CornerRadius="12"
                      Padding="20" Margin="0,0,0,16">
                <StackPanel>
                  <TextBlock Name="lNode" Text="Node.js   : checking..."
                             Foreground="#AAA" FontSize="14"
                             FontFamily="Consolas" Margin="0,4"/>
                  <TextBlock Name="lNpm" Text="npm       : checking..."
                             Foreground="#AAA" FontSize="14"
                             FontFamily="Consolas" Margin="0,4"/>
                  <TextBlock Name="lNat" Text="Nativefier: checking..."
                             Foreground="#AAA" FontSize="14"
                             FontFamily="Consolas" Margin="0,4"/>
                </StackPanel>
              </Border>
              <StackPanel Orientation="Horizontal">
                <Button Name="btnUpd" Content="Update Nativefier"
                        Background="#7C3AED" Foreground="White"
                        Padding="18,10" BorderThickness="0"
                        Cursor="Hand" FontSize="13" Margin="0,0,10,0"/>
                <Button Name="btnOF" Content="Open Output Folder"
                        Background="#2D2D5E" Foreground="White"
                        Padding="18,10" BorderThickness="0"
                        Cursor="Hand" FontSize="13"/>
              </StackPanel>
            </StackPanel>

            <StackPanel Name="pg4" Visibility="Collapsed">
              <TextBlock Text="About"
                         Foreground="White" FontSize="26" FontWeight="Bold"
                         Margin="0,0,0,20"/>
              <Border Background="#1A1A2E" CornerRadius="12" Padding="24">
                <TextBlock Foreground="#AAA" FontSize="13"
                           TextWrapping="Wrap" LineHeight="22">
NativefierGUI wraps the Nativefier CLI in a modern WPF interface.

Nativefier converts any website into a standalone Electron desktop app.

Features:
  - Checks what is installed before doing anything
  - Auto-installs Node.js and Nativefier if missing
  - Custom icons, window sizes, tray mode
  - Build history tracking
  - Advanced Electron flags

github.com/nativefier/nativefier
                </TextBlock>
              </Border>
            </StackPanel>

          </Grid>
        </ScrollViewer>
      </Grid>
    </Grid>
  </Border>
</Window>
'@

    $mw = [Windows.Markup.XamlReader]::Load([Xml.XmlNodeReader]::new($xaml))

    $mw.FindName('dragBar').Add_MouseLeftButtonDown({ $mw.DragMove() })
    $mw.FindName('btnClose').Add_Click({ $mw.Close() })
    $mw.FindName('btnMin').Add_Click({ $mw.WindowState = 'Minimized' })

    $tabs  = 0..4 | ForEach-Object { $mw.FindName("t$_")  }
    $pages = 0..4 | ForEach-Object { $mw.FindName("pg$_") }

    $txtUrl  = $mw.FindName('txtUrl')
    $txtName = $mw.FindName('txtName')
    $txtIcon = $mw.FindName('txtIcon')
    $txtOut  = $mw.FindName('txtOut')
    $txtOut.Text = $script:outputDir

    $btnBuild = $mw.FindName('btnBuild')
    $logBox   = $mw.FindName('logBox')
    $txtLog   = $mw.FindName('txtLog')

    $txtW        = $mw.FindName('txtW')
    $txtH        = $mw.FindName('txtH')
    $chkMax      = $mw.FindName('chkMax')
    $chkFull     = $mw.FindName('chkFull')
    $chkSingle   = $mw.FindName('chkSingle')
    $chkTray     = $mw.FindName('chkTray')
    $chkInsecure = $mw.FindName('chkInsecure')
    $chkNoCtx    = $mw.FindName('chkNoCtx')
    $chkNoDev    = $mw.FindName('chkNoDev')
    $txtUA       = $mw.FindName('txtUA')
    $txtHist     = $mw.FindName('txtHist')
    $lNode       = $mw.FindName('lNode')
    $lNpm        = $mw.FindName('lNpm')
    $lNat        = $mw.FindName('lNat')

    $bc = [System.Windows.Media.BrushConverter]::new()

    $doTab = {
        param([int]$i)
        for ($j = 0; $j -lt 5; $j++) {
            $pages[$j].Visibility =
                if ($j -eq $i) { 'Visible' } else { 'Collapsed' }
            $tabs[$j].Background =
                if ($j -eq $i) { $bc.ConvertFrom('#1A1A3E') }
                else            { [System.Windows.Media.Brushes]::Transparent }
            $tabs[$j].Foreground =
                if ($j -eq $i) { [System.Windows.Media.Brushes]::White }
                else            { $bc.ConvertFrom('#8888AA') }
        }
    }

    $tabs[0].Add_Click({ & $doTab 0 })
    $tabs[1].Add_Click({ & $doTab 1 })

    $tabs[2].Add_Click({
        & $doTab 2
        $txtHist.Text =
            if (Test-Path $script:historyFile) {
                Get-Content $script:historyFile -Raw
            } else { 'No builds yet.' }
    })

    $tabs[3].Add_Click({
        & $doTab 3
        $state = Get-InstallState
        $lNode.Text = if ($state.NodeOK)       { "Node.js   : $($state.NodeVer)"       } else { 'Node.js   : NOT FOUND' }
        $lNpm.Text  = if ($state.NpmOK)        { "npm       : $($state.NpmVer)"        } else { 'npm       : NOT FOUND' }
        $lNat.Text  = if ($state.NativefierOK) { "Nativefier: $($state.NativefierVer)" } else { 'Nativefier: NOT FOUND' }
    })

    $tabs[4].Add_Click({ & $doTab 4 })

    $mw.FindName('btnIco').Add_Click({
        $d = [Microsoft.Win32.OpenFileDialog]::new()
        $d.Filter = 'Icons (*.ico;*.png)|*.ico;*.png|All files (*.*)|*.*'
        if ($d.ShowDialog()) { $txtIcon.Text = $d.FileName }
    })

    $mw.FindName('btnOut').Add_Click({
        $d = [System.Windows.Forms.FolderBrowserDialog]::new()
        $d.SelectedPath = $txtOut.Text
        if ($d.ShowDialog() -eq 'OK') { $txtOut.Text = $d.SelectedPath }
    })

    $mw.FindName('btnClrH').Add_Click({
        Remove-Item $script:historyFile -Force -ErrorAction SilentlyContinue
        $txtHist.Text = 'History cleared.'
    })

    $mw.FindName('btnCopyLog').Add_Click({
        if ($txtLog.Text) {
            [System.Windows.Clipboard]::SetText($txtLog.Text)
        }
    })

    $mw.FindName('btnUpd').Add_Click({
        $b = $mw.FindName('btnUpd')
        $b.Content   = 'Updating...'
        $b.IsEnabled = $false
        $mw.Dispatcher.Invoke([Action]{}, 'Background')
        Invoke-Cmd 'npm' @('update', '-g', 'nativefier') | Out-Null
        $b.Content   = 'Done!'
        $b.IsEnabled = $true
    })

    $mw.FindName('btnOF').Add_Click({
        $d = $txtOut.Text
        if (-not (Test-Path $d)) { New-Item $d -ItemType Directory -Force | Out-Null }
        Start-Process explorer.exe $d
    })

    $btnBuild.Add_Click({
        $url = $txtUrl.Text.Trim()
        if (-not $url) {
            [System.Windows.MessageBox]::Show(
                'Please enter a URL first.', 'Missing URL', 'OK', 'Warning')
            return
        }

        if ($url -notmatch '^https?://') { $url = "https://$url" }

        $out = $txtOut.Text.Trim()
        if (-not $out) { $out = $script:outputDir }
        if (-not (Test-Path $out)) {
            New-Item $out -ItemType Directory -Force | Out-Null
        }

        $logBox.Visibility  = 'Visible'
        $txtLog.Foreground  = $bc.ConvertFrom('#10B981')
        $txtLog.Text        = "Starting build...`r`n"
        $btnBuild.Content   = 'BUILDING...'
        $btnBuild.IsEnabled = $false
        $mw.Dispatcher.Invoke([Action]{}, 'Background')

        $buildArgs = [System.Collections.Generic.List[string]]::new()
        if ($script:useNpx) { $buildArgs.Add('nativefier') }

        $n = $txtName.Text.Trim()
        if ($n) {
            $buildArgs.Add('--name')
            $buildArgs.Add("`"$n`"")
        }

        $ic = $txtIcon.Text.Trim()
        if ($ic -and (Test-Path $ic)) {
            $buildArgs.Add('--icon')
            $buildArgs.Add("`"$ic`"")
        }

        $ww = $txtW.Text.Trim()
        $hh = $txtH.Text.Trim()
        if ($ww) { $buildArgs.Add('--width');  $buildArgs.Add($ww) }
        if ($hh) { $buildArgs.Add('--height'); $buildArgs.Add($hh) }

        if ($chkMax.IsChecked)      { $buildArgs.Add('--maximize')             }
        if ($chkFull.IsChecked)     { $buildArgs.Add('--full-screen')          }
        if ($chkSingle.IsChecked)   { $buildArgs.Add('--single-instance')      }
        if ($chkTray.IsChecked)     { $buildArgs.Add('--tray')                 }
        if ($chkInsecure.IsChecked) { $buildArgs.Add('--insecure')             }
        if ($chkNoCtx.IsChecked)    { $buildArgs.Add('--disable-context-menu') }
        if ($chkNoDev.IsChecked)    { $buildArgs.Add('--disable-dev-tools')    }

        $ua = $txtUA.Text.Trim()
        if ($ua) {
            $buildArgs.Add('--user-agent')
            $buildArgs.Add("`"$ua`"")
        }

        $buildArgs.Add("`"$url`"")
        $buildArgs.Add("`"$out`"")

        $exe     = if ($script:useNpx) { 'npx' } else { 'nativefier' }
        $fullCmd = "$exe " + ($buildArgs -join ' ')

        $txtLog.Text += "CMD: $fullCmd`r`n`r`n"
        $mw.Dispatcher.Invoke([Action]{}, 'Background')

        try {
            $pi                        = [Diagnostics.ProcessStartInfo]::new()
            $pi.FileName               = 'cmd.exe'
            $pi.Arguments              = "/c $fullCmd 2>&1"
            $pi.UseShellExecute        = $false
            $pi.RedirectStandardOutput = $true
            $pi.RedirectStandardError  = $true
            $pi.CreateNoWindow         = $true

            $pr = [Diagnostics.Process]::Start($pi)
            $so = $pr.StandardOutput.ReadToEnd()
            $se = $pr.StandardError.ReadToEnd()
            $pr.WaitForExit()

            $txtLog.Text += $so
            if ($se) { $txtLog.Text += "`r`n--- stderr ---`r`n$se" }

            if ($pr.ExitCode -eq 0) {
                $txtLog.Text += "`r`n`r`n===  BUILD SUCCESSFUL  ==="
                Add-Content $script:historyFile "[$(Get-Date -Format 'yyyy-MM-dd HH:mm')]  $url  |  $n"
            } else {
                $txtLog.Text      += "`r`n`r`n===  BUILD FAILED (exit $($pr.ExitCode))  ==="
                $txtLog.Foreground = $bc.ConvertFrom('#EF4444')
            }
        } catch {
            $txtLog.Text      += "`r`nERROR: $($_.Exception.Message)"
            $txtLog.Foreground = $bc.ConvertFrom('#EF4444')
        }

        $btnBuild.Content   = 'BUILD APP'
        $btnBuild.IsEnabled = $true
    })

    $mw.ShowDialog() | Out-Null
}

if (Show-Setup) {
    Show-Main
}