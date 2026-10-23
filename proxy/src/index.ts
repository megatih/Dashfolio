import { cacheTtl, cookieHeaderFrom, corsHeaders, isAllowedPath, isValidCrumb, needsCrumb, resolveAllowedOrigin, upstreamSearch } from "./logic.ts";

export interface Env {
  ALLOWED_ORIGINS?: string;
}

const HOSTS = ["https://query1.finance.yahoo.com", "https://query2.finance.yahoo.com"];
const UA =
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36";
const SESSION_TTL_MS = 30 * 60 * 1000;

interface Session {
  cookie: string;
  crumb: string;
  expires: number;
}

// Module-level cache: shared by requests served from the same isolate.
let session: Session | null = null;

/** Test hook: forget the cached Yahoo session. */
export function resetSessionForTests(): void {
  session = null;
}

async function getSession(force = false): Promise<Session> {
  if (!force && session && session.expires > Date.now()) return session;

  const fc = await fetch("https://fc.yahoo.com", { headers: { "User-Agent": UA }, redirect: "manual" });
  const setCookies = fc.headers.getSetCookie?.() ?? [];
  const cookie = cookieHeaderFrom(setCookies);

  const res = await fetch(`${HOSTS[0]}/v1/test/getcrumb`, { headers: { "User-Agent": UA, Cookie: cookie } });
  const crumb = await res.text();
  if (res.status !== 200 || !isValidCrumb(crumb)) throw new Error(`crumb request failed (${res.status})`);

  session = { cookie, crumb: crumb.trim(), expires: Date.now() + SESSION_TTL_MS };
  return session;
}

async function fetchUpstream(url: URL, withCrumb: boolean, ttl: number, attempt = 0): Promise<Response> {
  const host = HOSTS[attempt % HOSTS.length];
  const s = withCrumb ? await getSession(attempt > 0) : null;
  const target = `${host}${url.pathname}${upstreamSearch(url.searchParams, s?.crumb ?? null)}`;
  const res = await fetch(target, {
    headers: { "User-Agent": UA, Accept: "application/json", ...(s ? { Cookie: s.cookie } : {}) },
    cf: ttl > 0 ? { cacheTtl: ttl, cacheEverything: true } : undefined,
  });
  // A stale crumb shows up as 401/403; refresh it once and retry.
  if (withCrumb && (res.status === 401 || res.status === 403) && attempt < 1) {
    session = null;
    return fetchUpstream(url, withCrumb, ttl, attempt + 1);
  }
  return res;
}

function json(status: number, body: unknown, extra: Record<string, string> = {}): Response {
  return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json", ...extra } });
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const origin = request.headers.get("Origin");
    const allowed = resolveAllowedOrigin(origin, env.ALLOWED_ORIGINS);
    const cors = corsHeaders(allowed);

    if (request.method === "OPTIONS") {
      // Preflight: only answer for allowed origins.
      return allowed ? new Response(null, { status: 204, headers: cors }) : new Response(null, { status: 403 });
    }
    if (request.method !== "GET") return json(405, { error: "Method not allowed" }, cors);
    if (origin && !allowed) return json(403, { error: "Origin not allowed" });

    const url = new URL(request.url);
    if (!isAllowedPath(url.pathname)) return json(404, { error: "Not found" }, cors);

    try {
      const upstream = await fetchUpstream(url, needsCrumb(url.pathname), cacheTtl(url.pathname, url.searchParams));
      const headers = new Headers(cors);
      headers.set("Content-Type", upstream.headers.get("Content-Type") ?? "application/json");
      if (upstream.ok) headers.set("Cache-Control", `public, max-age=${Math.min(cacheTtl(url.pathname, url.searchParams), 300)}`);
      return new Response(upstream.body, { status: upstream.status, headers });
    } catch (e) {
      return json(502, { error: "Upstream request failed", detail: e instanceof Error ? e.message : String(e) }, cors);
    }
  },
};
