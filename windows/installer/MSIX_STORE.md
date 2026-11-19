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

1. Register a free developer account at https://storedeveloper.microsoft.com and reserve the app name (`VeloxMD`) in **Microsoft Partner Center** (`New product → MSIX or PWA app`).
2. Under **Product management → Product identity**, copy:
   - `Package/Identity/Name`
   - `Package/Identity/Publisher` (`CN=...`)
   - `Package/Properties/PublisherDisplayName`
3. Add those values as GitHub Repository **Variables** (**Settings → Secrets and variables → Actions → Variables**):
   - `MSIX_IDENTITY_NAME`
   - `MSIX_PUBLISHER`
   - `MSIX_PUBLISHER_DISPLAY_NAME` *(optional, defaults to `Lucas Bonomo`)*
4. Run the **Build Windows MSIX (Microsoft Store)** workflow (or publish a new release), download the `veloxmd-windows-msix` workflow artifact, and upload `veloxmd.msix` in Partner Center under **Packages**.

> Note: Packages built with `--store` are intentionally unsigned; Microsoft signs the `.msix` with its own certificate during Store certification.
