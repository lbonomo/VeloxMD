import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;

class UpdateCheckException implements Exception {
  const UpdateCheckException(this.message);

  final String message;

  @override
  String toString() => 'UpdateCheckException: $message';
}

/// Result of querying GitHub Releases for a newer version.
class UpdateCheckResult {
  const UpdateCheckResult({
    required this.updateAvailable,
    required this.currentVersion,
    required this.latestVersion,
    this.downloadUrl,
    this.releaseUrl,
  });

  final bool updateAvailable;
  final String currentVersion;
  final String latestVersion;

  /// Direct download URL for the asset matching the current platform.
  /// Falls back to [releaseUrl] when no matching asset is found.
  final String? downloadUrl;

  /// The release's `html_url` on GitHub.
  final String? releaseUrl;
}

/// Checks GitHub Releases for a newer version of the app.
///
/// NETWORK: [checkGitHubUpdate] performs a single HTTPS request. VeloxMD is
/// otherwise 100% offline (see `.kiro/steering/offline.md`), so this MUST only
/// be called in response to an explicit user action -- e.g. the "Check for
/// updates" button in the About dialog -- never automatically at startup or
/// during normal use.
class UpdateChecker {
  UpdateChecker._();

  static const Duration _timeout = Duration(seconds: 10);

  /// Queries `releases/latest` for [owner]/[repo] and compares the tag against
  /// [currentVersion].
  ///
  /// Throws [UpdateCheckException] on network/HTTP/parse failure.
  static Future<UpdateCheckResult> checkGitHubUpdate({
    required String owner,
    required String repo,
    required String currentVersion,
  }) async {
    final url = Uri.parse(
      'https://api.github.com/repos/$owner/$repo/releases/latest',
    );

    final http.Response response;
    try {
      response = await http.get(
        url,
        headers: const {'Accept': 'application/vnd.github+json'},
      ).timeout(_timeout);
    } catch (e) {
      throw UpdateCheckException('No se pudo conectar con GitHub: $e');
    }

    if (response.statusCode != 200) {
      throw UpdateCheckException(
        'GitHub respondió con estado ${response.statusCode}.',
      );
    }

    final Map<String, dynamic> data;
    try {
      data = json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw const UpdateCheckException('Respuesta de GitHub inválida.');
    }

    final latestTag =
        (data['tag_name']?.toString() ?? '').replaceAll('v', '').trim();
    if (latestTag.isEmpty) {
      throw const UpdateCheckException('La release no tiene tag_name.');
    }

    final releaseUrl = data['html_url']?.toString();
    final hasUpdate = isNewer(latestTag, currentVersion);

    String? downloadUrl;
    if (hasUpdate) {
      final assets = (data['assets'] as List?) ?? const <dynamic>[];
      downloadUrl = _pickAssetForPlatform(assets) ?? releaseUrl;
    }

    return UpdateCheckResult(
      updateAvailable: hasUpdate,
      currentVersion: currentVersion,
      latestVersion: latestTag,
      downloadUrl: downloadUrl,
      releaseUrl: releaseUrl,
    );
  }

  /// Selects the release asset matching the current desktop platform.
  /// Windows -> `.exe`; Linux -> `.AppImage` (preferred) or `.deb`.
  static String? _pickAssetForPlatform(List<dynamic> assets) {
    final extensions =
        Platform.isWindows ? const ['.exe'] : const ['.appimage', '.deb'];

    for (final ext in extensions) {
      for (final asset in assets) {
        final name = (asset['name']?.toString() ?? '').toLowerCase();
        if (name.endsWith(ext)) {
          return asset['browser_download_url']?.toString();
        }
      }
    }
    return null;
  }

  /// True if [latest] is strictly newer than [current] using a numeric dotted
  /// comparison. Build/pre-release suffixes (`+8`, `-rc1`) are ignored.
  @visibleForTesting
  static bool isNewer(String latest, String current) {
    final a = _parse(latest);
    final b = _parse(current);
    final len = a.length > b.length ? a.length : b.length;
    for (var i = 0; i < len; i++) {
      final ai = i < a.length ? a[i] : 0;
      final bi = i < b.length ? b[i] : 0;
      if (ai != bi) return ai > bi;
    }
    return false;
  }

  static List<int> _parse(String v) {
    // 0.5.0+8 -> [0,5,0], 1.2.0-rc1 -> [1,2,0]
    final core = v.split(RegExp(r'[+-]')).first;
    return core
        .split('.')
        .map((p) => int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
  }
}
