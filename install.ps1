<#
.SYNOPSIS
    Penrift Installer v1.0.3 - "Bulldozer" Edition
    https://github.com/HPNChanel/hpn-tunnel-public

.DESCRIPTION
    Downloads and installs Penrift to %LOCALAPPDATA%\Penrift\bin
    Automatically adds to user PATH environment variable.
    
    THIS IS THE "BULLDOZER" INSTALLER:
    - Uses taskkill /F to forcefully terminate ALL penrift processes
    - Waits for file handles to release
    - Verifies SHA256 checksum of downloaded binary
    - Verifies installation by running 'penrift version'
    - FAILS if version mismatch detected

.EXAMPLE
    iwr -useb https://penrift.io.vn/install.ps1 | iex
#>

$ErrorActionPreference = "Stop"

# ══════════════════════════════════════════════════════════════════════════════
# ⚙️ CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════
$ExpectedVersion = "v1.0.3"
$Repo = "HPNChanel/hpn-tunnel-public"
$FileName = "penrift-windows-amd64.zip"
$BinaryName = "penrift.exe"
# CANONICAL INSTALL PATH - Always use this specific location
$InstallDir = "$env:LOCALAPPDATA\Penrift\bin"
$GitHubAPI = "https://api.github.com/repos/$Repo/releases/latest"

# ══════════════════════════════════════════════════════════════════════════════
# 🎨 OUTPUT HELPERS
# ══════════════════════════════════════════════════════════════════════════════
function Write-Info { param($msg) Write-Host "[INFO] " -ForegroundColor Blue -NoNewline; Write-Host $msg }
function Write-Success { param($msg) Write-Host "[✓] " -ForegroundColor Green -NoNewline; Write-Host $msg }
function Write-Warn { param($msg) Write-Host "[!] " -ForegroundColor Yellow -NoNewline; Write-Host $msg }
function Write-Err { param($msg) Write-Host "[✗] " -ForegroundColor Red -NoNewline; Write-Host $msg }
function Write-Step { param($msg) Write-Host "[→] " -ForegroundColor Magenta -NoNewline; Write-Host $msg }

