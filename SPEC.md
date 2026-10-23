# Dashfolio — Implementation Specification

Status: v1 implemented (see §18 for status and deviations); **v2 (Luno data source) implemented; verified against fixtures and fakes, not yet against a live Luno account (see §18)** · Target: Claude Code implementation · Project root: `dashfolio/` (existing `flutter create` scaffold, Dart SDK `^3.13`, platforms: iOS, macOS, Windows, Linux, Web; **no Android**).

### v2 changes at a glance
- **Luno** (crypto exchange) becomes a second data source, **native platforms only** (iOS, macOS, Windows, Linux). Read-only: balances, full account ledger, trades, transfers, rewards, fees, tickers, candles, markets (§7A).
- Each Luno API key is a **connection** that owns a **linked, synced, read-only portfolio**. Multiple connections are supported.
- API key id + secret are stored only in the platform secure store, gated by the app lock, with step-up auth and write-permission rejection (§7B).
- Shared **request scheduler** and call-volume rules for **both** Yahoo and Luno to avoid rate limiting (§8A).
- Schema v2: transaction `source`/`connection_id`/`external_id`/`executed_at`, new tx types `transfer_in`, `transfer_out`, `reward`, new Luno tables (§5).
- Milestones 14–19, new acceptance criteria and risks (§15–17). Sections 1–13 below are v1 text amended for v2; where v2 text conflicts with v1 text, v2 wins.

Sources: Luno OpenAPI 1.2.5 (changelog through 2026-10-01) and <https://www.luno.com/en/developers/api>. Luno publishes only an official Go SDK; there is no Dart SDK.

---

## 1. Overview

Dashfolio is a sleek, professional, intuitive portfolio dashboard for professional traders, financial analysts and personal investors. It tracks multiple portfolios of any Yahoo-quoted asset, computes value and P&L, charts performance and allocation, tracks dividend income, and offers watchlists with quote detail and candlestick charts. The UI is neumorphic (soft extruded/inset surfaces), with light and dark themes.

- **Data source:** Yahoo Finance (unofficial, undocumented endpoints). Data may be delayed or change without notice. The app shows a persistent-in-Settings and first-run disclaimer: *"Market data from Yahoo Finance, may be delayed. Not financial advice."*
- **Second data source (v2):** Luno, read with the user's own read-only API key (native platforms only). The disclaimer gains: *"Luno data is read with your own read-only API key and stays on this device."*
- **Storage:** local only. No accounts, no backend, no telemetry. Luno's API is the only additional network peer; credentials never leave the device except in requests to `api.luno.com`.
- **Platforms:** iOS, macOS, Windows, Linux, Web.

## 2. Scope

### In scope (v1)
- Multiple portfolios plus an aggregate "All portfolios" view.
- Any asset Yahoo quotes: equities, ETFs, mutual funds, indices, crypto, FX, futures.
- Holdings entered via manual transactions, manual positions (quantity + average cost) and CSV import.
- Core dashboard: total value, day change, total/unrealized/realized P&L, allocation, value-history chart.
- Markets: symbol search, watchlists, quote detail with line/candlestick charts, key stats, profile, news links.
- Income: dividends received, detected-but-unrecorded, upcoming, projected.
- Base currency with FX conversion (current and historical).
- Manual refresh only.
- **Luno account sync (native only, read-only):** balances, full ledger history, trades, crypto/fiat transfers, interest rewards and fees, mapped into a synced portfolio per connection; Luno pairs searchable, watchable and chartable in Markets; Luno-priced holdings with Yahoo fallback.
- Light + dark neumorphic themes (follow system, manual override).
- Adaptive layout (phone → desktop/web), desktop keyboard shortcuts.
- Export/backup (JSON full backup, CSV transactions) and restore.
- App lock (biometric where available + PIN).
- Thorough tests and CI.

### Out of scope (non-goals)
Android; broker/exchange API sync **other than Luno**; Luno on web; Luno order placement, sends, withdrawals, address/beneficiary management, conversions or any other write call (the only non-GET calls are the two permission probes in §7A); Luno websocket streaming; other exchanges; cloud sync/accounts; advanced analytics (TWR/XIRR, Sharpe/Sortino, drawdown, beta, correlation, benchmark comparison); price alerts/notifications; auto-polling or streaming prices; order placement; tax reporting; options-specific analytics; multi-language UI (English only; number, currency and date formatting is locale-aware through `intl`, but UI strings are written inline in widgets rather than in a localization catalogue).

## 3. Tech stack

Add all packages with `flutter pub add` (latest stable at implementation time) and commit the lockfile. Do not hand-write version numbers from this document.

| Concern | Package(s) | Notes |
|---|---|---|
| State / DI | `flutter_riverpod` (3.x) | Hand-written `Notifier`/`StreamProvider`s. `riverpod_generator`/`riverpod_lint`/`custom_lint` are **not** used: `custom_lint` could not resolve against Riverpod 3 and codegen added no value here |
| Models | Hand-written immutable classes; `build_runner` only for drift | Entities are small and manual `copyWith`/`toJson` keeps the domain layer free of codegen; Yahoo DTOs are parsed defensively by hand-written mappers |
| HTTP | `dio`, `dio_cookie_manager`, `cookie_jar` | Cookie jar only on native (Yahoo crumb) |
| Routing | `go_router` | `StatefulShellRoute`, path URLs on web |
| Database | `drift`, `drift_flutter`, `drift_dev` | Web: needs `sqlite3.wasm` + `drift_worker.js` in `web/` (see drift docs) |
| Money math | `decimal` | No `double` for quantities, prices, cash, FX |
| Charts | `fl_chart` | Line/area/pie/bar. Candlestick via fl_chart's candlestick chart if it supports crosshair + zoom/pan; otherwise a `CustomPainter` |
| Neumorphism | **Custom design system** | See §11. Do **not** use `flutter_neumorphic`/`flutter_neumorphic_plus` (abandoned / no web). Write an in-house inset-shadow painter; do **not** depend on `flutter_inset_shadow` (stale, unverified publisher) |
| Formatting | `intl` | Locale-aware currency, number, date |
| Files | `file_picker`, `file_saver`, `csv`, `path_provider` | Import and export, all platforms including web |
| App lock | `local_auth`, `flutter_secure_storage` | PIN hash in secure storage |
| Misc | `url_launcher`, `logging`, `crypto` (PIN hashing), `path` | |
| Luno (v2) | **No new packages.** Hand-written `LunoClient` on `dio`; `flutter_secure_storage` and `local_auth` for credentials/step-up | Do not add any third-party Luno package or OpenAPI-generated client (decision: hand-written, typed DTOs for only the endpoints used) |
| Fonts | Bundled assets: Inter (UI), tabular figures for numbers | No runtime font fetching (works offline, no web flash) |
| Test | `flutter_test`, `integration_test`, `mocktail` | |

`analysis_options.yaml`: `flutter_lints` + `strict-casts`, `strict-inference`, `strict-raw-types`; formatter page width 140. Zero analyzer issues is a gate.

## 4. Architecture

Feature-first clean architecture with three layers per the Flutter architecture guidance: **data → domain → presentation**.

```
lib/
  main.dart                  # bootstrap: ProviderScope, DB, logging
  app/                       # app.dart (MaterialApp.router, lifecycle, privacy cover), providers, refresh controller, settings
  core/                      # Result/AppFailure, Clock, logging, Decimal/format extensions, env
  design_system/             # tokens, NeuTheme, neu_* widgets, chart theme, gallery
  data/
    db/                      # drift database, tables, DAOs, converters, migrations
    net/                     # RequestScheduler (token bucket, de-dup, backoff, circuit breaker) shared by Yahoo + Luno (§8A)
    yahoo/                   # YahooClient (dio), DTOs, mappers, crumb manager
    luno/                    # LunoClient, DTOs, mappers, LunoCredentialStore, LunoPermissionProbe, LunoSyncService (§7A, §7B)
    repositories/            # implementations of domain interfaces (incl. RoutingMarketDataRepository, LunoMarketDataRepository)
  domain/
    entities/                # entities
    repositories/            # abstract interfaces (MarketDataRepository, PortfolioRepository, LunoRepository, ...)
    services/                # pure calculators (holdings, valuation, allocation, history, dividends, luno_ledger_mapper)
  features/
    shell/  dashboard/  portfolios/  holdings/  transactions/
    markets/  income/  import_export/  settings/  lock/
    luno/                    # connect wizard, connection list/detail, sync status (native only)
  routing/                   # router.dart, route names
proxy/                       # Cloudflare Worker for web CORS (§7)
test/                        # mirrors lib/; fixtures in test/fixtures/
integration_test/
```

