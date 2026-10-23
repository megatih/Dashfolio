import 'package:dashfolio/core/failure.dart';
import 'package:dashfolio/data/luno/luno_credential_store.dart';

/// In-memory credential store for tests; behaves like the secure store but never persists anything.
class FakeLunoCredentialStore implements LunoCredentialStore {
  FakeLunoCredentialStore({this.available = true});

  bool available;
  final Map<int, LunoCredentials> _items = {};

  Iterable<int> get connectionIds => _items.keys;

  void _check() {
    if (!available) throw const SecureStorageUnavailableFailure();
  }

  @override
  Future<LunoCredentials?> read(int connectionId) async {
    _check();
    return _items[connectionId];
  }

  @override
  Future<void> write(int connectionId, LunoCredentials credentials) async {
    _check();
    _items[connectionId] = credentials;
  }

  @override
  Future<void> delete(int connectionId) async {
    _check();
    _items.remove(connectionId);
  }

  @override
  Future<void> deleteAll() async {
    _check();
    _items.clear();
  }

  @override
  Future<bool> isAvailable() async => available;
}