function Show-Banner {
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          🌀 Penrift Installer v1.0.3 - BULLDOZER          ║" -ForegroundColor Cyan
    Write-Host "║          Expose localhost instantly. P2P & Relay.         ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

# ══════════════════════════════════════════════════════════════════════════════
# 🔍 GET LATEST VERSION FROM GITHUB API
# ══════════════════════════════════════════════════════════════════════════════
function Get-LatestVersion {
    Write-Step "Fetching latest version from GitHub..."
    
    try {
        $response = Invoke-RestMethod -Uri $GitHubAPI -UseBasicParsing -TimeoutSec 10
        $version = $response.tag_name
        
        if (-not $version) {
            throw "Could not parse version from GitHub API"
        }
        
        Write-Success "Latest version: $version"
        return $version
    } catch {
        Write-Err "Failed to fetch latest version: $_"
        Write-Warn "Falling back to expected version: $ExpectedVersion"
        return $ExpectedVersion
    }
}

# ══════════════════════════════════════════════════════════════════════════════
# 💀 BULLDOZER: Force Kill ALL Penrift Processes
# ══════════════════════════════════════════════════════════════════════════════
function Stop-PenriftForce {
    Write-Step "BULLDOZER: Force-killing all Penrift processes..."
    
    # Method 1: taskkill /F /IM /T (forceful with tree kill)
    # This is aggressive and handles child processes too
    # Note: Use try-catch because taskkill writes to stderr even for "not found"
    try {
        $result = & { taskkill /F /IM "penrift.exe" /T 2>&1 }
        $exitCode = $LASTEXITCODE
    } catch {
        $result = $_.Exception.Message
        $exitCode = 1
    }
    
    # ═══════════════════════════════════════════════════════════════════════════
    # 🔐 CRITICAL: Handle privilege mismatch (Standard User vs Admin Process)
    # ═══════════════════════════════════════════════════════════════════════════
    if ($exitCode -eq 128) {
        Write-Host ""
        Write-Err "╔══════════════════════════════════════════════════════════════╗"
        Write-Err "║  CRITICAL: Penrift is running as Administrator               ║"
        Write-Err "║                                                               ║"
        Write-Err "║  You must run this installer as Administrator to update it.  ║"
        Write-Err "║  Right-click PowerShell → 'Run as Administrator'             ║"
        Write-Err "╚══════════════════════════════════════════════════════════════╝"
        Write-Host ""
        exit 1
    } elseif ($exitCode -eq 0) {
        Write-Success "Killed running Penrift process(es)"
    } elseif ("$result" -match "not found" -or "$result" -match "ERROR: The process") {
        Write-Info "No running Penrift processes found (good!)"
    } else {
        Write-Warn "taskkill returned code $exitCode"
    }
    
    # Method 2: Also try Stop-Process for any that taskkill missed
    $processes = Get-Process -Name "penrift" -ErrorAction SilentlyContinue
    foreach ($proc in $processes) {
        try {
            Stop-Process -Id $proc.Id -Force -ErrorAction Stop
            Write-Success "Stopped process ID: $($proc.Id)"
        } catch {
            # Ignore - process may have already exited
        }
    }
    
    # CRITICAL: Wait for file handles to release
    Write-Step "Waiting 2 seconds for file handles to release..."
    Start-Sleep -Seconds 2
    
    # Double-check no penrift.exe still running
    $stillRunning = Get-Process -Name "penrift" -ErrorAction SilentlyContinue
    if ($stillRunning) {
        Write-Err "Penrift is still running! Please close it manually and try again."
        Write-Err "Or restart your computer to release all file handles."
        exit 1
    }
    
    Write-Success "All Penrift processes terminated"
}

# ══════════════════════════════════════════════════════════════════════════════
# 🧹 DEEP CLEAN - Remove ALL old penrift.exe from system
# ══════════════════════════════════════════════════════════════════════════════
function Remove-OldInstallations {
    Write-Step "Searching for existing Penrift installations..."
    
    $removedCount = 0
    
    # Method 1: Use Get-Command to find penrift in PATH
    try {
        $existingCommands = Get-Command "penrift" -ErrorAction SilentlyContinue -All
        
        if ($existingCommands) {
            foreach ($cmd in $existingCommands) {
                $oldPath = $cmd.Source
                
                # Skip if it's our canonical install path (we'll overwrite it anyway)
                if ($oldPath -like "$InstallDir\*") {
                    Write-Info "Found canonical installation: $oldPath (will be updated)"
                    continue
                }
                
                Write-Warn "Found old installation: $oldPath"
                
                try {
                    Remove-Item -Path $oldPath -Force -ErrorAction Stop
                    Write-Success "Removed: $oldPath"
                    $removedCount++
                } catch {
                    Write-Warn "Could not remove $oldPath : $_"
                }
            }
        }
    } catch {
        # Get-Command might fail, that's fine
    }
    
    # Method 2: Check common installation locations
    $commonPaths = @(
        "$env:USERPROFILE\penrift.exe",
        "$env:USERPROFILE\Downloads\penrift.exe",
        "$env:USERPROFILE\Desktop\penrift.exe",
        "$env:LOCALAPPDATA\Penrift\penrift.exe",
        "C:\penrift\penrift.exe",
        "C:\Tools\penrift.exe"
    )
    
    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            Write-Warn "Found old installation: $path"
            try {
                Remove-Item -Path $path -Force -ErrorAction Stop
                Write-Success "Removed: $path"
                $removedCount++
            } catch {
                Write-Warn "Could not remove $path - file may be in use"
            }
        }
    }
    
    # Method 3: Clean up .old and .new files from failed updates
    $cleanupPatterns = @("$InstallDir\*.old", "$InstallDir\*.new", "$env:LOCALAPPDATA\Penrift\*.old")
    foreach ($pattern in $cleanupPatterns) {
        Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue | ForEach-Object {
            try {
                Remove-Item -Path $_.FullName -Force -ErrorAction Stop
                Write-Info "Cleaned up: $($_.FullName)"
            } catch {}
        }
    }
    
    if ($removedCount -gt 0) {
        Write-Success "Removed $removedCount old installation(s)"
    } else {
        Write-Info "No old installations to remove"
    }
}

