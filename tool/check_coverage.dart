// Enforces line-coverage thresholds from an lcov file.
//
// Usage: dart run tool/check_coverage.dart coverage/lcov.info --domain 90 --overall 70
//
// "domain" covers lib/domain/** (pure calculators); "overall" covers all of lib/ except generated
// code and the debug-only design gallery.
import 'dart:io';

class _Counts {
  int found = 0;
  int hit = 0;
  double get percent => found == 0 ? 100 : hit * 100 / found;
}

bool _excluded(String path) => path.endsWith('.g.dart') || path.endsWith('.freezed.dart') || path.endsWith('design_system/gallery.dart');

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('usage: check_coverage.dart <lcov.info> [--domain N] [--overall N]');
    exit(64);
  }
  final file = File(args.first);
  if (!file.existsSync()) {
    stderr.writeln('No such file: ${args.first}');
    exit(66);
  }
  double? opt(String name) {
    final i = args.indexOf('--$name');
    return i >= 0 && i + 1 < args.length ? double.tryParse(args[i + 1]) : null;
  }

  final domainMin = opt('domain');
  final overallMin = opt('overall');

  final domain = _Counts();
  final overall = _Counts();
  final perFile = <String, _Counts>{};

  String? current;
  for (final line in file.readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      current = line.substring(3).replaceAll(r'\', '/');
    } else if (line.startsWith('DA:') && current != null && current.startsWith('lib/') && !_excluded(current)) {
      final parts = line.substring(3).split(',');
      final hit = (int.tryParse(parts[1]) ?? 0) > 0;
      for (final c in [overall, if (current.startsWith('lib/domain/')) domain, perFile.putIfAbsent(current, _Counts.new)]) {
        c.found++;
        if (hit) c.hit++;
      }
    }
  }

  stdout
    ..writeln('Domain  coverage: ${domain.percent.toStringAsFixed(1)}% (${domain.hit}/${domain.found})')
    ..writeln('Overall coverage: ${overall.percent.toStringAsFixed(1)}% (${overall.hit}/${overall.found})');

  final lowest = perFile.entries.where((e) => e.value.found > 0).toList()..sort((a, b) => a.value.percent.compareTo(b.value.percent));
  stdout.writeln('Least covered files:');
  for (final e in lowest.take(8)) {
    stdout.writeln('  ${e.value.percent.toStringAsFixed(0).padLeft(3)}%  ${e.key}');
  }

  var failed = false;
  if (domainMin != null && domain.percent < domainMin) {
    stderr.writeln('FAIL: domain coverage ${domain.percent.toStringAsFixed(1)}% is below $domainMin%');
    failed = true;
  }
  if (overallMin != null && overall.percent < overallMin) {
    stderr.writeln('FAIL: overall coverage ${overall.percent.toStringAsFixed(1)}% is below $overallMin%');
    failed = true;
  }
  exit(failed ? 1 : 0);
}
