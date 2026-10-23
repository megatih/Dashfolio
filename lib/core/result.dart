import 'failure.dart';

/// Minimal result type for operations that can fail with an [AppFailure].
sealed class Result<T> {
  const Result();

  const factory Result.ok(T value) = Ok<T>;
  const factory Result.err(AppFailure failure) = Err<T>;

  T? get valueOrNull => switch (this) {
    Ok(:final value) => value,
    Err() => null,
  };

  R when<R>({required R Function(T value) ok, required R Function(AppFailure failure) err}) => switch (this) {
    Ok(:final value) => ok(value),
    Err(:final failure) => err(failure),
  };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final AppFailure failure;
}
