import '../../domain/repositories/settings_repository.dart';
import '../db/app_database.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._db);
  final AppDatabase _db;

  @override
  Stream<Map<String, String>> watchAll() => _db.select(_db.settings).watch().map((rows) => {for (final r in rows) r.key: r.value});

  @override
  Future<Map<String, String>> getAll() async => {for (final r in await _db.select(_db.settings).get()) r.key: r.value};

  @override
  Future<String?> get(String key) async {
    final row = await (_db.select(_db.settings)..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  @override
  Future<void> set(String key, String value) =>
      _db.into(_db.settings).insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));

  @override
  Future<void> remove(String key) => (_db.delete(_db.settings)..where((t) => t.key.equals(key))).go();
}
