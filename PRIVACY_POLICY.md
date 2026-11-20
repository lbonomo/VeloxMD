# Privacy Policy for VeloxMD

**Last updated:** November 20, 2026  
**Developer:** Lucas Bonomo  
**Repository:** https://github.com/lbonomo/VeloxMD  
**Web version:** https://lbonomo.github.io/VeloxMD/privacy.html

## Overview

VeloxMD is an open-source, offline-first desktop Markdown viewer. **VeloxMD does not collect, store, sell, or transmit personal data, usage analytics, crash reports, or telemetry.**

## Local Files and Preferences

* **Documents:** Markdown, `.mdc`, and plain text files opened in VeloxMD are read locally on your device and are never uploaded or sent to any remote server.
* **Configuration & Preferences:** User preferences (such as theme selection, font scale, OpenDyslexic font toggle, and custom `keybindings.json` / `fonts.json` settings) are stored strictly locally on your device.

## Network Access

VeloxMD operates offline by default. Network requests occur only when explicitly initiated by the user:

1. **Manual Update Check:** When you click **Check for updates** in the About dialog, VeloxMD sends a single read-only HTTPS GET request to the public GitHub Releases API (`https://api.github.com/repos/lbonomo/VeloxMD/releases/latest`) to check whether a newer release tag exists. No user identifiers, device details, or telemetry are sent by VeloxMD.
2. **External Links:** Clicking a web link inside a Markdown document or the About dialog opens the URL in your system's default web browser.

## Distribution Platforms

If you download or install VeloxMD through **Microsoft Store** or **GitHub Releases**, those platforms may process download or diagnostic data according to their own privacy policies.

## Contact

If you have questions about this Privacy Policy, please open an issue at https://github.com/lbonomo/VeloxMD/issues.
