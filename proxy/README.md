# Dashfolio Yahoo proxy

Browsers cannot call Yahoo Finance directly (no CORS headers), so the **web** build of Dashfolio talks to this
small Cloudflare Worker instead. Native builds (iOS, macOS, Windows, Linux) call Yahoo directly and do not need it.

What it does

- Forwards only five GET endpoints: `v8/finance/chart/*`, `v7/finance/quote`, `v1/finance/search`,
  `v10/finance/quoteSummary/*` (everything else is a 404, so it is not an open proxy).
- Owns the Yahoo cookie + crumb server-side (cached per isolate, refreshed once on 401/403). The app never sees them.
- Adds CORS headers for the origins you list in `ALLOWED_ORIGINS` and answers preflight requests.
- Caches at the edge: quotes 30 s, intraday charts 60 s, daily/long charts and profiles 1 h, search 5 min.

## Deploy

```sh
cd proxy
npm install
# 1. Edit wrangler.toml: set ALLOWED_ORIGINS to the origin(s) that serve your web build.
# 2. Log in once and deploy
npx wrangler login
npm run deploy
```

Wrangler prints the worker URL, e.g. `https://dashfolio-yahoo-proxy.<you>.workers.dev`.

## Use it from the app

Either bake the URL into the web build:

```sh
flutter build web --dart-define=YAHOO_PROXY_URL=https://dashfolio-yahoo-proxy.<you>.workers.dev
```

or leave it out and paste the URL into **Settings → Data connection → Yahoo proxy URL** at runtime.

## Local development

```sh
npm run dev          # wrangler dev, listens on http://localhost:8787
flutter run -d chrome --web-port 8080 --dart-define=YAHOO_PROXY_URL=http://localhost:8787
```

`ALLOWED_ORIGINS` already includes `http://localhost:8080` for this flow.

## Tests

```sh
npm run typecheck
npm test            # Node's built-in test runner; mocks Yahoo, no network needed
```

## Notes

- Yahoo's endpoints are unofficial and may change or rate-limit. Keep usage personal and respect Yahoo's terms.
- The Worker free tier is plenty for a personal dashboard. Do not set `ALLOWED_ORIGINS = "*"` on a public deployment.