Rules:
- `domain/` is pure Dart: no Flutter, dio, or drift imports. All financial math lives here.
- Presentation talks to repositories only through Riverpod providers wrapping domain interfaces.
- `Clock` and `MarketDataRepository` are injected so tests can fake time and prices.
- `MarketDataRepository` stays the single interface the UI uses. v2 provides `RoutingMarketDataRepository`, which dispatches symbols prefixed `LUNO:` to `LunoMarketDataRepository` and everything else to the Yahoo implementation; both write the same `quote_cache`/`price_history_cache`. Provider wiring happens in `lib/app/providers.dart`.
- Errors: sealed `AppFailure` (`network`, `rateLimited`, `notFound`, `parse`, `storage`, `unauthorized`; v2 adds `forbidden` (insufficient key permissions), `credentialsMissing`, `keyRevoked`, `secureStorageUnavailable`). Repositories return `Result<T>` or surface via `AsyncValue.error`. One shared `ErrorRetryView` widget handles all async error UI.
- Use Dart 3 features (records, patterns, sealed classes, switch expressions).

## 5. Data model (drift)

All decimals are persisted as TEXT through a drift `TypeConverter<Decimal, String>`. Dates are stored as UTC ints; trade dates as `yyyy-MM-dd` date-only values. `schemaVersion` starts at 1; every change ships a migration plus a `verifyMigration` test (use drift's schema dump workflow).

| Table | Columns |
|---|---|
| `portfolios` | id, name, description?, color, cost_basis_method (`average`\|`fifo`), sort_order, archived, created_at |
| `instruments` | symbol (PK, Yahoo symbol), name, quote_type, exchange, currency, sector?, industry?, last_meta_refresh |
| `transactions` | id, portfolio_id (FK), symbol, type, trade_date, quantity, price, fees, currency, fx_rate_to_base, notes?, import_batch_id?, created_at |
| `watchlists` | id, name, sort_order |
| `watchlist_items` | watchlist_id, symbol, sort_order |
| `quote_cache` | symbol (PK), payload_json, fetched_at |
| `price_history_cache` | symbol, interval, ts, open, high, low, close, adj_close, volume (PK: symbol+interval+ts) |
| `history_meta` | symbol, interval, oldest_ts, newest_ts, currency, fetched_at (PK: symbol+interval): which window of a series is cached and when |
| `profile_cache` | symbol (PK), payload_json, fetched_at |
| `dividend_events_cache` | symbol, ex_date, amount, pay_date? |
| `split_events_cache` | symbol, date, numerator, denominator |
| `import_mappings` | id, name, mapping_json |
| `settings` | key (PK), value |

**v2 additions (`schemaVersion` 1 → 2; ship migration, schema dump and `verifyMigration` test):**

| Table / change | Columns |
|---|---|
| `transactions` (+4 columns) | `source` (`manual`\|`csv`\|`luno`, default `manual`; backfill `csv` where `import_batch_id` is set), `connection_id` (nullable FK → `luno_connections`, `ON DELETE SET NULL`), `external_id` (nullable), `executed_at` (nullable UTC ms). Unique index on `(connection_id, external_id)` where both non-null |
| `luno_connections` | id, label, portfolio_id (FK → portfolios), key_id_hint (last 4 chars of key id only), home_fiat, status (`ok`\|`syncing`\|`error`\|`revoked`\|`credentials_missing`\|`needs_review`), last_sync_at?, last_error? (sanitised message, no secrets/IDs), write_perm_warning (bool), unrecognised_rows (int), created_at |
| `luno_account_cursors` | connection_id, account_id, asset, account_type, last_row_index, balance_snapshot, reserved_snapshot, unconfirmed_snapshot, synced_at (PK connection_id + account_id) |
| `luno_markets_cache` | pair (PK), base, counter, price_scale, volume_scale, trading_status, fetched_at |
| `luno_ledger_rows` | connection_id, account_id, row_index (PK), timestamp_ms, payload_json, state (`pending`\|`mapped`\|`unrecognised`): the raw ledger rows fetched from Luno, kept so syncs are resumable, trade legs can be paired across accounts, and the mapping can be re-run. Derived data: excluded from backups |

`transactions.type` ∈ `buy`, `sell`, `dividend`, `split`, `deposit`, `withdrawal`, `fee`, `opening_position`, and (v2) `transfer_in`, `transfer_out`, `reward`.
- `transfer_in` / `transfer_out`: crypto moved onto/off the platform (symbol set, `quantity` = amount, `fees` = network fee in the same asset, `price` = fiat market value per unit at `executed_at` for `transfer_in`, and the then-current cost basis is used for `transfer_out`).
- `reward`: Luno interest/earn payments received as crypto (`price` = fiat market value per unit at receipt); counted as income.
- Luno instruments: symbol `LUNO:{ASSET}{FIAT}` (e.g. `LUNO:XBTMYR`), `quote_type` `CRYPTOCURRENCY`, exchange `Luno`, currency = the connection's home fiat (one position per asset per connection), name from a built-in asset-name map (`XBT` → "Bitcoin", etc.; unknown assets use the code).
- Ordering of transactions everywhere is `(trade_date, executed_at ?? created_at, id)`.
- Rows with `source = luno` are read-only in the UI (notes are the only editable field) and are only created/updated/deleted by the sync service.
- FX pairs (e.g. `EURUSD=X`) are cached in `price_history_cache` like any other symbol, so there is no separate `fx_history_cache` table.

`opening_position` is how "manual positions" are entered: quantity + average cost, dated, treated as a buy for cost basis but flagged in the UI as "opening balance".
- `split`: `quantity` = numerator, `price` = denominator (e.g. 4:1 → 4 and 1).
- `fx_rate_to_base` is the rate (transaction currency → base currency) captured at entry (auto-fetched, editable). Changing the base currency recomputes from `fx_history_cache`/Yahoo, keeping any user-overridden rates.
- Deleting a portfolio deletes its transactions (confirm dialog). Archiving hides it from aggregate views by default.

Settings keys (v2 adds none for Luno; connection state lives in `luno_connections`, credentials only in the secure store): `base_currency` (default `USD`), `theme_mode`, `default_cost_method` (default `average`), `lock_enabled`, `lock_timeout_s`, `lock_biometric`, `proxy_url_override`, `last_refresh_at`, `hide_amounts` (reserved, not user-facing in v1), `disclaimer_accepted`.

## 6. Yahoo Finance integration

`MarketDataRepository` (domain interface) is implemented by `YahooMarketDataRepository` over `YahooClient` (dio) plus the drift caches. Swapping data providers later must only require a new implementation.

### Endpoints
| Purpose | Request | Crumb |
|---|---|---|
| History + events | `GET /v8/finance/chart/{symbol}?range=&interval=&events=div,splits&includePrePost=false` | no |
| Batch quotes | `GET /v7/finance/quote?symbols=A,B,...&crumb=` (≤ 50 symbols/call) | yes |
| Search | `GET /v1/finance/search?q=&quotesCount=10&newsCount=8` | no |
| Fundamentals / profile / calendar | `GET /v10/finance/quoteSummary/{symbol}?modules=price,summaryDetail,defaultKeyStatistics,assetProfile,calendarEvents&crumb=` | yes |
| FX | symbols like `EURUSD=X` via the quote/chart endpoints | per endpoint |

Hosts: `query1.finance.yahoo.com` / `query2.finance.yahoo.com` (round-robin on retry).

### Crumb/cookie handling (native)
1. `GET https://fc.yahoo.com` to obtain the session cookie (a 404 body is fine; keep the `Set-Cookie`).
2. `GET https://query1.finance.yahoo.com/v1/test/getcrumb` with the cookie → crumb string.
3. Cache crumb + cookie in memory; on 401/403 invalidate and retry once.
4. Send a realistic browser `User-Agent` on every request.

On **web** the proxy (§7) owns cookie/crumb; the client never sees them.

### Environment
- Native: base URL = Yahoo hosts directly.
- Web: base URL = `YAHOO_PROXY_URL` (`--dart-define=YAHOO_PROXY_URL=https://...`), overridable by `proxy_url_override` in Settings. If unset on web, show a blocking-but-dismissible banner explaining setup and render cache-only.

### Resilience
- In-flight request de-duplication keyed by URL.
- Batching and chunking of symbol lists.
- 15 s timeout; exponential backoff + jitter on 429/5xx, max 3 attempts.
- On persistent failure show *"Couldn't reach Yahoo — showing cached data from hh:mm"*; never blank the UI if a cache exists.

### Parsing quirks (must be handled and tested)
- Every field nullable; tolerate missing `regularMarketPreviousClose`, null candles in `indicators.quote[0]`, empty `result` arrays and `error` objects with HTTP 200.
- **Minor currency units:** `GBp`/`GBX` (pence), `ZAc`, `ILA` — divide by 100 and map to `GBP`/`ZAR`/`ILS`.
- Use `exchangeTimezoneName`/`gmtoffset` for day boundaries.
- Delisted/invalid symbols → `notFound`.
- Crypto and FX trade 24/7; "market closed" UI logic must not apply to them.
- Use `adjclose` only for return display on the quote chart; portfolio valuation uses raw close (+ explicit transaction-driven split/dividend handling).

### Fixtures
Record real responses into `test/fixtures/yahoo/` (chart equity, chart crypto, chart FX, GBp equity, quote batch, quoteSummary, search, error payloads). Parsing tests run only against fixtures — never the live network.

### Luno
Luno is a second `MarketDataRepository` backend for `LUNO:` symbols; see §7A. Call volume and retry rules for both providers are in §8A and supersede the "Resilience" bullets above where they differ (the Yahoo client is migrated onto the shared `RequestScheduler`, behaviour-preserving).

## 7. Web CORS proxy (`proxy/`)

The Worker has **no Luno routes** and must never receive or forward Luno credentials. Luno is unavailable on web (§7A). Browsers cannot call Yahoo directly. Ship a minimal **Cloudflare Worker** (TypeScript, ~100 lines) in `proxy/`:
- Route layout mirrors Yahoo paths (`/v8/finance/chart/*`, `/v7/finance/quote`, `/v1/finance/search`, `/v10/finance/quoteSummary/*`).
- **Allowlist** only those paths; reject everything else (no open proxy).
- Holds the Yahoo cookie + crumb server-side (module cache with TTL, refresh on 401) and injects `crumb`.
- Adds CORS headers for an `ALLOWED_ORIGINS` env var (comma-separated); handles `OPTIONS`.
- Edge-caches quotes 30 s, search 5 min, chart/history 1 h, quoteSummary 1 h.
- Files: `src/index.ts`, `wrangler.toml`, `package.json`, `tsconfig.json`, `README.md` (deploy with `wrangler deploy`, local dev with `wrangler dev`, how to set `YAHOO_PROXY_URL`).

## 7A. Luno integration (native only; v2)

### Platform availability
Available on iOS, macOS, Windows, Linux. On web the whole feature is hidden: no settings section, no routes (redirect), no Luno search results; synced data restored from a backup still renders (cache-only, Luno pairs priced from cache/Yahoo).

### Client (`lib/data/luno/luno_client.dart`)
- Base URL `https://api.luno.com`. HTTP Basic auth (key id : key secret), added per request by an interceptor that reads the secret from `LunoCredentialStore` just in time (§7B).
- Hardening: HTTPS only; exact host allowlist `api.luno.com` (reject anything else); `followRedirects: false`; no `badCertificateCallback`; 15 s timeout; no `LogInterceptor`; `DioException` text scrubbed of headers/URLs before logging or wrapping.
- Parsing: every price/amount is a decimal **string** → `Decimal.parse` (never `double`); timestamps are integer ms since UTC epoch → UTC `DateTime`; POST bodies (probes only) are `application/x-www-form-urlencoded`. All fields nullable-tolerant; unknown enum values map to an `unknown` member.
- Throttling, retries, de-duplication and circuit breaking come from the shared `RequestScheduler` (§8A).
- Error mapping: HTTP 401 or `ErrApiKeyRevoked` → `keyRevoked`; `ErrInsufficientPerms`/403 → `forbidden`; 429 → `rateLimited`; 5xx and `ErrClusterUnavailable` → `network` (retryable); `ErrNotFound`/`ErrAccountNotFound`/`ErrMarketUnavailable` → `notFound`; malformed payload → `parse`.

### Endpoints used (all read-only except the two probes)
| Purpose | Endpoint | Key permission |
|---|---|---|
| Accounts + balances | `GET /api/1/balance` (`account_id`, `asset`, `balance`, `reserved`, `unconfirmed`, `account_type`) | `Perm_R_Balance` |
| Ledger (source of truth) | `GET /api/1/accounts/{id}/transactions?min_row&max_row` (≤ 1000 rows per call; `kind` ∈ FEE, TRANSFER, EXCHANGE, INTEREST; `balance_delta`, `reference`, `description`, `details`, `row_index`, `timestamp`) | `Perm_R_Transactions` |
| Pending movements (client method exists; not yet shown in the UI) | `GET /api/1/accounts/{id}/pending` | `Perm_R_Transactions` |
| Order permission check (not used by sync; ledger FEE rows give exact fees) | `GET /api/1/listtrades?pair&limit=1` | `Perm_R_Orders` |
| Order history (**not implemented**) | `GET /api/exchange/2/listorders`, `GET /api/exchange/3/order` | `Perm_R_Orders` |
| Permission check; on-chain tx ids come from the ledger's `detail_fields.crypto_details` (the client method for transfers exists but sync does not call it) | `GET /api/exchange/1/transfers?account_id&limit=1` | `Perm_R_Transfers` (optional) |
| Permission check only | `GET /api/1/withdrawals?limit=1` | `Perm_R_Withdrawals` (optional) |
| Fee tier | `GET /api/1/fee_info?pair` | `Perm_R_Orders` |
| Tickers (multi-pair, repeated `pair=`) | `GET /api/1/tickers` | none |
| Market parameters and status | `GET /api/exchange/1/markets` | none |
| Candles | `GET /api/exchange/1/candles?pair&since&duration` (≤ 1000 candles per call; durations 60, 300, 900, 1800, 3600, 10800, 14400, 28800, 86400, 259200, 604800 s) | requires a key |
| Permission probes | `POST /api/1/stoporder`, `DELETE /api/1/withdrawals/{id}` | see below |

**Explicitly not implemented:** postorder, marketorder, send, send_fee, send/networks, address/validate, funding_address, accounts create/rename, beneficiaries, withdrawals POST, move, convert, users/linked, orderbook, trades (public), streaming API.

### Connect wizard (`features/luno/`, native only)
1. **Gate:** app lock must be enabled (else CTA to enable it first). Step-up auth (§7B) before showing the credential form.
2. **Instructions:** link to Luno's API-keys settings page (via `url_launcher`); recommend a *custom* key with only View balance, View transactions, View orders, View transfers, View withdrawals. Warn that Luno's "Read-only access" preset also includes "Send to any address".
3. **Credentials:** key id + secret fields (secret obscured, no autofill/suggestions/IME learning, write-only).
4. **Validate:** `GET /balance` (401 → "invalid key"); check required permissions `R_Balance`, `R_Transactions`, `R_Orders` (a `forbidden` on ledger/listtrades fails the step); `R_Transfers`/`R_Withdrawals` optional (degrade: no on-chain detail/network-fee linkage).
5. **Write-permission probes** (`LunoPermissionProbe`, the only non-GET code in the codebase; isolated, unit-tested, and a CI test greps `lib/data/luno/` for any other non-GET call):
   - `POST /api/1/stoporder` with a random non-existent `order_id` (`BXDASHFOLIOPROBE…`): `ErrInsufficientPerms`/403 → `Perm_W_Orders` absent (good). `ErrCannotStopUnknownOrNonPendingOrder`/`ErrOrderNotFound` → permission **present** → reject the key.
   - `DELETE /api/1/withdrawals/0`: `ErrInsufficientPerms`/403 → `Perm_W_Withdrawals` absent (good). `ErrWithdrawalNotFound`/404 → permission present → reject the key.
   - `Perm_W_Send` cannot be probed safely: never call `/send`. Always show a warning card and set `write_perm_warning`.
   - Probes run only at connect and key replacement; if the probe result is ambiguous (network error), do not proceed.
6. **Name + home fiat:** label (default "Luno"), home fiat auto-detected from the fiat account with the most ledger activity (editable; MYR for the maintainer). A portfolio "Luno – {label}" is created (cost method `average`, colour default, `luno_connections.portfolio_id`).
7. **First sync** with progress (accounts, rows, ETA), cancel and resume (§8A).

### Ledger sync (`LunoSyncService` in `data/luno/`, mapping in pure `domain/services/luno_ledger_mapper.dart`)
1. `GET /balance` → upsert `luno_account_cursors`; if balance, reserved and unconfirmed equal the snapshot and no pending rows exist, skip that account (§8A).
2. Per account, page the ledger from `last_row_index + 1` in windows of 1000 rows (`min_row`/`max_row`) until caught up; commit the cursor per page.
3. Mapping by `kind` and sign of `balance_delta` (account asset decides fiat vs crypto):
   | Ledger | Becomes |
   |---|---|
   | TRANSFER, fiat, positive / negative | `deposit` / `withdrawal` |
   | TRANSFER, crypto, positive / negative | `transfer_in` / `transfer_out` (network fee and tx id from `/transfers` when available) |
   | INTEREST | `reward` |
   | FEE, fiat | `fee` (no symbol) |
   | FEE, crypto | `fee` with symbol (reduces quantity) |
   | EXCHANGE | paired across the base-asset and counter-asset accounts by `reference` (fallback: identical timestamp) into one `buy`/`sell` of `LUNO:{BASE}{FIAT}`; price = \|counter Δ\| / \|base Δ\| |
   **One position per asset per connection:** every transaction for asset X uses the symbol `LUNO:{X}{homeFiat}` and the home fiat as its currency. A trade paid in another fiat is converted to the home fiat at that day's rate and annotated "Paid in USD", so a later send or fee always draws down the same position. Fees come from the ledger's own `FEE` rows that share the trade's `reference` (fiat fees attach to the trade; crypto fees become a `fee` of the asset); an amount the ledger already netted stays embedded in the derived price. Crypto↔crypto trades (e.g. `ETHXBT`) become a `sell` of one position and a `buy` of the other, valued in the home fiat at trade time from the daily series (held back with a warning if no price exists yet).
4. `external_id` = `{account_id}:{row_index}` (paired trades: lower of the two ids joined with `+`). Upserts are idempotent; each page is written in one DB transaction so a crash never half-books a trade.
5. `fx_rate_to_base` at `executed_at` is captured as for manual rows (Yahoo history; existing `BaseCurrencyRebaser` rules apply).
6. Reconcile (§9). Set status `ok` or `needs_review`, `last_sync_at`.
7. Unknown ledger shapes are booked as nothing, counted in `unrecognised_rows`, logged without amounts or ids, and listed (description text only) in the connection detail screen so mappings can be extended from live fixtures.
8. Concurrency: one sync per connection at a time; connections sync sequentially.

### Market data (`LunoMarketDataRepository`; writes shared caches)
- **Quote:** `price` = `last_trade`; bid/ask; `rolling_24_hour_volume`; `previousClose`, open and the day's range from the cached daily candles (last close before today, UTC; no extra candle request); `marketState` from ticker `status` (ACTIVE → REGULAR, POSTONLY, DISABLED); 24/7, so "market closed" logic never applies. Currency = counter fiat.
- **Chart ranges → Luno candle duration:** 1D 300 s, 5D 1800 s, 1M 14400 s, 3M/6M/YTD/1Y 86400 s, 5Y/MAX 604800 s. Daily history for valuation uses 86400 s candles.
- **Candles require a key.** With no connection, Luno pairs still have tickers; chart/history fall back to Yahoo `{ASSET}-{FIAT}` (`XBT` → `BTC`), labelled "via Yahoo".
- **Search:** filter cached markets by base/counter code and asset name; results grouped under "Luno".
- **Pricing of holdings:** a holding of asset X in a Luno portfolio is priced from `LUNO:{X}{homeFiat}`; if that pair does not exist, `{X}XBT` × `XBT{homeFiat}`, then `{X}USDC`/`{X}USDT` converted via FX, then Yahoo `{X}-{homeFiat}`. Fiat balances (the home fiat) are cash.
- **Fees:** `fee_info` shown on the Luno quote screen when connected (lazy, cached 24 h).

### Disconnect and revocation
- Status `revoked` (401/`ErrApiKeyRevoked`) or user "Disconnect": the secret is wiped immediately, syncing stops, and the user chooses **Keep as manual portfolio** (rows become `source = manual`, unlocked, `connection_id` cleared) or **Delete portfolio and its synced transactions** (confirmation). Cursors for the connection are deleted either way.
- Replacing a key (e.g. after revocation) requires step-up and re-runs validation and probes; the new key must belong to the same Luno user (matched by the set of `account_id`s) or the user must create a new connection.

## 7B. Credential security (v2)

Standards basis: OWASP MASVS (STORAGE, CRYPTO, NETWORK, AUTH, PLATFORM) and the platform guidance for keychain/credential storage. Credentials are the Luno **key id** and **key secret**.

### Storage
- Key id + secret live only in `flutter_secure_storage`, keys `dashfolio.luno.{connectionId}.keyId` and `.secret`. They are **never** stored in drift, `settings`, backups/exports, logs, crash output, clipboard, analytics or Riverpod state (providers expose only `key_id_hint` and status). The DB keeps only the last 4 characters of the key id.
- Per-platform options:
  | Platform | Backing store | Options |
  |---|---|---|
  | iOS | Keychain | `KeychainAccessibility.unlocked_this_device`, `synchronizable: false` (no iCloud Keychain, not restored to other devices) |
  | macOS | Legacy (file-based) login keychain | `usesDataProtectionKeychain: false`, as the PIN today (no Apple Developer Team available). App Sandbox stays on. Upgrade path: Data Protection keychain with a `keychain-access-groups` entitlement once the app is signed with a team; migrate the PIN at the same time |
  | Windows | `flutter_secure_storage` Windows backend (per-user DPAPI/credential store) | verify the backend at implementation time and document it |
  | Linux | libsecret (Secret Service) | if the service is missing or locked → `secureStorageUnavailable` and **refuse to connect**; never fall back to plaintext or a file |
  | Web | none | feature disabled |
- All reads/writes are wrapped; any storage failure surfaces as `secureStorageUnavailable`, never silently as "no key".

### In memory and UI
- The secret is read per request inside the auth interceptor; it is not cached in long-lived objects. The `Authorization` header is built per request and never logged. Dart strings cannot be zeroised; this limitation is documented.
- Credential text fields: obscured secret, `autocorrect: false`, `enableSuggestions: false`, `enableIMEPersonalizedLearning: false`, no autofill hints; controllers are cleared and disposed immediately after save. The secret is **write-only**: it is never displayed again after saving; only `…{last4}` of the key id is shown.
- The existing privacy cover applies to the connect and connection screens.

### Gating and step-up
- Connecting requires the app lock to be enabled. Disabling the app lock while connections exist forces *Disconnect all Luno connections* (wipes secrets) or cancels.
- **Step-up authentication** (biometric where available, else PIN, via the existing lock controller; a fresh check even if the app is unlocked) before: opening the credential form, replacing a key, disconnecting, and restoring a connection after backup restore. Step-up must not be satisfiable by a cached unlock older than 60 s.
- "Reset app" and Forgot-PIN → "Reset app" wipe all Luno secrets along with local data.

### Network
HTTPS only to `api.luno.com`, OS trust store, no certificate pinning (decision: avoids outages on certificate rotation), no custom proxies or redirect following with credentials.

### Backup / restore
JSON backups include connection metadata (label, home fiat, key id hint, status) and synced transactions (`source`, `connection_id`, `external_id`, `executed_at`) but **never** credentials. Restored connections are `credentials_missing` (portfolio read-only, no sync) until the user re-enters a key with step-up.

### Failure behaviour
`keyRevoked`, `forbidden`, `credentialsMissing` and `secureStorageUnavailable` are shown as a status chip on the connection and portfolio, never as a blocking error; cached data keeps rendering and Yahoo refresh continues.

### Threat model (summary)
| Threat | Mitigation |
|---|---|
| Lost/stolen unlocked-then-locked device | Secure store accessible only when unlocked, this device only; app lock + step-up |
| Malware / another app reading app data | Secrets never in DB/prefs/files; sandbox; key is read-only (probes enforce) |
| Leakage via logs, crash reports, clipboard | No header/URL logging, scrubbed exceptions, write-only field, tests assert on captured logs |
| Backup / export leakage | Credentials excluded by construction; backup test greps for key id/secret |
| MITM | TLS only, OS trust, host allowlist, no redirects |
| Over-privileged key | Rejection of keys with order/withdrawal write permission; warning for send permission; guidance to build a custom key |
| Shoulder surfing / screenshots | Obscured field, privacy cover, secret never re-displayed |

## 8. Refresh and caching

- **Manual refresh only.** Triggers: app launch (only if `last_refresh_at` older than 15 min), refresh button, pull-to-refresh on touch devices, `Cmd/Ctrl+R`.
- A refresh collects the distinct symbols across all non-archived portfolios and watchlists, plus needed FX pairs, fetches quotes in batches, writes `quote_cache`, updates `last_refresh_at`. A linear progress indicator shows state; partial failures don't discard successes.
- **v2 order:** (1) sync every healthy Luno connection (sequential; native only), (2) quotes for Yahoo and `LUNO:` symbols (one Luno `tickers` call + Yahoo batches), (3) FX, profiles, incremental daily history (Luno 86400 s candles for `LUNO:` symbols). A failing connection or Luno outage never blocks the Yahoo steps (and vice versa); the Luno status shows on the portfolio and in Settings → Luno. Each connection also has "Sync now" in Settings.
- UI always renders from cache first (offline-capable) and shows a *"Updated hh:mm"* chip; amber when older than 1 trading day (or 15 min after a manual-refresh-on-open window), red-tinged on failed refresh.
- History is fetched lazily per symbol/range when a chart opens, then cached; daily series are incremental (only fetch dates after the newest cached row). Intraday (1D/5D) is cached with a short TTL and not used for portfolio history.
- Cache can be cleared in Settings (does not touch user data).

## 8A. API call optimisation and rate-limit hygiene (Yahoo and Luno; v2)

Goal: minimise request volume and never trip provider limits. Implemented once in `lib/data/net/` as `RequestScheduler` (per-host token bucket and concurrency cap, in-flight de-duplication keyed by method + URL, `Retry-After`-aware backoff with full jitter, circuit breaker) and used by `YahooClient` (refactored, behaviour-preserving) and `LunoClient`.

### Shared rules
- **Never fetch what is fresh.** Every call passes a cache check first (TTLs below); a refresh only requests stale symbols/accounts. A manual refresh within 30 s of the previous completed one is a no-op (debounced; the UI says "Already up to date").
- **Batch and coalesce.** Multi-symbol endpoints for all symbols in one call (chunked at the provider limit); concurrent callers of one resource share a single in-flight future.
- **Incremental by cursor.** History and ledgers fetch only after the newest cached point; never refetch full ranges.
- **Backoff.** On 429/5xx honour `Retry-After` when present, else exponential backoff with full jitter, max 3 attempts. Repeated 429s open a per-host circuit (60 s, doubling to 10 min) that serves from cache with the existing "Couldn't reach … — showing cached data from hh:mm" message. Lazy work (profiles, history, fee info) yields to user-initiated calls.
- **Priority queue.** User-initiated (open screen, manual refresh) > refresh pipeline > lazy/background.
- **Observability.** Debug-only per-host counters (requests, cache hits, 429s, retries) in the gallery/log; never credentials or amounts.
- **Budget tests.** Fake-dio tests assert exact request counts: cold start with N holdings, warm refresh with nothing stale (0 Yahoo calls), repeat refresh within 30 s (0 calls), Luno incremental sync with no new activity (1 call per connection). A regression in call volume fails CI.

### Yahoo (unofficial, aggressive limits)
- Per-host bucket ≈ 2 req/s, burst 4, max 4 concurrent across `query1`/`query2` round-robin.
- Quotes in batches of 50 (one call per refresh for ≤ 50 symbols; FX pairs ride in the same batches). TTLs: quote 30 s (equal to the 30 s refresh debounce), quoteSummary/profile 24 h, daily history 6 h (incremental from `history_meta.newest_ts`, skip if `fetched_at` within TTL), intraday 2 min.
- Crumb + cookie reused for the session and refreshed only on 401/403 (single-flight); stable realistic `User-Agent`.
- Search debounced 300 ms with a 5-minute in-memory LRU of query → results. No requests while the circuit is open.

### Luno (documented limit: 300 calls/min per key, 429 beyond; market data may be cached ≤ 1 s server-side)
- One shared bucket at **240 req/min** (80 % headroom), max 2 concurrent; public calls (tickers, markets) use the same bucket.
- `GET /balance` once per sync; **skip an account's ledger fetch when balance, reserved and unconfirmed equal the cursor snapshot** and nothing is pending, so a no-activity sync costs one call per connection.
- Ledger in 1000-row pages from the cursor, staged locally so an interrupted first sync resumes page by page. Trades, transfers and withdrawals are *not* fetched during sync (the ledger carries everything needed), which keeps a full sync to `1 + ⌈rows/1000⌉` calls per changed account.
- Tickers: one `GET /tickers` with repeated `pair=` for all needed pairs (TTL 60 s, never < 1 s). Markets cached 24 h. `fee_info` lazy (quote screen only), 24 h. Candles incremental from the newest cached candle using the coarsest duration that serves the view, ≤ 1000 per call. Probes only at connect/key replacement.
- First full sync is resumable (cursor committed per page), throttled by the bucket, shows progress/ETA; persistent 429 pauses it and resumes on the next refresh. Multiple connections sync sequentially.

## 9. Calculations (`domain/services/`, pure Dart)

All use `Decimal`. Every function is unit tested; target 100% line coverage for this folder.

### Holdings engine
Replays a portfolio's transactions in `(trade_date, created_at)` order, per symbol:
- **Quantity** — buy/opening add, sell subtract, split multiplies (`qty × num/den`) and divides per-share cost accordingly.
- **Cost basis** — per portfolio setting:
  - `average`: running weighted-average cost per share (fees capitalized into buys, deducted from sell proceeds).
  - `fifo`: lot queue; sells consume oldest lots first; lots exposed to the holding-detail screen.
- **Realized P&L** — on each sell: proceeds − fees − consumed cost basis; reported in base currency using each transaction's `fx_rate_to_base`.
- **Dividends received** — sum of `dividend` transactions (amount = quantity × price, or price as total when quantity is 0).
- **v2 transaction types:**
  - `transfer_in`: adds quantity; cost basis = fiat market value at `executed_at` (Luno candle close, else Yahoo daily close); not a cash flow.
  - `transfer_out`: removes quantity at current cost basis (average or FIFO) with **no realized P&L**; the network fee (`fees`, in the asset) removes additional quantity and is expensed as a realized loss at cost.
  - `reward`: adds quantity with cost basis = market value at receipt; counted as income (dividends-like) in totals and the Income tab, excluded from projected annual income.
  - `fee` with a symbol (crypto fee): reduces quantity, cost expensed as realized loss; `fee` without a symbol is a fiat cash outflow as before.
  - Crypto↔crypto trades are booked as a sell and a buy at the same `executed_at` (see §7A).
- **Reconciliation (Luno portfolios):** after each sync, engine quantity per asset must equal Luno `balance + reserved` (`unconfirmed` excluded). A mismatch sets the connection to `needs_review`, shows a data warning on the portfolio with the per-asset delta, and **never auto-adjusts**. In-flight trades (listtrades may lag) are re-checked on the next sync before being flagged persistently.
- Dividend detection, split prompts and `calendarEvents` skip `LUNO:` symbols; allocation asset class for `CRYPTOCURRENCY` is "Crypto".
- Selling more than held is rejected at input time; the engine, if it encounters it from imports, clamps and flags the row as a data warning rather than crashing.

### Valuation
- Market value (base) = `quantity × lastPrice × fx(currency → base)`.
- Day change = `quantity × (price − previousClose) × fx`; %, relative to previous-close value.
- Unrealized P&L = market value − cost basis (cost basis converted at each lot's historical FX; use the transaction's `fx_rate_to_base`).
- Total return = unrealized + realized + dividends.
- Portfolio and aggregate totals: value, day change (abs/%), unrealized, realized, dividend income, cash balance (deposits − withdrawals − fees ± trade cash flows).

### Allocation
Group by: holding, asset class (`quote_type`), sector, currency, exchange/region. Weights sum to 100 %; groups under 2 % collapse into "Other" in the donut but remain in the legend/table.

### Value history
Daily series per range (1W, 1M, 3M, YTD, 1Y, 5Y, MAX): for each date, holdings-as-of-date × daily close × daily FX. Weekends/holidays forward-fill. Missing history for a symbol → skip that symbol for that date and flag the chart with an "incomplete data" footnote. Computation runs in an isolate (`compute`) for large portfolios.

### Dividends & splits
- **Received:** from `dividend` transactions.
- **Detected (unrecorded):** Yahoo dividend events × quantity held on the ex-date, minus already-recorded dividends for that symbol/date; one tap records it.
- **Upcoming:** `calendarEvents` ex/pay dates for held symbols.
- **Projected annual income:** trailing-12-month dividend per share × current quantity (base currency); yield on cost = projected / cost basis.
- **Splits:** Yahoo split events for held symbols occurring after the first purchase and not yet recorded raise a prompt to add a `split` transaction.

## 10. Screens and UX

### Adaptive shell
| Width | Navigation | Content |
|---|---|---|
| < 600 (compact) | Bottom `NeuNavBar` | Single column |
| 600–1199 (medium) | `NeuRail` | 2-column grids |
| ≥ 1200 (expanded) | Collapsible `NeuSidebar` | 12-column dashboard grid, side panels |

Destinations: **Dashboard · Portfolios · Markets · Income · Settings**. Top bar: portfolio selector (where relevant), refresh button + "Updated" chip, global search (`Cmd/Ctrl+K`).

### Dashboard
Portfolio selector (All / each) · hero card (total value, day change abs/%, total P&L) · value-history area chart with range selector and crosshair tooltip · allocation donut with group-by toggle · top movers (gainers/losers today) · compact holdings table · recent transactions. On wide screens a 12-column grid of `NeuCard`s; on phones a vertical stack.

### Portfolios
- List: name, total value, day change, mini sparkline; create / edit / archive / reorder (drag).
- Detail: tabs **Holdings · Transactions · Allocation**. Holdings table columns: symbol, name, quantity, avg cost, price, day %, market value, unrealized P&L (abs, %), weight; sortable, tap-to-open; on compact, collapse to a two-line row with a column-picker.
- **Holding detail:** position stats, lots (FIFO) or average-cost summary, symbol's transactions, price chart with buy/sell markers.

- **Luno-synced portfolios (v2):** a "Luno · synced hh:mm" badge (with status chip for `error`/`revoked`/`needs_review`/`credentials_missing`); transactions are read-only (notes editable); add/edit/delete/CSV-import are disabled with an explanatory tooltip; holding detail shows Luno trade markers and order ids; the reconciliation warning lists per-asset deltas.

### Transaction form (modal sheet / dialog)
The type picker also offers `transfer_in`, `transfer_out` and `reward` (v2) for manual portfolios; they are unavailable in Luno-synced portfolios.
Symbol autocomplete (Yahoo search, debounced 300 ms) · type · date · quantity · price (prefilled with the close on that date when available) · fees · currency (from instrument) · FX rate (auto-fetched, editable) · notes. Validation: positive numbers; sell ≤ held quantity at that date; date not in the future. "Add position" shortcut creates an `opening_position`. Editing/deleting any transaction recalculates everything.

### Markets
- **Search/command palette** (`Cmd/Ctrl+K`): symbols grouped by type, recent searches; on native, Luno pairs appear in a "Luno" group (v2).
- **Luno quote detail (v2):** same screen as any quote plus bid/ask/spread, 24 h volume, market status (ACTIVE/POSTONLY/DISABLED), Luno fee tier when connected, 24/7 (no market-closed state), "via Yahoo" label when the chart falls back.
- **Watchlists:** multiple, reorderable; columns: price, change, %, day range, volume, market cap; add/remove with swipe (touch) or context menu (desktop).
- **Quote detail:** header (name, price, change, market state), line/candle toggle, ranges 1D / 5D / 1M / 6M / YTD / 1Y / 5Y / MAX, volume subchart, crosshair with OHLC readout, key stats (open, range, 52-week range, market cap, P/E, EPS, dividend yield, beta), profile, upcoming events, news list (opens with `url_launcher`), actions "Add to watchlist" / "Add to portfolio".

### Income
**Rewards (v2):** Luno interest/earn rewards by month and by asset, shown beside dividends and included in income totals, excluded from projected annual income · Dividends received by month (bar chart, 12 months) and by symbol (ranked list) · upcoming dividends list/calendar · detected-unrecorded dividends with one-tap record · projected annual income and yield on cost.

### Import / export
- **CSV import wizard:** pick file → choose or save a column-mapping preset (generic columns: date, symbol, type, quantity, price, fees, currency, notes; map type aliases such as `BUY`/`Purchase`) → set date and decimal formats → preview with per-row validation errors and duplicate detection → commit as one `import_batch_id`. A committed batch can be undone from the Transactions tab.
- **Export:** full JSON backup (versioned `schema_version`, includes portfolios, transactions, watchlists, settings except lock secrets), transactions CSV.
- **Restore:** from JSON, *replace* or *merge* with explicit confirmation and a summary.

### Settings
Base currency · theme (System/Light/Dark) · default cost method · app lock · Yahoo proxy URL (web only) · **Luno connections (native only, v2):** list with status, last sync, key id hint, "Sync now", rename, change home fiat, replace key (step-up), disconnect (keep/delete choice), unrecognised-rows viewer, and the connect wizard (§7A) · clear cache · import/export/restore · about, disclaimer, open-source licenses.

### App lock
Opt-in. Biometrics via `local_auth` where available (iOS Face/Touch ID, macOS Touch ID, Windows Hello) with a 4–6 digit PIN fallback on all platforms (salted hash in `flutter_secure_storage`; on web the PIN is a convenience screen only and the UI says so; Linux has no biometrics). Locks on cold start and after a configurable background timeout (default 1 min). Content is obscured in the app switcher where the platform allows. 5 failed PIN attempts → escalating cooldown. Forgot PIN → "Reset app" (wipes local data) after confirmation.

### Desktop & input
Shortcuts: `Cmd/Ctrl+R` refresh · `Cmd/Ctrl+K` search · `Cmd/Ctrl+N` new transaction · `Cmd/Ctrl+1…5` navigate · `Esc` closes dialogs. Hover states, right-click context menus on table rows, full keyboard focus traversal.

### States
Every async view has skeleton loaders (soft neumorphic shimmer), a meaningful empty state with a primary action (e.g. "Add your first transaction"), and the shared error/retry view. First run: disclaimer → base currency → "Create portfolio" / "Import CSV".

## 11. Neumorphic design system (`lib/design_system/`)

> A second, Cupertino skin for iOS and macOS (user-selectable in Settings) is specified in `SPEC_CUPERTINO.md`.

Custom, on top of Material 3 `ThemeData` (light + dark) so stock widgets inherit the look.

### Tokens (`NeuTheme extends ThemeExtension`)
- Surface, raised-shadow (light source top-left) and sunken-shadow colors.
  - Light: surface ≈ `#E6EBF1`, highlight `#FFFFFF`, shadow `#A3B1C6`.
  - Dark: surface ≈ `#22262E`, highlight `#2C313A`, shadow `#16191F`.
- Depth levels 0–4 (blur and offset per level), radii 8 / 12 / 20, 4-pt spacing scale, type scale (Inter; tabular figures for all numeric text).
- Semantic colors: `gain`, `loss`, `neutral`, `accent`, `warning` — gain/loss/accent text meets ≥ 4.5:1 on the surface in both themes; verify with a unit test using a contrast helper.

### Primitives
Inner shadows are implemented in-house with a `CustomPainter`/`DecoratedBox` clip-and-offset-blur technique (no external inset-shadow package).

### Widgets
`NeuSurface` (flat · convex · concave · pressed) · `NeuCard` · `NeuButton` / `NeuIconButton` (animated press → inset) · `NeuSwitch` · `NeuSegmentedControl` · `NeuTextField` (inset) · `NeuDropdown` · `NeuChip` · `NeuSlider` · `NeuProgress` · `NeuNavBar` / `NeuRail` / `NeuSidebar` · `NeuDataTable` · `NeuDialog` / `NeuSheet` · `NeuTooltip` · `NeuSkeleton` · `ChangeBadge` (▲/▼ + color — never color alone) · `MoneyText` (tabular figures, currency-aware).

### Rules
- **Accessibility:** neumorphic depth is decoration — meaning is always carried by text/icons with sufficient contrast; visible focus rings; `Semantics` labels on charts and badges; respect reduced motion and OS text scaling; ≥ 44 px hit targets.
- **Performance:** cap blur radius; wrap charts and table rows in `RepaintBoundary`; inside long scrolling lists and on web use a flat/low-shadow variant; avoid nested shadow stacks.
- **Gallery:** a debug-only `/gallery` route (and widget previews) renders every component in both themes; goldens are generated from it.

## 12. Routing (go_router)

`StatefulShellRoute.indexedStack` so each tab keeps state.

```
/dashboard
/portfolios                                 /portfolios/:id
/portfolios/:id/holdings/:symbol
/markets                                    /markets/quote/:symbol
/markets/watchlists/:id
/income
/settings                                   /settings/import
/settings/luno  /settings/luno/connect  /settings/luno/:id     (native only; redirect to /settings on web)
/lock                                       (lock gate via redirect)
/gallery                                    (debug only)
```
Web uses path URL strategy; unknown routes show a friendly not-found page.

## 13. Testing and CI

- **Unit:** holdings engine (average/FIFO, partial sells, splits, fees, multi-currency, GBp), valuation, allocation, value-history reconstruction, dividend detection, CSV parsing/mapping, Yahoo DTO parsing from fixtures, crumb/retry logic with a mocked dio, contrast helper.
- **Repository/DB:** drift in-memory tests, migration tests (v1 → v2 with data backfill).
- **Luno (v2), all against `test/fixtures/luno/` and fakes, never the live network:**
  - DTO/mapper parsing (balance, ledger of every `kind`, listtrades, transfers, tickers, markets, candles, error payloads); fixtures recorded live from the maintainer's read-only MYR key and **scrubbed** (account/order/trade ids, tx hashes, addresses replaced deterministically; amounts perturbed consistently) with a `README.md` describing provenance.
  - `LunoLedgerMapper`: deposits/withdrawals, instant buy/sell, exchange orders with fees, crypto↔crypto, transfers in/out with network fees, interest, fiat/crypto fees, unrecognised rows, idempotency by `external_id`.
  - Holdings engine: new tx types in average and FIFO, no-P&L `transfer_out`, reward income, reconciliation delta.
  - `LunoSyncService`: paging/cursors, resume after kill, skip-unchanged-account, partial failure, revoked key, 429 handling.
  - Permission probe: all outcomes (absent / present / ambiguous); test that no non-GET request exists in `lib/data/luno/` outside the probe.
  - Credential store and security: `FakeCredentialStore`; assertions that secrets never appear in DB files, backup JSON or captured log records; step-up and lock gating; disconnect wipes; web hides the feature.
  - `RequestScheduler`: bucket, concurrency, de-dup, `Retry-After`, circuit breaker; request-budget tests for Yahoo and Luno (§8A).
  - Market data: routing by `LUNO:` prefix, quote/candle mapping, pair fallback chain, Yahoo fallback.
- **Widget:** dashboard, holdings table sorting, transaction form validation, import wizard, lock screen — with Riverpod overrides and fakes.
- **Golden:** every Neu* component, light + dark.
- **Integration (`integration_test/`):** create portfolio → add transaction → dashboard shows expected totals, with a fake `MarketDataRepository`.
- **Coverage targets:** ≥ 90 % `domain/`, ≥ 70 % overall.
- **CI (`.github/workflows/ci.yml`):** format check · `flutter analyze` · `custom_lint` · `build_runner` + `git diff --exit-code` (generated code current) · tests with coverage · builds: web + linux (ubuntu), windows (windows-latest), macos + `ios --no-codesign` (macos-latest) · proxy `tsc --noEmit`.

## 14. Platform notes

- **macOS:** add `com.apple.security.network.client` to Debug and Release entitlements; keychain entitlement for secure storage.
- **iOS:** `NSFaceIDUsageDescription`; keychain for secure storage.
- **Windows:** Windows Hello through `local_auth`.
- **Linux:** `libsecret` for secure storage (document `libsecret-1-dev`); no biometrics.
- **Luno credential storage (v2):** see the per-platform table in §7B. iOS: device-only, non-synchronizable keychain; macOS: legacy file keychain (no team); Windows: verify backend; Linux: `libsecret` required for Luno (no fallback). Web: Luno disabled.
- **Web:** drift needs `web/sqlite3.wasm` and `web/drift_worker.js`; file import/export via `file_picker`/`file_saver`; `YAHOO_PROXY_URL` dart-define.
- App name/display name "Dashfolio", bundle identifiers set consistently, replace default icons.

## 15. Implementation milestones

Complete in order; each ends with analyzer clean + its tests green.

1. **Setup:** dependencies, lints, folder structure, fonts, CI skeleton, platform entitlements.
2. **Design system:** tokens, `NeuTheme`, widgets, gallery route, golden tests.
3. **Database:** drift schema, converters, DAOs, migrations test, settings repository.
4. **Yahoo layer:** client, crumb manager, DTOs, fixtures, `MarketDataRepository` + caches; `proxy/` worker.
5. **Domain services:** holdings, valuation, allocation, history, dividends — full unit tests.
6. **Shell & routing:** adaptive navigation, theme switching, first-run flow.
7. **Portfolios, holdings, transactions:** CRUD, forms, tables, holding detail.
8. **Dashboard:** hero, history chart, allocation, movers, refresh flow.
9. **Markets:** search, watchlists, quote detail (line + candles, stats, news).
10. **Income:** dividends views, detection, projections.
11. **Import/export:** CSV wizard, JSON backup/restore, CSV export.
12. **App lock.**
13. **Polish:** empty/error/skeleton states, shortcuts, accessibility audit, web performance pass, integration tests, README.

**v2 (Luno)** — continue in order; each ends with analyzer clean + its tests green:

14. **Schema v2:** new columns/tables/tx types, migration + `verifyMigration`, engine ordering and new tx-type rules with unit tests (domain coverage stays ≥ 90 %).
15. **Request scheduler + Luno client:** shared `RequestScheduler` (§8A) with `YahooClient` migrated onto it and request-budget tests; `LunoClient`, error mapping, DTOs/mappers, `LunoCredentialStore`, `LunoPermissionProbe`. Record fixtures live with the maintainer's read-only MYR key, scrub them, commit to `test/fixtures/luno/` with a README.
16. **Ledger sync + reconciliation:** `LunoLedgerMapper` (pure, fixture-driven), `LunoSyncService`, idempotency, resume.
17. **Luno market data + routing repository:** quotes, candles, search, pricing fallback chain, Yahoo fallback; refresh pipeline integration.
18. **UI:** Settings → Luno, connect wizard, synced-portfolio read-only states, Rewards in Income, Luno quote details, web hiding.
19. **Security hardening + docs:** lock gating, step-up, backup-exclusion and log-leak tests, reset wipe, platform storage options verified per platform, README (how to create a read-only Luno key), `CLAUDE.md` (Luno gotchas, fixtures path), §18 v2 status.

## 16. Acceptance criteria

- App builds and launches on iOS, macOS, Windows, Linux and Web; `flutter analyze` and `custom_lint` report zero issues.
- Totals (value, day change, unrealized/realized P&L, dividends) match hand-calculated fixtures exactly (decimal equality) for average and FIFO methods, including splits and multi-currency cases.
- With a previously populated cache and no network, every screen renders and shows a stale/offline indicator; refresh failures never wipe data.
- Web build loads live data through the deployed proxy and fails gracefully (cache-only banner) when `YAHOO_PROXY_URL` is missing.
- A CSV with ≥ 1,000 rows imports with a per-row preview, flags invalid/duplicate rows, and can be undone as a batch.
- JSON backup → wipe → restore reproduces identical totals.
- Light and dark themes pass contrast checks and golden tests; all primary flows are keyboard-operable on desktop.
- Dashboard with 5 portfolios / 500 holdings stays responsive (no jank > 16 ms/frame in profile mode on desktop; value-history computed off the UI thread).
- App lock gates content on cold start and after timeout; PIN is never stored in plain text.
- Coverage targets in §13 met; CI green on all jobs.

**v2 (Luno):**
- For the maintainer's live MYR account, synced portfolio quantities equal Luno `balance + reserved` per asset (or the delta is flagged with a documented cause); re-running sync is idempotent (no duplicate rows).
- A first full sync of ≥ 10,000 ledger rows never exceeds 300 req/min and is resumable after the app is killed.
- Request-budget tests pass for Yahoo and Luno: a warm refresh with nothing stale makes 0 Yahoo calls and 1 Luno call per connection; a repeat refresh within 30 s makes none; no scenario exceeds a host's bucket.
- A key with order or withdrawal write permission is rejected; no non-GET request exists in `lib/data/luno/` other than the two probes (enforced by test).
- Secrets never appear in the database, backups, exports or captured logs (enforced by tests); disconnect removes the keychain entry.
- Connecting is impossible without app lock; replace/disconnect require step-up.
- Luno UI is absent on web; the web build and all v1 tests are unaffected.
- A Luno outage, revoked key or `secureStorageUnavailable` never blocks Yahoo refresh or blanks cached data.

## 17. Open items / risks

- **Yahoo endpoints are unofficial** and can change or rate-limit; the `MarketDataRepository` abstraction and fixtures isolate the blast radius. Check Yahoo terms before any public distribution.
- **Web proxy hosting** is the maintainer's responsibility (Cloudflare free tier is sufficient for personal use).
- fl_chart candlestick feature depth must be evaluated at milestone 9; fall back to a custom painter if crosshair/zoom is insufficient.
- Mutual funds and some indices lack intraday data or volume — UI must degrade gracefully.
- **Luno ledger semantics are under-documented** (EXCHANGE row pairing, `details` shapes, instant-buy/convert fee treatment): rely on live fixtures, surface unrecognised rows instead of guessing, and expect mapper adjustments on first live run.
- Luno's "Read-only access" preset includes *Send to any address*, which cannot be probed safely; the app warns but cannot verify that permission. Presets may change.
- Candles need an authenticated key, so Luno charts without a connection fall back to Yahoo.
- The macOS legacy keychain is weaker than the Data Protection keychain; upgrade once an Apple Developer Team is available.
- Luno API availability and terms vary by region; `listtrades` may lag, so reconciliation tolerates in-flight trades for one sync cycle.
- The shared `RequestScheduler` refactor touches the working Yahoo client; the v1 Yahoo tests plus new budget tests must stay green.

## 18. Implementation status and deviations

This section records what was actually built and verified, and where the implementation departs from the text above.
Sections 1–17 describe the intended design; where they disagree with the code, the code and this section win.

**Cupertino skin:** implemented behind the `App*` facade; see `SPEC_CUPERTINO.md` §17 for status and what remains.

### Verified in this repository
- `flutter analyze`: no issues (strict-casts / strict-inference / strict-raw-types).
- `flutter test`: 223 tests (unit, repository, widget, golden). Domain line coverage 95.6 %, overall 84.2 % (gates: 90 % / 70 %, enforced by `tool/check_coverage.dart`).
- `integration_test/app_flow_test.dart` passes on a real macOS window (onboarding → add transaction → valued holding on the dashboard).
- Builds succeeded for **web**, **macOS** and **iOS** (`--no-codesign`). The macOS app was launched and reached the welcome screen without startup errors.
- Proxy: `npm run typecheck` and `npm test` (13 tests, mocked Yahoo) pass.

### v2 (Luno) status
Milestones 14–19 are implemented. Everything below was verified with fixtures, fakes and the real macOS app; **nothing has yet been run against a live Luno account**.

**Verified in this repository**
- `flutter analyze`: no issues. `flutter test --exclude-tags golden`: 429 tests; goldens: 9. Coverage 97.0 % (`domain/`) and 85.7 % overall (gates 90 % / 70 %).
- Builds: web, macOS (debug) and iOS (`--no-codesign`, debug). `integration_test/app_flow_test.dart` passes on a real macOS window with the v2 schema.
- Migration v1 → v2 (`verifyMigration`, data backfill), the shared `RequestScheduler`, request-budget tests for Yahoo (cold, warm, repeat, chunking, incremental history) and for a Luno sync (4 calls first time, 1 call when idle, 2 for one changed account, paging, resume), ledger mapping (the fixture account replays to exactly the balances and cash Luno reports), reconciliation, permission probes, credential handling (nothing in the DB, backups or logs), lock gating and step-up, backup/restore without keys, and read-only synced portfolios.

**Verified against a recording of a real Luno account** (`test/fixtures/luno/live/`: eight wallets, 136 ledger rows, 27 trades in seven coins, 2 bank deposits, 2 on-chain receives, scrubbed and scaled; the recorder has been run once):
- Every endpoint the app reads parses (balances, ledger, markets, tickers, candles, fee info, transfers, user trades).
- All 136 rows are understood (0 unrecognised, 0 held back, no engine warnings); every coin replays to **exactly** the balance Luno reports, with FIFO and average cost; derived cash equals the sum of the MYR wallet's balance changes; a first sync costs 9 requests and an idle one 1; a later trade is picked up from the cursor for just the two wallets involved.
- What the real ledger looks like (see `test/fixtures/luno/README.md`) differed from the first draft of this spec in four ways, now handled and tested: pages arrive newest first; instant buys carry no `trade_details` (limit fills do); fees are separate `FEE` rows in the traded coin and are charged on top of the amount on a sell; order reserve/release rows have no `kind` and no balance change.

**Permission probes, verified live** (`tool/check_luno_key.dart`, read-only key, 8 wallets): all view reads answered 200; `POST /stoporder` and `DELETE /withdrawals/0` each answered a bare `403` with no error code, which the classifier treats as "permission absent" (any 403, or `ErrInsufficientPerms`). The positive case (a key that *can* stop orders or cancel withdrawals) has not been seen live and relies on the documented not-found codes; an unrecognised answer is refused as inconclusive.

**Not verified here**
- **Live ledger semantics beyond what the recording contains** (e.g. crypto-for-crypto swaps, interest/`INTEREST` rows, withdrawals, and `unconfirmed`/pending amounts did not occur in the recorded account).
- **Live Luno behaviour in general.** The synthetic fixtures in `test/fixtures/luno/` are hand-built from `openapi.json`; the recording in `live/` covers the rest. Unrecognised rows are reported rather than guessed, and write probes whose answer is not understood are treated as "cannot confirm read-only". Record more scrubbed data with `dart run tool/record_luno_fixtures.dart` (key in `LUNO_KEY_ID` / `LUNO_KEY_SECRET`).
- Windows and Linux builds, and secure storage on real devices (iOS device-only keychain, Windows DPAPI, Linux Secret Service). CI covers the builds.

**Deviations from §7A–§9 above**
| Area | Spec | Implementation |
|---|---|---|
| Positions | `LUNO:{ASSET}{FIAT}` per trading pair | One position per asset per connection, `LUNO:{ASSET}{homeFiat}`; a trade paid in another fiat is converted at that day's rate ("Paid in USD"). Found by a test: separate per-pair positions cannot be drawn down by a later send |
| Trade fees | from `listtrades` | From the ledger's `FEE` rows sharing the trade's reference. A fee in the traded coin is folded into the trade (`|leg + fee|` coins change hands, so it is part of the cost basis on a buy and reduces proceeds per coin on a sell); a fiat fee is the trade's `fees`. Order reserve/release rows (no `kind`, no balance change) are ignored |
| Endpoints used by sync | balance, ledger, trades, transfers, … | Balance and ledger only. `listtrades`, `transfers`, `withdrawals` are permission checks; `fee_info` is shown on the quote screen; order history (`listorders`/`order`) and pending rows are **not** implemented in the UI |
| Quote previous close / day range | 1 h candles | Cached daily candles (last close before today, UTC): no extra request |
| Pricing fallback | `{A}XBT × XBT{F}`, `{A}USDC`, then Yahoo for assets without a home-fiat pair | Not implemented: such a holding is flagged as missing a price. Candle/history fallback to Yahoo (`XBTMYR` → `BTC-MYR`) **is** implemented, labelled "via Yahoo" |
| Staging | — | New `luno_ledger_rows` table (raw rows, resumable, re-mappable, excluded from backups) |
| Quote TTL | 60 s | 30 s, equal to the refresh debounce |
| Search | Luno pairs grouped under "Luno" | Results show "Cryptocurrency · Luno"; v1 search has no group headers |
| Step-up | fresh check | Reused for 60 s within one flow (`kStepUpGrace`) |
| Held-back rows | — | A trade leg without a counterpart younger than 10 minutes, or a movement without a fiat price yet, stays staged and is retried; the connection shows "waiting" instead of an alarm |
| Rewards in income | — | Valued at the price on the day received and shown beside dividends; excluded from projected income |

### Not verified here
- **Windows and Linux builds** could not be run on the macOS authoring machine; the CI workflow covers them. CI (`.github/workflows/ci.yml`) is written but has not been executed because the folder is not a git repository yet.
- **Live Yahoo data**: Yahoo rate-limited the authoring environment (HTTP 429), so no live response was recorded. Parsers are tested against hand-assembled fixtures that mirror the documented response structure (`test/fixtures/yahoo/README.md`). The first run against the live API may need small mapper adjustments.
- **Proxy deployment** (`wrangler deploy`) and the web app talking to a deployed proxy were not exercised; the Worker is tested with a mocked upstream.
- **Biometrics / secure storage** run only on real devices; the lock logic is tested with fakes, `SecurePinStore` and `LocalBiometricAuth` are thin wrappers.

### Deviations from the text above
| Area | Spec | Implementation |
|---|---|---|
| Codegen / lints | freezed, json_serializable, riverpod_generator, riverpod_lint | Hand-written entities and providers; `custom_lint` was incompatible with Riverpod 3 (see §3) |
| Schema | `fx_history_cache` | FX pairs share `price_history_cache`; added `history_meta` and `profile_cache` (§5) |
| Localization | "strings centralized" | English only; strings inline. Formatting is locale-aware via `intl` (§2) |
| Dashboard grid | 12-column grid | Flex rows (8/4 split) on wide screens, 2-column on medium, stacked on phones |
| App-switcher privacy | "blur where the platform allows" | A cover widget replaces content whenever the app is inactive and the lock is enabled |
| Candlestick fallback | CustomPainter if fl_chart lacks crosshair/zoom | Not needed: fl_chart 1.3 provides touch tooltips, indicators and horizontal zoom/pan |
| Linux | — | No biometrics and no generated launcher icon (Flutter does not support one) |
| Yahoo fixtures | recorded from the real API | Hand-assembled (see above) |
| Accessibility audit | milestone 13 | Contrast ratios are unit-tested for both themes; controls have Semantics labels, focus rings and ≥ 44 px targets; direction is never conveyed by color alone (▲/▼); reduced-motion is honoured; a 1.5× text-scale layout sweep runs in tests. No manual screen-reader pass was performed |

### Behaviors worth knowing
- **Quantities and money** use `Decimal` end to end; `double` appears only in chart series and displayed quote values.
- **Split handling**: Yahoo closes are split-adjusted, so historical value restates pre-split quantities with the cumulative future split factor (`ValueHistory`). Recorded `split` transactions also scale the running position.
- **Changing the base currency** recomputes every transaction's `fx_rate_to_base` from Yahoo history where available, else from `old rate × current old→new rate` (`BaseCurrencyRebaser`); user-edited rates are not tracked separately and are recomputed too.
- **Value-history computation** runs in an isolate via `compute` (inline on web); the runner is injectable for tests.
- **Refresh** is manual-only (plus once on launch if data is older than 15 minutes). A refresh fetches quotes, FX pairs, missing profiles (sector/beta) and incrementally updates daily history, which also feeds dividend and split detection.
- **Backups** exclude lock settings and the PIN; restore supports *replace* and *merge* (duplicates skipped).
