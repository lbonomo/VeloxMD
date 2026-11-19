# Windows MSIX & Microsoft Store Packaging

This project is configured with the Flutter [`msix`](https://pub.dev/packages/msix) package in `pubspec.yaml` (`msix_config`) and the GitHub Actions workflow `.github/workflows/build-windows-msix.yml` to produce `.msix` packages for the Microsoft Store.

## Local Test Build (on Windows)

To generate a test-signed `.msix` for local QA (requires installing the generated test certificate when prompted or trusting it locally):

```powershell
flutter pub get
flutter build windows --release
dart run msix:create --build-windows false
```

Output: `build/windows/msix/veloxmd.msix`

## Microsoft Store Build (GitHub Actions)

`pubspec.yaml` (`msix_config`) is configured with the Microsoft Partner Center identity:
- `identity_name`: `LucasBonomo.VeloxMD`
- `publisher`: `CN=8D59B12E-EAA9-4F45-912B-B5D7ED20635B`
- `publisher_display_name`: `Lucas Bonomo`

*(Optional: you can override these at build time with GitHub Repository Variables `MSIX_IDENTITY_NAME`, `MSIX_PUBLISHER`, and `MSIX_PUBLISHER_DISPLAY_NAME`.)*

Run the **Build Windows MSIX (Microsoft Store)** workflow (or publish a new release), download the `veloxmd-windows-msix` workflow artifact, and upload `veloxmd.msix` in Partner Center under **Packages**.

> Note: Packages built with `--store` are intentionally unsigned; Microsoft signs the `.msix` with its own certificate during Store certification.
