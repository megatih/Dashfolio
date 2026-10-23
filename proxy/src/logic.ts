// Pure helpers for the proxy: kept free of Workers APIs so they can be unit tested with plain Node.

/** The only Yahoo paths the proxy forwards. Anything else is rejected (this is not an open proxy). */
const ALLOWED_PATHS: RegExp[] = [
  /^\/v8\/finance\/chart\/[^/]+$/,
  /^\/v7\/finance\/quote$/,
  /^\/v1\/finance\/search$/,
  /^\/v10\/finance\/quoteSummary\/[^/]+$/,
];

export function isAllowedPath(pathname: string): boolean {
  return ALLOWED_PATHS.some((re) => re.test(pathname));
}

/** Endpoints that need a Yahoo cookie + crumb. */
export function needsCrumb(pathname: string): boolean {
  return pathname === "/v7/finance/quote" || pathname.startsWith("/v10/finance/quoteSummary/");
}

/** Edge cache lifetime in seconds. */
export function cacheTtl(pathname: string, params: URLSearchParams): number {
  if (pathname === "/v7/finance/quote") return 30;
  if (pathname === "/v1/finance/search") return 300;
  if (pathname.startsWith("/v10/finance/quoteSummary/")) return 3600;
  if (pathname.startsWith("/v8/finance/chart/")) {
    const interval = params.get("interval") ?? "1d";
    const intraday = /^(1|2|5|15|30|60|90)m$|^1h$/.test(interval);
    return intraday ? 60 : 3600;
  }
  return 0;
}

/** Returns the origin to echo in Access-Control-Allow-Origin, or null if it is not allowed. */
export function resolveAllowedOrigin(origin: string | null, allowed: string | undefined): string | null {
  if (!origin) return null;
  const list = (allowed ?? "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);
  if (list.includes("*")) return "*";
  return list.includes(origin) ? origin : null;
}

export function corsHeaders(allowedOrigin: string | null): Record<string, string> {
  if (!allowedOrigin) return {};
  return {
    "Access-Control-Allow-Origin": allowedOrigin,
    "Access-Control-Allow-Methods": "GET, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Max-Age": "86400",
    Vary: "Origin",
  };
}

/** Query string to send upstream: client-supplied crumbs are dropped; the proxy injects its own. */
export function upstreamSearch(params: URLSearchParams, crumb: string | null): string {
  const out = new URLSearchParams(params);
  out.delete("crumb");
  if (crumb) out.set("crumb", crumb);
  const s = out.toString();
  return s ? `?${s}` : "";
}

/** Extracts the cookie pairs (name=value) from raw Set-Cookie header values. */
export function cookieHeaderFrom(setCookies: string[]): string {
  return setCookies
    .map((c) => c.split(";")[0].trim())
    .filter((c) => c.includes("="))
    .join("; ");
}

/** A crumb body is plain text; HTML or rate-limit messages mean the request failed. */
export function isValidCrumb(body: string): boolean {
  const t = body.trim();
  return t.length > 0 && t.length < 64 && !t.includes("<") && !/too many/i.test(t);
}