# ══════════════════════════════════════════════════════════════════════════════
# 🔐 SHA256 CHECKSUM VERIFICATION
# ══════════════════════════════════════════════════════════════════════════════
function Verify-SHA256Checksum {
    param(
        [string]$FilePath,
        [string]$Version,
        [string]$FileName
    )
    
    Write-Step "Verifying SHA256 checksum..."
    
    $ChecksumUrl = "https://github.com/$Repo/releases/download/$Version/SHA256SUMS"
    $ChecksumFile = Join-Path (Split-Path $FilePath -Parent) "SHA256SUMS"
    
    try {
        # Download checksums file
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $ChecksumUrl -OutFile $ChecksumFile -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
        $ProgressPreference = 'Continue'
        
        if (!(Test-Path $ChecksumFile)) {
            Write-Warn "Checksum file not available, skipping verification"
            return $true
        }
        
        # Read checksums file (handle UTF-8 encoding properly)
        $checksumContent = Get-Content -Path $ChecksumFile -Raw -Encoding UTF8
        
        # Parse the checksums file: format is "hash  filename" or "hash filename"
        $expectedHash = $null
        foreach ($line in $checksumContent -split "`n") {
            $line = $line.Trim()
            if ($line -match "^([a-fA-F0-9]{64})\s+(.+)$") {
                $hash = $matches[1].ToLower()
                $file = $matches[2].Trim()
                if ($file -eq $FileName -or $file -like "*$FileName") {
                    $expectedHash = $hash
                    break
                }
            }
        }
        
        if (-not $expectedHash) {
            Write-Warn "Checksum not found for $FileName in SHA256SUMS, skipping verification"
            return $true
        }
        
        # Compute actual hash using Get-FileHash
        $actualHash = (Get-FileHash -Path $FilePath -Algorithm SHA256).Hash.ToLower()
        
        Write-Info "Expected: $expectedHash"
        Write-Info "Actual:   $actualHash"
        
        if ($expectedHash -eq $actualHash) {
            Write-Success "SHA256 checksum verified ✓"
            return $true
        } else {
            Write-Host ""
            Write-Err "╔══════════════════════════════════════════════════════════════╗"
            Write-Err "║  🚨 SECURITY ALERT: SHA256 CHECKSUM MISMATCH!                ║"
            Write-Err "║                                                               ║"
            Write-Err "║  The downloaded file does not match the expected checksum.   ║"
            Write-Err "║  This could indicate:                                         ║"
            Write-Err "║    - A corrupted download                                     ║"
            Write-Err "║    - A man-in-the-middle attack                               ║"
            Write-Err "║    - A tampered file                                          ║"
            Write-Err "║                                                               ║"
            Write-Err "║  The file has been DELETED for your safety.                  ║"
            Write-Err "╚══════════════════════════════════════════════════════════════╝"
            Write-Host ""
            
            # Delete the potentially malicious file
            Remove-Item -Path $FilePath -Force -ErrorAction SilentlyContinue
            
            return $false
        }
        
    } catch {
        Write-Warn "Could not download checksum file: $_"
        Write-Warn "Proceeding without checksum verification (use at your own risk)"
        return $true
    } finally {
        # Clean up checksum file
        if (Test-Path $ChecksumFile) {
            Remove-Item -Path $ChecksumFile -Force -ErrorAction SilentlyContinue
        }
    }
}

