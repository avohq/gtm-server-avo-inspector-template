# GTM Server tag Avo Inspector template

Use this template to let Avo Inspector monitor the health of your tracking and help you improve it.

Learn more about Avo Inspector [here](https://www.avo.app/docs/data-design/start-using-inspector)

> Note: No user data is sent to Avo.

## Anonymous ID / Stream ID

The template automatically resolves an anonymous ID from the event data to use as the stream identifier. It checks the following fields in priority order:

1. `client_id`
2. `x-ga-js_client_id`

`user_id` is intentionally excluded — it is typically a known, authenticated identifier and would break anonymity. If none of the above are present, an empty string is used.

## Excluded common fields

The tag excludes standard GTM/GA4 common fields from the event schema sent to Avo Inspector, so monitoring focuses on your custom event properties. The default exclusion list:

`client_id`, `currency`, `event_name`, `ip_override`, `language`, `page_encoding`, `page_hostname`, `page_location`, `page_path`, `page_referrer`, `page_title`, `screen_resolution`, `user_agent`, `user_data.email_address`, `user_data.phone_number`, `user_data.address.first_name`, `user_data.address.last_name`, `user_data.address.street`, `user_data.address.city`, `user_data.address.region`, `user_data.address.postal_code`, `user_data.address.country`, `user_id`, `value`, `viewport_size`, plus all `x-ga-*` and `x-sst-*` prefixed keys.

### Including specific fields

Use the **"Common fields to include in Inspector schemas"** table in the tag configuration to opt fields back in (e.g. `user_id`, `currency`):

- Only the property name and type are sent to Inspector — never values.
- Including `user_id` does not change anonymous-ID resolution (see above); it is never used as the stream ID.
- `x-ga-*` / `x-sst-*` keys are always excluded and cannot be opted in.
- Names must exactly match a default-excluded field (whitespace is trimmed); unknown names are ignored.
- The setting applies at every nesting level — e.g. including `currency` also reveals a `currency` key inside `items[]` objects.

## Gateways

Avo Inspector is moving to a multi-gate model: one Inspector API key per *gateway* (e.g. this server-side GTM container), rather than one Inspector source per destination. This tag has three optional parameters — **Output reference**, **Origin hint** and **App version** — that let a gateway-scoped key tell observations apart.

**Output reference** determines which checkpoint a tag instance observes:

- Leave it empty to observe at the **gateway checkpoint** — after gateway-level transformations, before any individual output's own transformations.
- Set it to a destination's reference from Avo (e.g. `meta-x7k2q`) to observe **that output's checkpoint** — after that output's transformations.

To observe an output's checkpoint, fire this tag with the same trigger as the destination tag and add it to that destination's transformations. What this tag sends is the event as *this tag* sees it at that point — i.e. before the destination tag's own mapping runs, not the payload as it actually leaves the destination.

All three parameters are optional and independent: `outputReference` alone determines the checkpoint, and `originHint` / `appVersion` (below) can be set or omitted at either checkpoint.

## Origin hint

**Origin hint** is a value identifying which source produced the event, e.g. `{{Event Data - platform}}`. Use the same field consistently across every Avo tag in the container, then map each value to a source in Avo.

- Values must be **low-cardinality** (e.g. `android`, `ios`, `web`) — never a user identifier, session ID, or anything else unique per user or per event.
- The tag does not validate this at runtime; it only trims and stringifies the value you provide, so getting this right is on the tag configuration, not the code.
- Origin hint also changes which app version the event carries — see below.

## App version

**App version** is the version of the app that produced the event, e.g. `{{Event Data - app_version}}`. Like the other two parameters it is trimmed (numbers and booleans are stringified) and sent as a top-level field alongside the event schema, never inside the event's own properties.

Because an Origin hint marks the event as belonging to a *different* source than this container, the container-level default version (`unversioned GTM server-side tag`) must not be attached to it. The two parameters therefore interact:

| Origin hint | App version | Version reported for the event |
| --- | --- | --- |
| set | provided | the App version value |
| set | empty | `null` — no version at all; the container default is deliberately not applied |
| empty | provided | the App version value (overrides the container default) |
| empty | empty | the container default, `unversioned GTM server-side tag` (unchanged behavior) |

"Empty" means an empty string, a whitespace-only string, or a value the tag cannot turn into a string (an object or an array). Unlike `outputReference` and `originHint`, which are omitted entirely when empty, `appVersion` is always present on the body — as a literal JSON `null` in the second row above.

> A customer's own event property literally named `outputReference`, `originHint` or `appVersion` (with unrelated business meaning) is unaffected by this feature. It still appears in `eventProperties` exactly as before — the top-level `outputReference`/`originHint`/`appVersion` fields described here come only from this tag's configuration, never from event data, and neither one overwrites or is affected by the other even though they share a key name.

## Where events are sent

The tag posts to Avo's unified Inspector ingest endpoint:

```
POST https://api.avo.app/inspector/v2/track
```

with these headers:

| Header | Value |
| --- | --- |
| `api-key` | the Inspector key from the tag configuration |
| `env` | `dev`, `staging` or `prod`, from the Environment parameter |
| `X-Avo-Client` | `gtm-server` |
| `content-type` | `application/json` |

Every Avo Inspector sender — the SDKs and both GTM templates — now posts to this one endpoint and identifies itself with `X-Avo-Client`, so traffic can be attributed at the edge without decoding a body. `X-Avo-Client: gtm-server` is what marks a request as coming from this template.

`api-key` and `env` are read from the headers rather than the body. The body still carries `apiKey` and `env` on every event so that all senders share one body shape; the endpoint ignores those copies.

Three things changed when the tag moved here from the previous server-side GTM endpoint (`/inspector/gtm/v1/track`):

- **Events are no longer sampled server-side.** The previous endpoint applied Inspector's own sampling to server-side GTM traffic, so an accepted event could still be discarded before it was stored, and stored counts were extrapolated from the surviving sample. This endpoint does not sample: every accepted event is stored, and counts are exact. (The `samplingRate: 1` field the tag puts on the body is unchanged — the tag has never sampled client-side.)
- **Attribution changed.** Events used to be recorded with the tracking ID `GTM`, which the previous endpoint stamped on everything it handled. They are now recorded with `writeApiV2`, which this endpoint stamps on everything *it* handles, so the tracking ID no longer identifies server-side GTM. The `X-Avo-Client: gtm-server` header is what distinguishes this traffic instead.
- **The 200 body changed shape.** See the next section.

The tag makes this call from your GTM server container, server to server — never from a browser — so no CORS preflight is involved and browser-side constraints on this endpoint do not apply to it.

## What the 200 means

An HTTP 200 from Avo means the event was **accepted and queued**, not that it was processed. Turning the payload into an Inspector event happens later in a background worker, after the response has already been sent, and its outcome is not reflected in the response this tag sees.

| Response | What it means |
| --- | --- |
| `200 {"samplingRate":1,"success":true}` | Accepted and queued for processing. The rate is a fixed `1` — this endpoint does not sample — and is on the body because downstream counting divides by it. |
| `200 {"success":false}` | Accepted, then dropped because the workspace's Inspector event limit is exhausted. This is the only post-acceptance drop visible in a 200 body. |
| `200 {"ok":false}` | An unexpected server-side error while handling the request. The API's error handler answers without setting a status, so it arrives as a 2xx. |
| `400 {"ok":false,"error":"..."}` | Rejected before acceptance: a missing or invalid Inspector key or environment header, an Inspector key the API does not recognize, or a body it could not parse. |

Only the first three reach the tag as a success — any non-2xx (including the 400 row) calls `gtmOnFailure`.

In GTM Preview mode, the tag inspects the body of a 2xx response and logs a console warning for the two `false` shapes, so an event-limit drop or a server error is visible while you are testing rather than looking like a clean success. The warning prints the response body as its second argument, trimmed of surrounding whitespace, rather than just an error message, so whatever else the endpoint said is visible too — it is Avo's own API response and carries no event data. This logging only runs in Preview mode; it does not change whether the tag reports success or failure to GTM (`gtmOnSuccess`/`gtmOnFailure` are driven solely by the HTTP status code, unchanged by this behavior).

A 200 therefore cannot tell you that an event was *processed*: an event that later fails to decode in the background worker is indistinguishable from one that made it all the way through. What a 200 does now rule out is a sampling drop — there is no longer one.

## Event Validation (dev/staging only)

In development and staging environments, events are validated against the tracking plan spec fetched from the Avo API. The spec is fetched per request using the `/trackingPlan/eventSpec` endpoint.

Validation includes constraint checks:

- **Type checking** -- verifies the property value type matches the spec
- **Required/optional** -- fails if a required property is missing
- **Pinned values** -- exact match required for properties with pinned value
- **Allowed values** -- property value must be in the allowed set defined in Avo
- **Min/max ranges** -- numeric bounds checking

Regex validation is not supported in GTM Server's sandboxed JavaScript environment.

In production, events are sent directly without spec fetching or validation, optimizing for throughput.

If the spec fetch fails in dev/staging, the event is still sent without validation metadata.

## Encryption Limitation

**Encryption is NOT supported in the GTM Server template.**

GTM Server uses a sandboxed JavaScript environment that does not provide access to cryptographic APIs. As a result, property value encryption is not supported in this template.

If property value validation is a requirement, consider using the [Client Side GTM template](https://www.avo.app/docs/inspector/connect-inspector-to-gtm#inspector-client-side-gtm-integration-with-a-template) or the [Inspector SDK](https://www.avo.app/docs/inspector/inspector-installation-overview#install-inspector-sdk) instead.

## How to publish an update

https://developers.google.com/tag-platform/tag-manager/templates/gallery#update_your_template
