import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Which build is running: version and build number come from the platform bundle, the date from `--dart-define=BUILD_DATE=<ISO-8601>`.
class AppInfo {
  const AppInfo({required this.version, required this.buildNumber, this.buildDate});

  final String version;
  final String buildNumber;

  /// Null for builds made without the define (e.g. `flutter run`).
  final DateTime? buildDate;

  static const _envBuildDate = String.fromEnvironment('BUILD_DATE');

  static DateTime? parseBuildDate(String raw) => DateTime.tryParse(raw.trim());

  String get label => buildNumber.isEmpty ? version : '$version ($buildNumber)';
}

final appInfoProvider = FutureProvider<AppInfo>((ref) async {
  final p = await PackageInfo.fromPlatform();
  return AppInfo(version: p.version, buildNumber: p.buildNumber, buildDate: AppInfo.parseBuildDate(AppInfo._envBuildDate));
});
