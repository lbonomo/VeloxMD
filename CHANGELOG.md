# Changelog

## 1.0.3 - 2026-08-24

### ⚡ Performance & Optimization
- **High-performance text parsing**: eliminated redundant memory allocations in `DocumentStats` and `TocEntry`.
- **Off-thread processing**: stats and Table of Contents calculation offloaded to isolates (`Isolate.run`) for large documents.
- **Instant search navigation**: prevented Markdown document AST re-parsing when navigating search matches.
- **Optimized CEF height polling**: reduced Chromium WebView polling overhead for Mermaid diagrams.

### 🐛 Bug Fixes
- **Code block zoom scaling**: fixed fenced code blocks (` ``` `) to scale dynamically with font size zoom shortcuts (`Ctrl++`, `Ctrl+-`, `Ctrl+0`).

## 1.0.2 - 2026-08-17

### ✨ Features
- **Dedicated search panel**: moved document search out of the AppBar into a
  side panel with query input, match count, next/previous navigation, and clear
  action. The search remains debounced and still highlights matches in the
  rendered document.
- **Mermaid diagram rendering**: ` ```mermaid ` fenced code blocks are now rendered
  as diagrams (flowchart, sequence, class, state, gantt, pie, etc.).
  - Rendered fully **offline** via a bundled Mermaid runtime inside an embedded
    Chromium view (`webview_cef`) — no network calls, no external services.
  - Follows the app's light/dark theme and resizes to fit the diagram.
  - Gracefully falls back to showing the raw diagram source if the Chromium
    engine is unavailable.

### 🔌 Offline
- **100% offline fonts**: removed the `google_fonts` dependency, which downloaded
  Inter and Fira Code at runtime on first use. The fonts are now bundled as local
  assets in `assets/fonts/` (Inter 400/600/700, Fira Code 400) with their SIL Open
  Font License, so typography is consistent and the app makes **no network requests**.
- Added an always-on Kiro steering rule (`.kiro/steering/offline.md`) documenting the
  offline requirement for future changes.

### ⌨️ Keyboard shortcuts
- **Configurable shortcuts**: key bindings (open file, reload, font size, quit,
  etc.) are no longer hardcoded. They're read from an XDG-compliant config file
  (`$XDG_CONFIG_HOME/veloxmd/keybindings.json`, `%APPDATA%\veloxmd\keybindings.json`
  on Windows), created with the previous defaults on first run and editable by hand.

### ⚡ Performance
- **Debounced search**: typing in the search box no longer re-parses and re-renders
  the whole document on every keystroke. The query is applied after a short pause
  (180 ms); pressing Enter flushes it immediately. Noticeably smoother on large files.

---

## 1.0.1 - 2026-08-17

### 🐛 Fixes
- Restored the table of contents, including empty-state display and improved ATX heading parsing.

---

## 0.4.5 - 2026-08-04

### 📦 Version Bump
- Patch version bump to 0.4.5

---

## 0.4.4 - 2026-08-04

### 📦 Version Bump
- Patch version bump to 0.4.4

---

## 0.4.3 - 2026-08-04

### 🔧 Build System
- Updated Android and Windows release workflows to work better with local `act` runs

---

## 0.4.2 - 2026-08-04

### ✨ Features
- **Android CI/CD Automation**: Added GitHub Actions workflow for automated Android builds
  - Automated APK (Android Package) build process
  - Automated AAB (Android App Bundle) build for Google Play Store
  - Multi-platform build configuration
  - Integrated GitHub Actions CI/CD pipeline

### 🔧 Build System
- Android Gradle build configuration
- Automated build triggers on releases
- Platform-specific build optimizations
- Continuous integration for mobile platform

### 📦 Deployment
- Ready for Google Play Store distribution
- APK distribution support
- Automated artifact generation

---

## 0.4.1 - 2026-08-04

### ✨ Features
- **Developer Information**: Added developer profile section to About dialog
  - Developer name: Lucas Bonomo
  - Website link: https://lucasbonomo.com
  - GitHub profile link: https://github.com/lbonomo
  - LinkedIn profile link: https://www.linkedin.com/in/lbonomo/
  - All links are clickable and open in default browser

### 🐛 Bug Fixes
- Fixed RenderFlex overflow in About dialog
- Added SingleChildScrollView for content scrolling
- Added maxHeight constraint for responsive design
- Prevents layout errors on smaller screens

### 📚 Content Updates
- Professional attribution to project creator
- Easy access to developer's professional profiles

---

## 0.4.0 - 2026-08-04

### ✨ Features
- **About Dialog**: Comprehensive project information dialog
  - Project goal and description
  - Complete feature list
  - Development stack details (Flutter, Dart, Material Design 3)
  - Getting started instructions
  - Quick access links to GitHub resources
  - License information (MIT)

### 🎨 UI Enhancements
- Added About button (info icon) in AppBar
- Modal dialog with responsive layout
- Clickable resource links (repository, issues, discussions)
- Full theme support (dark/light mode)

### 📚 Resources
- Direct access to GitHub repository
- Issue tracker link
- Community discussions link

---

## 0.3.0 - 2026-08-04

### ✨ Features
- **Document Footer**: Added a comprehensive footer bar displaying document statistics
  - Real-time statistics: words, lines, characters, headings, links, code blocks
  - **Token counter** using industry-standard OpenAI tokenization algorithm
  - Software version display
  - Automatic update on file reload/change
  - Footer only visible when a document is open

### 🔢 Token Calculation
- Implemented hybrid token estimation algorithm based on OpenAI's standard
- Formula: Average of character-based (1 token ≈ 4 chars) and word-based (1 token ≈ 0.75 words) methods
- Useful for estimating costs in LLM APIs

### 📊 Document Statistics
- Words count
- Lines count
- Total characters
- Heading count
- External links count
- Code blocks count

---

## 0.2.0 - 2026-07-30

- Minor version bump from 0.1.1 to 0.2.0.
- Aligned Linux CMake project version with pubspec version.
