# Weekendmaxxing flight proxy (Cloudflare Worker)

A tiny proxy in front of SerpApi that:

- keeps the **SerpApi key off the device** (stored as a Cloudflare secret), and
- **caches every unique query in KV, shared across all users**, so a given search
  costs at most one SerpApi call per TTL window no matter how many people run it.

## Endpoints

Params mirror SerpApi (minus `api_key`). Every request needs `X-App-Token`.

| Path | SerpApi engine | Cache TTL |
| --- | --- | --- |
| `GET /v1/deals` | `google_flights_deals` (discovery) | 24h |
| `GET /v1/offers` | `google_flights` (route offers) | 3h |

Example:

```bash
curl -H "X-App-Token: $APP_TOKEN" \
  "https://<your-worker>/v1/deals?departure_id=/m/04jpl&outbound_date=2026-06-19&return_date=2026-06-21&type=1&max_price=200&currency=GBP&hl=en&gl=uk"
```

Responses include an `X-Cache: HIT|MISS` header.

## Local development

1. `npm install`
2. Secrets live in `.dev.vars` (gitignored): `SERPAPI_KEY` and `APP_TOKEN`.
3. `npm run dev` → serves on `http://localhost:8787` with a local KV simulation.

## Deploy

1. Log in: `npx wrangler login`
2. Create the KV namespace and paste its id into `wrangler.toml`:
   `npx wrangler kv namespace create CACHE`
3. Set the secrets (do **not** commit them):
   ```bash
   npx wrangler secret put SERPAPI_KEY
   npx wrangler secret put APP_TOKEN
   ```
4. `npm run deploy` → gives you a `https://weekendmaxxing-proxy.<account>.workers.dev` URL.

Put that URL (and the same `APP_TOKEN`) into `Config/Secrets.xcconfig` as
`PROXY_BASE_URL` and `PROXY_APP_TOKEN`. Optionally attach a custom domain
(e.g. `api.fwg.fyi`) in the Cloudflare dashboard.
