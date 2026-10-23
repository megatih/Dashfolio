# Dashfolio

[![CI](https://github.com/megatih/Dashfolio/actions/workflows/ci.yml/badge.svg)](https://github.com/megatih/Dashfolio/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/megatih/Dashfolio?include_prereleases)](https://github.com/megatih/Dashfolio/releases/latest)
![Flutter](https://img.shields.io/badge/Flutter-3.47-02569B?logo=flutter&logoColor=white)
![Platforms](https://img.shields.io/badge/platforms-macOS%20%7C%20Windows%20%7C%20Linux%20%7C%20iOS%20%7C%20Web-informational)

A sleek, neumorphic portfolio dashboard for traders, analysts and personal investors, powered by Yahoo Finance and (on native platforms) your Luno account.
Runs on **iOS, macOS, Windows, Linux and the web**. Everything you enter stays on your device.

- **Portfolios & holdings** — multiple portfolios plus an "All portfolios" view; stocks, ETFs, funds, indices, crypto, FX and futures.
- **Transactions** — manual buys/sells/dividends/splits/cash, opening positions (quantity + average cost), and CSV import with column mapping, previews, duplicate detection and one-tap undo.
- **Performance** — total value, day change, unrealized/realized P&L, dividends, value history, allocation (asset class, sector, currency, exchange…), top movers. Average-cost or FIFO per portfolio.
- **Markets** — symbol search (`Ctrl/Cmd+K`), watchlists, quote pages with line/candlestick charts, volume, key statistics, profile, events and news.
- **Income** — dividends received by month and symbol, unrecorded dividends detected from Yahoo data (record in one tap), projected annual income, stock-split prompts.
- **Luno (iOS, macOS, Windows, Linux)** — connect a read-only Luno API key and a portfolio mirrors your balances, trades, deposits, withdrawals, sends, receives and interest, priced from Luno's own tickers and candles. Several accounts are supported. Not available on the web.
- **Multi-currency** — pick a base currency; holdings convert with current and historical FX.
- **Private** — local SQLite database, optional app lock (PIN + biometrics), JSON backup/restore and CSV export. No accounts, no telemetry.
- **Adaptive** — bottom bar on phones, rail on tablets, collapsible sidebar and multi-column dashboard on desktop; light/dark themes follow the system.

> Market data comes from Yahoo Finance's unofficial endpoints. It may be delayed, incomplete or change without notice.
> Dashfolio is a tracking tool, not financial advice.

See [`SPEC.md`](SPEC.md) for the full specification and implementation notes.

## Download

Grab the latest build from the [Releases page](https://github.com/megatih/Dashfolio/releases/latest):

| Platform | Asset | Notes |
|---|---|---|
| macOS (Apple silicon & Intel) | `Dashfolio-<version>-macos.dmg` / `.zip` | Unsigned: right-click the app → **Open**, or run `xattr -dr com.apple.quarantine /Applications/Dashfolio.app` |
| Windows x64 | `Dashfolio-<version>-windows-x64.zip` | Unzip and run `dashfolio.exe`. SmartScreen may warn because the build is unsigned |
| Windows arm64 | `Dashfolio-<version>-windows-arm64.zip` | Native build for Snapdragon X and NVIDIA RTX Spark / N1X laptops. The x64 zip also runs there under emulation, but slower |
| Linux x64 / arm64 | `Dashfolio-<version>-linux-x64.AppImage`, `…-linux-arm64.AppImage` | `chmod +x` it and run it (see below) |
| Linux x64 | `Dashfolio-<version>-linux-x64.tar.gz` | Plain bundle for distros without AppImage support |

Each release includes `SHA256SUMS.txt`. The Windows zips include the Visual C++ runtime, so nothing else needs installing. iOS and web are built from source (see below).

**Linux AppImage.** Built on Ubuntu 22.04, so it needs glibc 2.35+ (Ubuntu 22.04, Debian 12 or newer), GTK 3 and `libsecret-1-0` (plus an unlocked
Secret Service to connect Luno). Ubuntu 22.04+ also needs `libfuse2` to run AppImages (or start it with `--appimage-extract-and-run`).

On first run it adds a Dashfolio entry and icons to your GNOME / KDE application menu (`~/.local/share/applications` and `~/.local/share/icons`). If
you move the file, the next run re-points the entry. To opt out set `DASHFOLIO_NO_INTEGRATION=1`; to undo it run
`./Dashfolio-<version>-linux-<arch>.AppImage --remove-desktop-integration` or choose **Remove from menu** on the menu entry. If you use Gear Lever or
AppImageLauncher, Dashfolio leaves the integration to them. They can also update it in place from the embedded update information.

## Getting started

Requirements: Flutter 3.47+ (Dart 3.13+). Linux builds need GTK and libsecret:
`sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libsecret-1-dev`.

```sh
flutter pub get
dart run build_runner build      # drift generated code (already committed; rerun after schema changes)
flutter run -d macos             # or windows, linux, chrome, an iOS simulator …
```

### Web

Browsers cannot call Yahoo Finance directly (CORS), so the web build talks to a small proxy — see
[`proxy/README.md`](proxy/README.md) to deploy it to Cloudflare Workers (free tier is enough).

```sh
flutter run -d chrome --web-port 8080 --dart-define=YAHOO_PROXY_URL=https://<your-worker>.workers.dev
```

### Build date

Settings → About shows the version and build number from `pubspec.yaml` (or `--build-name`/`--build-number`). The build
date is stamped at build time; without the define it reads "development build":

```sh
flutter build macos --dart-define=BUILD_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)
```

The proxy URL can also be entered at runtime in **Settings → Data connection**. Without it the web app still opens and
works from cached data, but cannot download prices.

## Using the app

1. First launch: accept the disclaimer, pick your base currency, name your first portfolio.
2. Add transactions (`Ctrl/Cmd+N`) or import a broker CSV (**Settings → Import CSV**).
3. Press the refresh button (`Ctrl/Cmd+R`, or pull down on touch screens) to download prices. Prices refresh **manually**
   (and once on launch when data is older than 15 minutes); the app always shows cached data first, so it works offline.

| Shortcut | Action |
|---|---|
| `Ctrl/Cmd+R` | Refresh prices |
| `Ctrl/Cmd+K` | Search markets |
| `Ctrl/Cmd+N` | New transaction |
| `Ctrl/Cmd+1…5` | Dashboard, Portfolios, Markets, Income, Settings |

## Connecting Luno

Luno is available on iOS, macOS, Windows and Linux (a browser can neither call Luno's API nor safely hold a key).
**Settings → Luno → Connect Luno** walks you through it. In short:

1. Turn on the **app lock** (Settings → Security). Connecting, replacing a key and disconnecting all ask for your PIN or biometrics.
2. On Luno open **Settings → API keys**, add a key with a *custom* permission set and tick only **View balance, View
   transactions, View orders, View transfers, View withdrawals**. Do **not** tick *Send to any address*, *Create orders* or
   *Create/cancel withdrawals*. (Luno's "Read-only access" preset includes *Send to any address*.)
3. Paste the key ID and secret. Dashfolio checks them, **refuses keys that can place orders or request/cancel withdrawals**
   (it probes with requests that can only fail: a stop on an order id that cannot exist, a cancel of withdrawal `0`), and never
   calls anything that moves money. It cannot test *Send to any address* without moving money, so it asks you to confirm that one.
4. Name the connection and choose your Luno currency. The first sync downloads your whole ledger (about one request per 1,000
   entries) and builds the transactions; later syncs are part of the normal refresh and cost one request when nothing changed.

How your key is protected:

| | |
|---|---|
| Stored | Only in the platform secure store: iOS keychain (this device only, never iCloud), macOS login keychain, Windows per-user store, Linux Secret Service. If none is available Dashfolio refuses to connect and **never falls back** to a file or database |
| Never in | The database, backups, exports, logs, clipboard, or any provider state. The database keeps the last four characters of the key ID |
| Shown | The secret is write-only and is never displayed again |
| Network | HTTPS to `api.luno.com` only; no redirects; no proxy; the web proxy never sees Luno traffic |
| Gated | App lock required; PIN/biometric step-up to open the key form, replace the key or disconnect. Turning the lock off, or resetting the app, deletes every key |
| Backups | Include connection details and synced transactions, never keys. A restored connection waits for you to enter a key again |

Synced portfolios are read-only (you can add notes). Balances are reconciled against Luno after every sync: a difference is
shown, never silently adjusted. Disconnecting asks whether to keep the portfolio as an ordinary one or delete it.

Request limits: every Yahoo and Luno call goes through one scheduler (token bucket, in-flight de-duplication,
`Retry-After`-aware backoff, circuit breaker). Luno is held to 240 of its 300 calls per minute, quotes are cached for 30 s,
history is fetched incrementally, and tests assert the number of requests for the common scenarios.

To record scrubbed fixtures from a real account for the test-suite (kept local: `test/fixtures/luno/live/` is git-ignored, and its tests skip when absent), or to see exactly how Luno answers the permission probes for your key (use a read-only key; the secret stays in your shell):

```sh
LUNO_KEY_ID=… LUNO_KEY_SECRET=… dart run tool/record_luno_fixtures.dart   # writes test/fixtures/luno/live/
LUNO_KEY_ID=… LUNO_KEY_SECRET=… dart run tool/check_luno_key.dart         # the wizard's key check, with Luno's raw answers
```

See `test/fixtures/luno/README.md` for what the recorder scrubs and what a real Luno ledger looks like.

## Development

```sh
flutter analyze                          # strict-casts / strict-inference / strict-raw-types, zero warnings expected
flutter test --exclude-tags golden       # unit + widget tests
flutter test --tags golden               # golden images (generated on macOS; regenerate with --update-goldens)
flutter test integration_test -d macos   # end-to-end flow
flutter test --coverage && dart run tool/check_coverage.dart coverage/lcov.info --domain 90 --overall 70
```

### Releasing

Releases are built by [`release.yml`](.github/workflows/release.yml) for Linux, Windows and macOS. Update `version:` in `pubspec.yaml` (and keep it in step with the tag), then:

```sh
git tag v1.2.3 && git push origin v1.2.3
```

The tag becomes the build name (`--build-name`), the workflow run number the build number, and the artifacts are attached to a new
GitHub release with generated notes. Tags containing a hyphen (`v1.2.3-beta.1`) are marked as pre-releases. The workflow can also be run
manually from the Actions tab to get the build artifacts without publishing a release. Changes under `linux/`, `windows/`, `macos/`
or to `pubspec.*` and the workflow itself also run it on `main` and in pull requests, building every platform without publishing, so packaging
breakage shows up before a tag. Linux AppImage packaging lives in `linux/packaging/`.

Architecture (feature-first, layered):

```
lib/
  core/            Result/AppFailure, Clock, Decimal helpers, formatting
  design_system/   Neumorphic tokens, Neu* widgets, theme, gallery (/gallery in debug builds)
  data/            drift database, request scheduler, Yahoo client + mappers, Luno client/sync/credentials, repositories, backup
  domain/          entities, repository interfaces, pure calculators (holdings, valuation, history, dividends, CSV)
  app/             Riverpod providers, refresh controller, settings, app root
  features/        dashboard, portfolios, holdings, transactions, markets, income, import_export, settings, lock, luno, shell
  routing/         go_router configuration
proxy/             Cloudflare Worker (CORS proxy for web)
tool/              coverage gate, icon generator
```

All money math uses `Decimal`; `double` appears only in chart series and quote display values. Yahoo parsing is covered by
fixtures in `test/fixtures/yahoo/` (hand-assembled to mirror real responses; re-record with `curl` when convenient). Luno is covered by
`test/fixtures/luno/` (hand-built from Luno's OpenAPI; see its README and the recorder above).

### Regenerating things

- App icons: `flutter test tool/icon_generator_test.dart && dart run flutter_launcher_icons`
- Drift schema snapshot after a schema change: `dart run drift_dev schema dump lib/data/db/app_database.dart drift_schemas/ && dart run drift_dev schema generate drift_schemas/ test/generated_migrations/`
- Web database assets (`web/sqlite3.wasm`, `web/drift_worker.js`) must match the `sqlite3` and `drift` versions in `pubspec.lock`
  (download from the `sqlite3.dart` and `drift` GitHub releases).

## Platform notes

- **macOS** — sandbox with outgoing network and user-selected file access entitlements. Secure storage uses the file keychain so unsigned debug builds work; moving Luno keys to the Data Protection keychain needs a signed build with a keychain access group.
- **iOS** — Face ID usage description included. Run `pod install` on first build.
- **Windows** — biometrics through Windows Hello (`local_auth`).
- **Windows arm64** — built natively on a `windows-11-arm` runner with Flutter installed from git (Flutter publishes no arm64 SDK archive); the Visual C++ runtime is bundled.
- **Linux** — secure storage needs `libsecret` and an unlocked Secret Service (GNOME Keyring, KWallet); without it Luno cannot be connected. No biometrics, PIN only.
- **Web** — PIN lock only hides the screen; data lives in the browser's storage. Luno is not available.
