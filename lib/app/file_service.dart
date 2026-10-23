import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/backup/backup_service.dart';
import 'providers.dart';

class PickedText {
  const PickedText({required this.name, required this.text});
  final String name;
  final String text;
}

/// File picking/saving behind an interface so screens can be tested with a fake.
abstract class FileService {
  /// Lets the user choose a text file with one of [extensions]; null when cancelled.
  Future<PickedText?> pickText(List<String> extensions);

  /// Saves [text] as [fileName]; returns false when cancelled or on failure.
  Future<bool> saveText({required String fileName, required String text, required String extension, required MimeType mime});
}

class PlatformFileService implements FileService {
  const PlatformFileService();

  @override
  Future<PickedText?> pickText(List<String> extensions) async {
    final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: extensions);
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return PickedText(name: file.name, text: _decode(bytes));
  }

  /// UTF-8 first; falls back to Latin-1 for older broker exports.
  static String _decode(Uint8List bytes) {
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return latin1.decode(bytes);
    }
  }

  @override
  Future<bool> saveText({required String fileName, required String text, required String extension, required MimeType mime}) async {
    final bytes = Uint8List.fromList(utf8.encode(text));
    try {
      final path = await FileSaver.instance.saveAs(name: fileName, bytes: bytes, fileExtension: extension, mimeType: mime);
      return path != null;
    } on Object {
      try {
        await FileSaver.instance.saveFile(name: fileName, bytes: bytes, fileExtension: extension, mimeType: mime);
        return true;
      } on Object {
        return false;
      }
    }
  }
}

final fileServiceProvider = Provider<FileService>((ref) => const PlatformFileService());

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(
    ref.watch(portfolioRepositoryProvider),
    ref.watch(settingsRepositoryProvider),
    ref.watch(clockProvider),
    ref.watch(lunoSupportedProvider) ? ref.watch(lunoRepositoryProvider) : null,
    ref.watch(lunoSupportedProvider) ? ref.watch(lunoCredentialStoreProvider) : null,
  ),
);
