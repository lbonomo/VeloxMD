# Changelog

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
