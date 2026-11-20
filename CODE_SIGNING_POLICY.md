# Code Signing Policy

Free code signing provided by [SignPath.io](https://signpath.io/), certificate by [SignPath Foundation](https://signpath.org/).

## Signed Artifacts

Official Windows release installers (`veloxmd-setup-windows-x64-*.exe`) published on [GitHub Releases](https://github.com/lbonomo/VeloxMD/releases) are built and signed through the automated GitHub Actions workflow [`.github/workflows/build-windows.yml`](.github/workflows/build-windows.yml).

## Roles and Responsibilities

* **Project Maintainer / Author / Reviewer / Approver:** Lucas Bonomo ([@lbonomo](https://github.com/lbonomo))
* **Build System:** GitHub Actions (automated builds from tagged releases in the public repository)

Only artifacts produced directly by the repository's GitHub Actions release workflow from reviewed commits are submitted for signing.

## Privacy Policy

VeloxMD operates completely offline. It does not collect, store, or transmit personal data, usage analytics, or telemetry to any server. See the full [Privacy Policy](PRIVACY_POLICY.md) ([web version](https://lbonomo.github.io/VeloxMD/privacy.html)).
