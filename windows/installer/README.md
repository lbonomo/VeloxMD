# Windows Installer Build

This directory contains the configuration for building Windows installers for VeloxMD using Inno Setup.

## Overview

The Windows installer is automatically built and published as a release asset whenever a new GitHub release is published. The process is managed by the GitHub Actions workflow at `.github/workflows/build-windows.yml`.

## Files

- `veloxmd.iss` - Inno Setup script that defines the installer configuration

## How It Works

### Automated Build (GitHub Actions)

When you publish a new release on GitHub:

1. The `build-windows` workflow is triggered
2. Flutter builds the Windows release binary
3. Inno Setup creates an installer executable
4. The installer is uploaded as a release asset

### Local Build (Manual)

To build the installer locally on Windows:

1. **Prerequisites:**
   - Flutter SDK installed and configured
   - Inno Setup 6 installed
   - ISCC.exe available in PATH or at `C:\Program Files (x86)\Inno Setup 6\`

2. **Build Flutter Release:**
   ```bash
   flutter build windows --release
   ```

3. **Build Installer:**
   ```powershell
   $iscc = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
   & $iscc `
     "/DMyAppVersion=0.4.1" `
     "/DMyOutputBaseFilename=veloxmd-setup-windows-x64-v0.4.1" `
     "/DMySourceDir=.\build\windows\x64\runner\Release" `
     "windows/installer/veloxmd.iss"
   ```

4. **Output:**
   - Installer will be created at: `build/windows/installer/veloxmd-setup-windows-x64-v{version}.exe`

## Inno Setup Configuration

The `veloxmd.iss` script includes:

- **Application Info:**
  - Name: VeloxMD
  - Publisher: Lucas Bonomo
  - Repository: https://github.com/lbonomo/VeloxMD

- **Installation:**
  - Default directory: `Program Files\VeloxMD`
  - Creates Start Menu shortcuts
  - Optional desktop shortcut
  - English and Spanish language support

- **Features:**
  - 64-bit architecture
  - License file included
  - Uninstaller support
  - Auto-launch after installation

## Customization

To customize the installer:

1. Edit `veloxmd.iss` to change:
   - Application name, icon, or directories
   - Languages supported
   - Installation options
   - License file path

2. Version is automatically injected via `/DMyAppVersion` parameter from the git tag

3. Source directory is injected via `/DMySourceDir` parameter

## Release Process

To publish a new Windows installer:

1. **Create a new release on GitHub:**
   ```bash
   git tag -a v0.4.2 -m "Release v0.4.2"
   git push origin v0.4.2
   gh release create v0.4.2
   ```

2. **The workflow automatically:**
   - Builds the Windows binary
   - Creates the installer
   - Uploads it as a release asset

3. **Download:**
   - Users can download the installer from the GitHub Releases page
   - File: `veloxmd-setup-windows-x64-v{version}.exe`

## Troubleshooting

### ISCC.exe not found
- Ensure Inno Setup 6 is installed
- Check installation path matches the script
- Add to PATH environment variable

### Build fails
- Verify Flutter is installed: `flutter doctor`
- Check Windows requirements are met
- Ensure you're in the project root directory

### Installer not created
- Check build output directory: `build/windows/x64/runner/Release`
- Verify all source files are present
- Run ISCC manually to see detailed error messages

## References

- [Inno Setup Documentation](https://jrsoftware.org/isinfo.php)
- [Flutter Windows Desktop Docs](https://docs.flutter.dev/deployment/windows)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
