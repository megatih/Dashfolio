# Luno fixtures

Two sets, deliberately kept apart:

| Where | What |
|---|---|
| `test/fixtures/luno/*.json` | **Synthetic** account built from `openapi.json` (MYR, XBT, ETH): a small, fully predictable story used by most unit tests (ids `1001` MYR, `1002` XBT, `1003` ETH; XBT `balance + reserved` = `0.01495`). Error bodies (`error_*.json`), `pending.json` and `ledger_empty.json` live here too |
| `test/fixtures/luno/live/*.json` | **Recorded from a real account** by `tool/record_luno_fixtures.dart` (MYR, eight wallets, 136 ledger rows, trades in seven coins), then scrubbed and scaled. **Local only: git-ignored and not in the public repo.** Pinned by `test/data/luno/luno_live_fixtures_test.dart`, which skips when the folder is missing |

## What the recorded data showed

- Ledger pages arrive **newest first**.
- Ledger amounts (`balance`, `balance_delta`, `available`, `available_delta`) are bare JSON numbers, sometimes in exponent form.
- Limit-order fills carry `detail_fields.trade_details` (pair, price, volume, sequence); **instant buys** ("Bought BTC … for RM …", `type` 14) do not. Both legs of a trade share a `reference`.
- Luno's fee is a separate `FEE` row in the traded coin with the trade's `reference`: taken out of what you receive on a buy, charged on top of what you sell on a sell.
- Rows with no `kind` ("Reserved/Released funds for order") change `available` but not `balance`; they are order bookkeeping.
- Deposits are `TRANSFER` rows without crypto details; receives carry `detail_fields.crypto_details`.
- `GET /transfers` returns inbound deposits with `fee` and (for crypto) `transaction_id`.

## Scrubbing

Recordings are made with a **read-only key held only in your shell**:

```sh
LUNO_KEY_ID=… LUNO_KEY_SECRET=… dart run tool/record_luno_fixtures.dart        # writes test/fixtures/luno/live
dart run tool/record_luno_fixtures.dart --rescrub test/fixtures/luno/live      # re-apply the rules to existing files
```

Account, order, trade and transfer ids, references, Luno's internal ids, addresses and hashes become placeholders;
descriptions keep only generic wording with every digit masked; the human-readable `details` block (addresses, hashes,
prices, fees, wallet names) is digit-masked or removed; amounts are multiplied by `LUNO_SCRUB_FACTOR` (default 0.37) while
prices are left alone. `luno_live_fixtures_test.dart` scans every committed fixture for addresses, hashes and e-mails and
fails if any appear. Review new recordings anyway before committing.

To see how Luno answers the permission probes for your key (the one part recordings cannot cover):

```sh
LUNO_KEY_ID=… LUNO_KEY_SECRET=… dart run tool/check_luno_key.dart
```
