# Dashfolio: notes for Claude Code

Flutter app (iOS, macOS, Windows, Linux, web) tracking portfolios with Yahoo Finance data and, on native platforms, a read-only Luno sync. Read `SPEC.md` (§18 lists status
and deviations) and `README.md` first.

## Commands
- Flutter lives at `~/Applications/flutter/bin` (add to PATH if `flutter` is not found).
- `flutter analyze` must stay at zero issues. Format with `dart format` (page width 140 from `analysis_options.yaml`).
- `flutter test --exclude-tags golden` for unit/widget tests; `flutter test --tags golden` for goldens (macOS-generated).
- `dart run build_runner build` after changing `lib/data/db/tables.dart`, then dump the schema and regenerate migration helpers (see README).
- Linux AppImage packaging (AppRun with first-run desktop integration, desktop file, AppStream template, `build_appimage.sh`) lives in `linux/packaging/`; `release.yml` builds Linux x64/arm64 and Windows x64/arm64 (arm64 jobs install Flutter from git).
- Proxy: `cd proxy && npm test && npm run typecheck`.

## Architecture
Layers: `domain/` (pure Dart: entities, repository interfaces, calculators) ← `data/` (drift, Yahoo client, repo impls) ←
`app/` + `features/` (Riverpod providers and UI). Money is `Decimal`. `Clock` and `MarketDataRepository` are injected;
use `FakeMarketData` and `AppHarness` (in `test/support/`) for tests.

## Gotchas learned the hard way
- **Riverpod 3 pauses providers nobody listens to.** In tests, `container.listen(...)` a provider before reading it; never rely on `ref.read(streamProvider.future)` alone.
- **Drift streams under `testWidgets` (fake async)**: `await repo.watchX().first` hangs. Use the one-shot `get*`/`*Snapshot` methods in services, and wrap direct DB reads in tests with `tester.runAsync`. Drift keeps cancelled streams alive on a timer, so `AppHarness.dispose` pumps before closing the DB.
- **`compute` never completes under fake async**: the value-history runner is injectable (`historyRunnerProvider`).
- **`Future.whenComplete(() => map.remove(key))` deadlocks** if the callback returns the future itself; use a block body.
- **Dialogs live on the root navigator**: close them with the dialog's own `BuildContext`, not the page's.
- Test text uses the Ahem font unless you call `loadAppFonts()`; widths differ, so load Inter for layout tests and goldens.
- Yahoo is unofficial and rate limits aggressively (`429` on repeated curl). Parsers are tested against `test/fixtures/yahoo/`.
- `web/sqlite3.wasm` and `web/drift_worker.js` must match the `sqlite3`/`drift` versions in `pubspec.lock`.

## Luno (read this before touching `lib/data/luno/` or `lib/features/luno/`)
- **Read-only by construction.** The only non-GET code is `LunoPermissionProbe`; `luno_write_guard_test.dart` fails if anything else sends a write or references a money-moving endpoint. Never add one.
- **Secrets**: key id/secret live only in `LunoCredentialStore` (secure storage). Never put them in drift, settings, backups, logs, provider state or test output; `LunoCredentials.toString()` is redacted on purpose. The `Authorization` header is built per request and the client logs only `e.type`, never messages/URIs.
- Anything that deletes a portfolio, turns the app lock off, or resets the app must go through `LunoConnectService` so keys are erased. `resetApp` deliberately does **not** depend on the keychain working.
- Tests must override `lunoCredentialStoreProvider` with `FakeLunoCredentialStore` (the harness does), or they will reach the real keychain.
- **Ledger amounts are JSON numbers** (`balance`, `balance_delta`, `available`, `available_delta`); `decodeLunoJson` quotes them before decoding so decimals stay exact. Use it, not `jsonDecode`.
- One position per asset per connection: `LUNO:{ASSET}{homeFiat}`. Trades paid in another fiat are converted to the home fiat; do not reintroduce per-pair positions (a later send cannot draw them down).
- Synced rows are staged in `luno_ledger_rows` and mapped by the pure `LunoLedgerMapper`; unknown shapes are reported (`unrecognised`), never guessed. `test/fixtures/luno/live/` is a scrubbed recording of a real account, **git-ignored and local-only** (its tests skip when absent; see its README for the real ledger's quirks: newest-first pages, trade fees as separate FEE rows, kind-less reserve/release rows, instant buys without `trade_details`). **Never run the recorder into `test/fixtures/luno/` itself** (it defaults to `live/`): that directory holds hand-built fixtures many tests depend on. A test fails if an address, hash or e-mail appears in any fixture.
- `RequestScheduler` (`lib/data/net/`) paces every Yahoo and Luno request. Request-count tests (`yahoo_request_budget_test.dart`, `luno_sync_service_test.dart`) guard call volume; keep them green when changing refresh or sync.
- **Widget tests + drift**: writing to the database from `tester.runAsync` *after* the app has live stream listeners deadlocks. Seed before `h.pump`, or drive the change through the UI (`luno_ui_test.dart` does both).
- Dialogs that own a `TextEditingController` must dispose it in their own `State` (disposing right after `showDialog` returns crashes the closing animation).
- Web has no Luno: everything keys off `lunoSupportedProvider` (override it in tests).
