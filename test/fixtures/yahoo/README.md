# Yahoo Finance fixtures

Hand-assembled to mirror the structure of real Yahoo Finance responses
(`/v8/finance/chart`, `/v7/finance/quote`, `/v1/finance/search`,
`/v10/finance/quoteSummary`). Live recording was blocked by rate limiting when
these were authored, so values are synthetic but field names, nesting, nulls and
quirks (minor currency units, null candles, error payloads) follow the real API.
Re-record with `curl -A "<browser UA>"` when convenient; parsers must keep passing.
