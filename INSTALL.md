# Installation Guide

## Quick Install

### Linux & macOS

**One-line installation:**

```bash
curl -fsSL https://raw.githubusercontent.com/HPNChanel/hpn-tunnel-public/main/install.sh | bash
```

Or download and run manually:

```bash
wget https://raw.githubusercontent.com/HPNChanel/hpn-tunnel-public/main/install.sh
chmod +x install.sh
./install.sh
```

The script will:
- ✅ Auto-detect your OS (Linux/macOS) and architecture (Intel/Apple Silicon)
- ✅ Download the latest release from GitHub
- ✅ Install to `/usr/local/bin/hpn`
- ✅ Make it executable
- ✅ Show progress indicators

### Windows

**PowerShell one-liner (Run as Administrator):**

```powershell
iwr -useb "https://api.github.com/repos/HPNChanel/hpn-tunnel-public/releases/latest" | % { $v=$_.Content|ConvertFrom-Json|% tag_name; $a=if([Environment]::Is64BitOperatingSystem){'amd64'}else{'386'}; iwr "https://github.com/HPNChanel/hpn-tunnel-public/releases/download/$v/hpn-tunnel_${v}_windows_$a.zip" -OutFile "$env:TEMP\hpn.zip"; Expand-Archive -Force "$env:TEMP\hpn.zip" "$env:TEMP\hpn"; Move-Item -Force "$env:TEMP\hpn\hpn.exe" "$env:ProgramFiles\hpn.exe"; [Environment]::SetEnvironmentVariable('Path',$env:Path+";$env:ProgramFiles",[EnvironmentVariableTarget]::Machine); Write-Host "✨ HPN Tunnel is ready! Run 'hpn help' to start." -ForegroundColor Green }
```

**Alternative (Manual):**

1. Download the latest Windows release from [GitHub Releases](https://github.com/HPNChanel/hpn-tunnel-public/releases/latest)
2. Extract `hpn.exe`
3. Move to a directory in your PATH (e.g., `C:\Program Files\`)
4. Run `hpn help`

## Verify Installation

After installation, verify by running:

```bash
hpn help
```

You should see the HPN Tunnel command help information.

## Updating

To update to the latest version, simply re-run the installation script:

```bash
curl -fsSL https://raw.githubusercontent.com/HPNChanel/hpn-tunnel-public/main/install.sh | bash
```

## Uninstall

### Linux & macOS
```bash
sudo rm /usr/local/bin/hpn
```

### Windows
```powershell
Remove-Item "$env:ProgramFiles\hpn.exe"
```

## Manual Installation

You can also download pre-built binaries directly from the [Releases page](https://github.com/HPNChanel/hpn-tunnel-public/releases/latest).

Available platforms:
- `hpn-tunnel_*_linux_amd64.tar.gz` - Linux (Intel/AMD)
- `hpn-tunnel_*_linux_arm64.tar.gz` - Linux (ARM)
- `hpn-tunnel_*_darwin_amd64.tar.gz` - macOS (Intel)
- `hpn-tunnel_*_darwin_arm64.tar.gz` - macOS (Apple Silicon)
- `hpn-tunnel_*_windows_amd64.zip` - Windows (64-bit)
- `hpn-tunnel_*_windows_386.zip` - Windows (32-bit)
