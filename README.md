# VeloxMD

A **fast** Markdown viewer built with Flutter, focused on the Linux desktop experience.

## Features

- ⚡ Instant rendering of `.md`, `.markdown`, and `.txt` files
- 🖥️ Native Linux desktop window (GTK, wayland/X11)
- 📂 Open files via the toolbar, keyboard shortcut, drag-and-drop, or command-line argument
- 📑 Auto-generated Table of Contents panel (toggle with **Ctrl+T**)
- 🔄 Live reload – the file is watched for changes and the view updates automatically
- 🌙 Dark / Light theme toggle (preference is persisted)
- 🔗 Clickable hyperlinks (opens in system browser)
- 💻 GitHub-Flavoured Markdown (tables, strikethrough, task lists, emoji)
- 📈 Mermaid diagrams – ` ```mermaid ` blocks render as diagrams, fully offline
- 🖱️ Fully selectable rendered text
- 📊 Document statistics (words, lines, characters, tokens, etc.)
- 👨‍💻 About section with developer information and links

## Keyboard shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+O` | Open file |
| `Ctrl+T` | Toggle Table of Contents |
| `Ctrl+R` / `F5` | Reload current file |
| `Ctrl+Q` | Quit |

## Build & run

### Linux (Primary Platform)

#### Prerequisites

- Flutter SDK ≥ 3.27 with Linux desktop support enabled
- GTK 3 development libraries (`libgtk-3-dev` on Debian/Ubuntu)
- A C++20 toolchain and CMake/Ninja (`clang`, `cmake`, `ninja-build`, `pkg-config`)
  — required by the embedded Chromium engine used for Mermaid diagrams

> ℹ️ The **first** Linux build downloads the Chromium Embedded Framework
> (CEF, ~330 MB) into `linux/flutter/.../third/cef` and compiles it, so the
> initial build takes noticeably longer. Subsequent builds are fast.

#### Commands

```bash
# Enable Linux desktop target (once)
flutter config --enable-linux-desktop

# Fetch dependencies
flutter pub get

# Run in debug mode
flutter run -d linux

# Build a release binary
flutter build linux --release
# Output: build/linux/x64/release/bundle/veloxmd

# Open a specific file from the terminal
./veloxmd path/to/document.md
```

### Windows

#### Build Locally

```bash
# Build Windows release binary
flutter build windows --release

# Build installer with Inno Setup (requires Inno Setup 6 installed)
# See: windows/installer/README.md for detailed instructions
```

#### Automated Build

Windows installers are automatically built and published as release assets when you create a GitHub release. See `.github/workflows/build-windows.yml` for details.

#### Download

Download the latest Windows installer from the [Releases page](https://github.com/lbonomo/VeloxMD/releases):
- File: `veloxmd-setup-windows-x64-v{version}.exe`

### Running tests

```bash
flutter test
```

## Project structure

```
lib/
├── main.dart                – entry point, window manager initialisation
├── app.dart                 – MaterialApp, theme management
├── screens/
│   └── viewer_screen.dart   – main UI: toolbar, drag-drop, keyboard shortcuts
├── widgets/
│   ├── markdown_viewer.dart – flutter_markdown widget with custom styling
│   ├── mermaid_view.dart    – offline Mermaid diagram renderer (webview_cef)
│   ├── toc_panel.dart       – Table of Contents side panel
│   ├── document_footer.dart – Document statistics footer with token counter
│   └── dialogs/
│       └── about_dialog.dart – About dialog with project and developer info
├── models/
│   ├── toc_entry.dart       – heading model + Markdown parser
│   └── document_stats.dart  – Document statistics and token calculation
└── services/
    └── file_service.dart    – async file reading with validation
```

## Desktop integration

A `.desktop` file is provided at
`linux/runner/resources/veloxmd.desktop` so the app can be registered as a
handler for `text/markdown` files in any XDG-compliant desktop environment:

```bash
cp linux/runner/resources/veloxmd.desktop ~/.local/share/applications/
update-desktop-database ~/.local/share/applications/
```

## Windows Installer

See [windows/installer/README.md](windows/installer/README.md) for:
- Automated Windows installer build via GitHub Actions
- Manual local build instructions
- Customization and troubleshooting guides


