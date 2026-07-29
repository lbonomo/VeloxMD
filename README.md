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
- 🖱️ Fully selectable rendered text

## Keyboard shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+O` | Open file |
| `Ctrl+T` | Toggle Table of Contents |
| `Ctrl+R` / `F5` | Reload current file |
| `Ctrl+Q` | Quit |

## Build & run

### Prerequisites

- Flutter SDK ≥ 3.10 with Linux desktop support enabled
- GTK 3 development libraries (`libgtk-3-dev` on Debian/Ubuntu)

### Commands

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

### Running tests

```bash
flutter test
```

## Project structure

```
lib/
├── main.dart              – entry point, window manager initialisation
├── app.dart               – MaterialApp, theme management
├── screens/
│   └── viewer_screen.dart – main UI: toolbar, drag-drop, keyboard shortcuts
├── widgets/
│   ├── markdown_viewer.dart – flutter_markdown widget with custom styling
│   └── toc_panel.dart       – Table of Contents side panel
├── models/
│   └── toc_entry.dart     – heading model + Markdown parser
└── services/
    └── file_service.dart  – async file reading with validation
```

## Desktop integration

A `.desktop` file is provided at
`linux/runner/resources/veloxmd.desktop` so the app can be registered as a
handler for `text/markdown` files in any XDG-compliant desktop environment:

```bash
cp linux/runner/resources/veloxmd.desktop ~/.local/share/applications/
update-desktop-database ~/.local/share/applications/
```
