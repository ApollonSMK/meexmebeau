import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import '../config/constants.dart';

class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String tagName;
  final String releaseNotes;
  final String apkDownloadUrl;
  final String releaseName;

  const UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.tagName,
    required this.releaseNotes,
    required this.apkDownloadUrl,
    required this.releaseName,
  });
}

class UpdateService {
  static const _githubApiBase = 'https://api.github.com';

  /// Checks GitHub Releases for a newer version.
  /// Returns [UpdateInfo] if an update is available, null otherwise.
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // e.g. "1.0.0"

      final repo = AppConstants.githubRepo;
      final url = Uri.parse('$_githubApiBase/repos/$repo/releases/latest');

      final response = await http.get(url, headers: {
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('[UpdateService] GitHub API returned ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = (data['tag_name'] as String? ?? '').trim();
      final releaseName = (data['name'] as String? ?? tagName).trim();
      final releaseNotes = (data['body'] as String? ?? '').trim();

      // Strip leading 'v' for version comparison: "v1.2.0" → "1.2.0"
      final latestVersion = tagName.startsWith('v')
          ? tagName.substring(1)
          : tagName;

      if (!_isNewer(latestVersion, currentVersion)) {
        debugPrint('[UpdateService] App is up to date ($currentVersion)');
        return null;
      }

      // Find the APK asset
      final assets = data['assets'] as List<dynamic>? ?? [];
      String? apkUrl;
      for (final asset in assets) {
        final name = (asset['name'] as String? ?? '').toLowerCase();
        if (name.endsWith('.apk')) {
          apkUrl = asset['browser_download_url'] as String?;
          break;
        }
      }

      if (apkUrl == null) {
        debugPrint('[UpdateService] No APK asset found in release $tagName');
        return null;
      }

      debugPrint('[UpdateService] Update available: $currentVersion → $latestVersion');

      return UpdateInfo(
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        tagName: tagName,
        releaseNotes: releaseNotes,
        apkDownloadUrl: apkUrl,
        releaseName: releaseName,
      );
    } catch (e) {
      debugPrint('[UpdateService] Error checking for update: $e');
      return null;
    }
  }

  /// Downloads the APK and returns the local file path.
  /// [onProgress] is called with values 0.0–1.0.
  static Future<String?> downloadApk(
    String url, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await request.send().timeout(const Duration(minutes: 10));

      if (response.statusCode != 200) {
        debugPrint('[UpdateService] Download failed: ${response.statusCode}');
        return null;
      }

      final total = response.contentLength ?? 0;
      int received = 0;
      final bytes = <int>[];

      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
        received += chunk.length;
        if (total > 0) {
          onProgress?.call(received / total);
        }
      }

      final dir = await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/mebeauty_update.apk');
      await file.writeAsBytes(bytes);

      debugPrint('[UpdateService] APK saved to ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('[UpdateService] Download error: $e');
      return null;
    }
  }

  /// Compares two semver strings. Returns true if [latest] > [current].
  static bool _isNewer(String latest, String current) {
    try {
      final l = _parse(latest);
      final c = _parse(current);
      for (int i = 0; i < 3; i++) {
        if (l[i] > c[i]) return true;
        if (l[i] < c[i]) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static List<int> _parse(String v) {
    final parts = v.split('.');
    return List.generate(3, (i) => i < parts.length ? (int.tryParse(parts[i]) ?? 0) : 0);
  }
}
