/// Typed application failures surfaced from repositories to the UI.
sealed class AppFailure implements Exception {
  const AppFailure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure([super.message = 'Network unavailable']);
}

final class RateLimitedFailure extends AppFailure {
  const RateLimitedFailure([super.message = 'Yahoo Finance is rate limiting requests']);
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure([super.message = 'Not found']);
}

final class ParseFailure extends AppFailure {
  const ParseFailure([super.message = 'Unexpected response format']);
}

final class StorageFailure extends AppFailure {
  const StorageFailure([super.message = 'Storage error']);
}

final class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure([super.message = 'Request was rejected']);
}

final class ConfigFailure extends AppFailure {
  const ConfigFailure([super.message = 'Configuration missing']);
}

/// The API key lacks a permission the request needs (Luno `ErrInsufficientPerms` / HTTP 403).
final class ForbiddenFailure extends AppFailure {
  const ForbiddenFailure([super.message = 'The API key does not have permission for this request']);
}

/// No credentials are stored for a connection (never entered, or restored from a backup).
final class CredentialsMissingFailure extends AppFailure {
  const CredentialsMissingFailure([super.message = 'API credentials are not available']);
}

/// The exchange rejected the key as unknown or revoked (HTTP 401).
final class KeyRevokedFailure extends AppFailure {
  const KeyRevokedFailure([super.message = 'The API key was rejected or has been revoked']);
}

/// The platform secure store could not be used. Credentials are never kept anywhere less safe.
final class SecureStorageUnavailableFailure extends AppFailure {
  const SecureStorageUnavailableFailure([super.message = 'Secure storage is unavailable on this device']);
}

/// The key authenticates, but belongs to a different Luno user than the connection it would replace.
final class KeyMismatchFailure extends AppFailure {
  const KeyMismatchFailure([super.message = 'This key belongs to a different Luno account than the connection it replaces']);
}

/// The key can place orders or withdraw funds (or its permissions could not be established) and was refused.
final class UnsafeKeyFailure extends AppFailure {
  const UnsafeKeyFailure([super.message = 'This key can place orders or withdraw funds; create a read-only key instead']);
}