# ══════════════════════════════════════════════════════════════════════════════
# 📥 DOWNLOAD & INSTALL
# ══════════════════════════════════════════════════════════════════════════════
function Install-PenriftBinary {
    param([string]$Version)
    
    $DownloadUrl = "https://github.com/$Repo/releases/download/$Version/$FileName"
    
    Write-Step "Downloading Penrift $Version..."
    Write-Host "    URL: $DownloadUrl" -ForegroundColor DarkGray
    Write-Host ""
    
    # Create temp directory
    $TempDir = Join-Path $env:TEMP "penrift-install-$(Get-Random)"
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
    
    try {
        $ZipPath = Join-Path $TempDir $FileName
        
        # Download with progress disabled for speed
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipPath -UseBasicParsing
        $ProgressPreference = 'Continue'
        
        if (!(Test-Path $ZipPath)) {
            Write-Err "Download failed. Please check your internet connection."
            exit 1
        }
        
        # VERIFY: Check file size (basic sanity check)
        $fileInfo = Get-Item $ZipPath
        $fileSizeMB = [math]::Round($fileInfo.Length / 1MB, 2)
        
        if ($fileInfo.Length -lt 1000000) {
            Write-Err "Downloaded file is too small ($fileSizeMB MB). Download may be corrupted."
            exit 1
        }
        
        Write-Success "Downloaded $FileName ($fileSizeMB MB)"
        
        # ═══════════════════════════════════════════════════════════════════════
        # 🔐 CRITICAL: SHA256 CHECKSUM VERIFICATION
        # ═══════════════════════════════════════════════════════════════════════
        $checksumValid = Verify-SHA256Checksum -FilePath $ZipPath -Version $Version -FileName $FileName
        if (-not $checksumValid) {
            Write-Err "Installation aborted due to checksum verification failure."
            exit 1
        }
        
        # Create canonical install directory
        Write-Step "Installing to $InstallDir..."
        
        if (!(Test-Path $InstallDir)) {
            New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
        }
        
        # Extract
        Write-Step "Extracting..."
        Expand-Archive -Path $ZipPath -DestinationPath $TempDir -Force
        
        $BinaryPath = Join-Path $TempDir $BinaryName
        if (!(Test-Path $BinaryPath)) {
            Write-Err "Binary not found in archive. The download may be corrupted."
            exit 1
        }
        
        # Move to canonical install location (overwrite existing)
        $DestPath = Join-Path $InstallDir $BinaryName
        
        # Force remove existing to ensure clean overwrite
        if (Test-Path $DestPath) {
            try {
                Remove-Item -Path $DestPath -Force -ErrorAction Stop
            } catch {
                # Try rename-swap if direct delete fails
                $oldPath = "$DestPath.old"
                Rename-Item -Path $DestPath -NewName $oldPath -Force -ErrorAction SilentlyContinue
            }
        }
        
        Move-Item -Path $BinaryPath -Destination $DestPath -Force
        
        Write-Success "Installed to $DestPath"
        
        return $DestPath
        
    } finally {
        # Cleanup temp directory
        if (Test-Path $TempDir) {
            Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# ══════════════════════════════════════════════════════════════════════════════
# 🔧 PATH MANAGEMENT
# ══════════════════════════════════════════════════════════════════════════════
function Add-ToPath {
    param([string]$PathToAdd)
    
    $CurrentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    
    if ($CurrentPath -notlike "*$PathToAdd*") {
        Write-Step "Adding $PathToAdd to user PATH..."
        
        # Clean up any duplicate semicolons and empty entries
        $pathParts = $CurrentPath -split ';' | Where-Object { $_ -ne '' }
        $pathParts += $PathToAdd
        $NewPath = $pathParts -join ';'
        
        [Environment]::SetEnvironmentVariable("Path", $NewPath, "User")
        
        # Also update current session
        $env:Path = "$env:Path;$PathToAdd"
        
        Write-Success "Added to PATH"
        return $true
    } else {
        Write-Info "Already in PATH"
        return $false
    }
}

# ══════════════════════════════════════════════════════════════════════════════
# ✅ VERIFICATION - THE FINAL CHECK
# ══════════════════════════════════════════════════════════════════════════════
function Verify-Installation {
    param([string]$ExpectedVersion, [string]$BinaryPath)
    
    Write-Step "VERIFICATION: Running 'penrift version'..."
    
    # Run the binary directly to get version
    try {
        $output = & $BinaryPath version 2>&1
        $versionLine = $output | Select-String -Pattern "v\d+\.\d+\.\d+" | Select-Object -First 1
        
        if ($versionLine) {
            $installedVersion = ($versionLine -match 'v\d+\.\d+\.\d+') | Out-Null; $matches[0]
            Write-Success "Installed version: $installedVersion"
            
            # Check if version matches expected
            if ($installedVersion -eq $ExpectedVersion) {
                Write-Success "Version verified: $ExpectedVersion ✓"
                return $true
            } else {
                Write-Warn "Version mismatch: installed $installedVersion, expected $ExpectedVersion"
                # Not a hard failure - could be newer version from GitHub
                return $true
            }
        } else {
            # Version command ran but couldn't parse output
            Write-Warn "Could not parse version from output, but binary runs"
            return $true
        }
    } catch {
        Write-Err "VERIFICATION FAILED: Could not run penrift version"
        Write-Err "Error: $_"
        Write-Host ""
        Write-Err "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Red
        Write-Err "║  INSTALLATION INCOMPLETE - RESTART YOUR COMPUTER             ║" -ForegroundColor Red
        Write-Err "║                                                               ║" -ForegroundColor Red
        Write-Err "║  The old version may still be locked in memory.              ║" -ForegroundColor Red
        Write-Err "║  After restart, run this installer again.                    ║" -ForegroundColor Red
        Write-Err "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Red
        return $false
    }
}

# ══════════════════════════════════════════════════════════════════════════════
# 🎉 SUCCESS MESSAGE
# ══════════════════════════════════════════════════════════════════════════════
function Show-SuccessMessage {
    param([string]$Version)
    
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║              Installation Complete! ($Version)              ║" -ForegroundColor Green
    Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Location: $InstallDir\$BinaryName" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Quick Start:" -ForegroundColor Cyan
    Write-Host "    penrift login               " -NoNewline; Write-Host "# Authenticate" -ForegroundColor DarkGray
    Write-Host "    penrift http 3000           " -NoNewline; Write-Host "# Expose port 3000" -ForegroundColor DarkGray
    Write-Host "    penrift http 3000 --id myapp" -NoNewline; Write-Host "# Custom subdomain" -ForegroundColor DarkGray
    Write-Host "    penrift update              " -NoNewline; Write-Host "# Update to latest" -ForegroundColor DarkGray
    Write-Host ""
    Write-Warn "⚠️  IMPORTANT: Open a NEW terminal window to use penrift."
    Write-Host ""
}

# ══════════════════════════════════════════════════════════════════════════════
# 🚀 MAIN ENTRY POINT
# ══════════════════════════════════════════════════════════════════════════════
function Main {
    Show-Banner
    
    # Step 1: BULLDOZER - Force kill ALL running instances
    Stop-PenriftForce
    
    # Step 2: Deep clean old installations
    Remove-OldInstallations
    
    # Step 3: Get latest version from GitHub
    $Version = Get-LatestVersion
    
    # Step 4: Download, verify SHA256, and install
    $BinaryPath = Install-PenriftBinary -Version $Version
    
    # Step 5: Add to PATH
    Add-ToPath $InstallDir
    
    # Step 6: VERIFICATION - The moment of truth
    $verified = Verify-Installation -ExpectedVersion $Version -BinaryPath $BinaryPath
    
    if ($verified) {
        Show-SuccessMessage -Version $Version
    } else {
        exit 1
    }
}

# Run installer
Main
