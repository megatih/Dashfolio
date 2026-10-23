import assert from "node:assert/strict";
import { test } from "node:test";
import { cacheTtl, cookieHeaderFrom, corsHeaders, isAllowedPath, isValidCrumb, needsCrumb, resolveAllowedOrigin, upstreamSearch } from "../src/logic.ts";

test("only the five Yahoo endpoints are forwarded", () => {
  for (const ok of ["/v8/finance/chart/AAPL", "/v8/finance/chart/EURUSD=X", "/v7/finance/quote", "/v1/finance/search", "/v10/finance/quoteSummary/MSFT"]) {
    assert.equal(isAllowedPath(ok), true, ok);
  }
  for (const bad of ["/", "/v1/test/getcrumb", "/v8/finance/chart/", "/v8/finance/chart/A/B", "/v7/finance/quote/AAPL", "/../etc/passwd", "/v10/finance/quoteSummary/", "/v8/finance/chart/AAPL/extra", "//v7/finance/quote"]) {
    assert.equal(isAllowedPath(bad), false, bad);
  }
});

test("crumb is needed for quote and quoteSummary only", () => {
  assert.equal(needsCrumb("/v7/finance/quote"), true);
  assert.equal(needsCrumb("/v10/finance/quoteSummary/AAPL"), true);
  assert.equal(needsCrumb("/v8/finance/chart/AAPL"), false);
  assert.equal(needsCrumb("/v1/finance/search"), false);
});

test("cache lifetimes follow the data volatility", () => {
  const p = (s: string) => new URLSearchParams(s);
  assert.equal(cacheTtl("/v7/finance/quote", p("")), 30);
  assert.equal(cacheTtl("/v1/finance/search", p("q=a")), 300);
  assert.equal(cacheTtl("/v10/finance/quoteSummary/AAPL", p("")), 3600);
  assert.equal(cacheTtl("/v8/finance/chart/AAPL", p("interval=1d&range=1y")), 3600);
  assert.equal(cacheTtl("/v8/finance/chart/AAPL", p("interval=5m&range=1d")), 60);
  assert.equal(cacheTtl("/v8/finance/chart/AAPL", p("interval=1h")), 60);
  assert.equal(cacheTtl("/v8/finance/chart/AAPL", p("interval=1mo")), 3600);
  assert.equal(cacheTtl("/other", p("")), 0);
});

test("CORS: only configured origins are echoed", () => {
  const allowed = "https://a.example, http://localhost:8080";
  assert.equal(resolveAllowedOrigin("https://a.example", allowed), "https://a.example");
  assert.equal(resolveAllowedOrigin("http://localhost:8080", allowed), "http://localhost:8080");
  assert.equal(resolveAllowedOrigin("https://evil.example", allowed), null);
  assert.equal(resolveAllowedOrigin(null, allowed), null);
  assert.equal(resolveAllowedOrigin("https://x.example", "*"), "*");
  assert.equal(resolveAllowedOrigin("https://x.example", undefined), null);
  assert.deepEqual(corsHeaders(null), {});
  assert.equal(corsHeaders("https://a.example")["Access-Control-Allow-Origin"], "https://a.example");
  assert.equal(corsHeaders("https://a.example")["Vary"], "Origin");
});

test("client-supplied crumbs are replaced by the proxy's own", () => {
  assert.equal(upstreamSearch(new URLSearchParams("symbols=A,B&crumb=evil"), "good"), "?symbols=A%2CB&crumb=good");
  assert.equal(upstreamSearch(new URLSearchParams("q=apple"), null), "?q=apple");
  assert.equal(upstreamSearch(new URLSearchParams("crumb=x"), null), "");
});

test("cookie header is built from Set-Cookie values", () => {
  assert.equal(cookieHeaderFrom(["A=1; Path=/; HttpOnly", "B=2; Domain=.yahoo.com"]), "A=1; B=2");
  assert.equal(cookieHeaderFrom([]), "");
  assert.equal(cookieHeaderFrom(["garbage"]), "");
});

test("crumb validation rejects html and rate-limit bodies", () => {
  assert.equal(isValidCrumb("abc123XYZ/-"), true);
  assert.equal(isValidCrumb(""), false);
  assert.equal(isValidCrumb("<html>Too Many Requests</html>"), false);
  assert.equal(isValidCrumb("Too Many Requests"), false);
  assert.equal(isValidCrumb("x".repeat(100)), false);
});
