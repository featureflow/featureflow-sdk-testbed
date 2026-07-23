# Server-driven SDK config

The wire contract for the server steering SDK event behaviour, designed once here and
implemented identically by every server-side SDK. Server reference implementation:
`sdk-server` (`sdkConfig.service.ts`); SDK reference implementation: `featureflow-node-sdk`.

## Delivery channels

The config is a single flat JSON object, delivered on the endpoints SDKs already call —
no extra request is ever made for it:

1. **`X-Featureflow-Sdk-Config` response header** on `GET /api/sdk/v1/features` (and
   `/features/:featureKey`), on **both 200 and 304** responses. The features body is a bare
   `featureKey → control` map, so a body envelope or reserved key would break old SDKs; the
   header is the only additive channel. It must be set on the 304 path because polling
   clients mostly see 304s.
2. **`POST /api/sdk/v1/events` response body** (200). Previously an empty 200; old SDKs
   ignore the body.

`featureflow-edge-proxy` must replicate the `/features` header behaviour byte-for-byte
(same header, same 304 handling) to stay wire-compatible with `sdk-server`.

## Schema (v1)

```json
{ "eventsEnabled": true, "mode": "summary", "flushIntervalSeconds": 60 }
```

| Field | Type | Meaning |
|---|---|---|
| `eventsEnabled` | boolean | Master switch. `false` suspends event recording and sending; the SDK drops its pending events and stops posting until re-enabled by a later config. Suspension is reversible — unlike a 401/403, which disables events permanently for the client's lifetime. |
| `mode` | `"summary"` \| `"full"` \| `"off"` | `summary` (default): one event per (featureKey, variant) per flush with summed `impressions`. `full`: one event per evaluation, `impressions: 1`, user attached to every event (raw fidelity, e.g. for a paid analytics tier). `off`: record nothing (equivalent to suspension, expressed as a mode). |
| `flushIntervalSeconds` | number | Events flush period. SDKs accept `1..3600` and restart their flush timer when it changes. |

## SDK rules

- **Absent field ⇒ keep current value.** The server may send a partial object.
- **Invalid value ⇒ ignore that field.** Wrong type, unknown mode, out-of-range interval —
  ignore the field, keep the rest. A malformed header/body as a whole is ignored entirely.
- **Unknown fields ⇒ ignore.** Additive evolution; never fail on extra keys.
- **Local disable wins.** If events are disabled in local SDK config (`disableEvents`) or
  permanently disabled by a 401/403, server config must never re-enable them.
- Config may arrive from either channel at any time; last received wins.

## Versioning

Additive changes (new fields) require no version signal. A breaking change would ship as a
new header name / response shape, not a mutation of this one.
