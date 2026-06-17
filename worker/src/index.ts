/**
 * Weekendmaxxing flight proxy.
 *
 * Sits between the app and SerpApi so that:
 *  - the SerpApi key never ships in the app (it's a Cloudflare secret), and
 *  - every unique query is cached in KV and shared across all users, so a given
 *    search costs at most one SerpApi call per TTL window regardless of traffic.
 *
 * Endpoints (params mirror SerpApi, minus api_key):
 *   GET /v1/deals   -> engine=google_flights_deals  (discovery)   TTL 24h
 *   GET /v1/offers  -> engine=google_flights        (route offers) TTL 3h
 * All requests must send header `X-App-Token: <APP_TOKEN>`.
 */

export interface Env {
  SERPAPI_KEY: string;
  APP_TOKEN: string;
  CACHE: KVNamespace;
}

interface RouteConfig {
  engine: string;
  ttl: number; // seconds
}

const ROUTES: Record<string, RouteConfig> = {
  "/v1/deals": { engine: "google_flights_deals", ttl: 24 * 60 * 60 },
  "/v1/offers": { engine: "google_flights", ttl: 3 * 60 * 60 },
};

// Only these params are forwarded to SerpApi (api_key is added server-side).
const ALLOWED_PARAMS = new Set([
  "departure_id",
  "arrival_id",
  "outbound_date",
  "return_date",
  "type",
  "travel_class",
  "adults",
  "children",
  "stops",
  "max_price",
  "currency",
  "hl",
  "gl",
  "deep_search",
  "departure_token",
]);

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    const route = ROUTES[url.pathname];

    if (request.method !== "GET" || !route) {
      return json({ error: "Not found" }, 404);
    }
    if (request.headers.get("X-App-Token") !== env.APP_TOKEN) {
      return json({ error: "Unauthorized" }, 401);
    }

    // Build a normalized, whitelisted query for SerpApi.
    const params = new URLSearchParams();
    params.set("engine", route.engine);
    for (const [key, value] of url.searchParams) {
      if (ALLOWED_PARAMS.has(key) && value !== "") params.set(key, value);
    }
    params.sort(); // stable cache key regardless of param order

    const cacheKey = `${route.engine}?${params.toString()}`;

    const cached = await env.CACHE.get(cacheKey);
    if (cached) {
      return json(JSON.parse(cached), 200, "HIT");
    }

    params.set("api_key", env.SERPAPI_KEY);
    let data: unknown;
    let upstreamStatus = 502;
    try {
      const resp = await fetch(`https://serpapi.com/search?${params.toString()}`);
      upstreamStatus = resp.status;
      data = await resp.json();
    } catch (err) {
      return json({ error: "Upstream request failed" }, 502);
    }

    // Only cache genuine successful payloads.
    const hasError = typeof data === "object" && data !== null && "error" in (data as Record<string, unknown>);
    if (upstreamStatus === 200 && !hasError) {
      await env.CACHE.put(cacheKey, JSON.stringify(data), { expirationTtl: route.ttl });
    }

    return json(data, upstreamStatus, "MISS");
  },
};

function json(body: unknown, status = 200, cache?: string): Response {
  const headers: Record<string, string> = { "Content-Type": "application/json" };
  if (cache) headers["X-Cache"] = cache;
  return new Response(JSON.stringify(body), { status, headers });
}
