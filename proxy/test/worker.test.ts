import assert from "node:assert/strict";
import { beforeEach, test } from "node:test";
import worker, { resetSessionForTests } from "../src/index.ts";

const env = { ALLOWED_ORIGINS: "https://app.example" };
type Call = { url: string; cookie: string | null };

let calls: Call[] = [];
let crumbCounter = 0;
let rejectCrumb: string | null = null;

function install() {
  calls = [];
  crumbCounter = 0;
  globalThis.fetch = (async (input: RequestInfo | URL, init?: RequestInit) => {
    const url = String(input);
    const headers = new Headers(init?.headers);
    calls.push({ url, cookie: headers.get("Cookie") });
    if (url.startsWith("https://fc.yahoo.com")) {
      const h = new Headers();
      h.append("Set-Cookie", "A3=session; Path=/");
      return new Response("", { status: 404, headers: h });
    }
    if (url.includes("/v1/test/getcrumb")) return new Response(`crumb${++crumbCounter}`, { status: 200 });
    const u = new URL(url);
    if (rejectCrumb !== null && u.searchParams.get("crumb") === rejectCrumb) return new Response('{"finance":{"error":"Unauthorized"}}', { status: 401 });
    return new Response(JSON.stringify({ ok: true, path: u.pathname }), { status: 200, headers: { "Content-Type": "application/json" } });
  }) as typeof fetch;
}

const req = (path: string, init: RequestInit = {}) => new Request(`https://proxy.example${path}`, init);

beforeEach(() => {
  resetSessionForTests();
  install();
  rejectCrumb = null;
});

test("answers CORS preflight only for allowed origins", async () => {
  const ok = await worker.fetch(req("/v7/finance/quote", { method: "OPTIONS", headers: { Origin: "https://app.example" } }), env);
  assert.equal(ok.status, 204);
  assert.equal(ok.headers.get("Access-Control-Allow-Origin"), "https://app.example");
  const bad = await worker.fetch(req("/v7/finance/quote", { method: "OPTIONS", headers: { Origin: "https://evil.example" } }), env);
  assert.equal(bad.status, 403);
  assert.equal(bad.headers.get("Access-Control-Allow-Origin"), null);
});

test("rejects other origins, methods and paths without calling Yahoo", async () => {
  assert.equal((await worker.fetch(req("/v8/finance/chart/AAPL", { headers: { Origin: "https://evil.example" } }), env)).status, 403);
  assert.equal((await worker.fetch(req("/v8/finance/chart/AAPL", { method: "POST", headers: { Origin: "https://app.example" } }), env)).status, 405);
  assert.equal((await worker.fetch(req("/v1/test/getcrumb", { headers: { Origin: "https://app.example" } }), env)).status, 404);
  assert.equal(calls.length, 0);
});

test("chart requests are forwarded without a crumb", async () => {
  const res = await worker.fetch(req("/v8/finance/chart/AAPL?range=1mo&interval=1d", { headers: { Origin: "https://app.example" } }), env);
  assert.equal(res.status, 200);
  assert.equal(res.headers.get("Access-Control-Allow-Origin"), "https://app.example");
  assert.equal(calls.length, 1);
  assert.ok(calls[0].url.startsWith("https://query1.finance.yahoo.com/v8/finance/chart/AAPL?range=1mo&interval=1d"));
  assert.ok(!calls[0].url.includes("crumb"));
});

test("quote requests get a server-side crumb and cookie; client crumbs are ignored", async () => {
  const res = await worker.fetch(req("/v7/finance/quote?symbols=AAPL&crumb=client", { headers: { Origin: "https://app.example" } }), env);
  assert.equal(res.status, 200);
  const upstream = calls.find((c) => c.url.includes("/v7/finance/quote"))!;
  assert.ok(upstream.url.includes("crumb="));
  assert.ok(!upstream.url.includes("crumb=client"));
  assert.equal(upstream.cookie, "A3=session");
});

test("a rejected crumb is refreshed once and the request retried", async () => {
  // Prime the cached session (crumb1 or later), then make Yahoo reject exactly that crumb.
  await worker.fetch(req("/v7/finance/quote?symbols=A", { headers: { Origin: "https://app.example" } }), env);
  rejectCrumb = `crumb${crumbCounter}`;
  const before = crumbCounter;
  const res = await worker.fetch(req("/v10/finance/quoteSummary/AAPL?modules=price", { headers: { Origin: "https://app.example" } }), env);
  assert.equal(res.status, 200);
  assert.equal(crumbCounter, before + 1, "fetched exactly one new crumb");
});

test("upstream failures become a JSON 502 with CORS headers", async () => {
  globalThis.fetch = (async () => {
    throw new Error("network down");
  }) as typeof fetch;
  const res = await worker.fetch(req("/v1/finance/search?q=a", { headers: { Origin: "https://app.example" } }), env);
  assert.equal(res.status, 502);
  assert.equal(res.headers.get("Access-Control-Allow-Origin"), "https://app.example");
  assert.match(((await res.json()) as { error: string }).error, /Upstream/);
});
