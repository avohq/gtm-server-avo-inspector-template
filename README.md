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

Avo Inspector is moving to a multi-gate model: one Inspector API key per *gateway* (e.g. this server-side GTM container), rather than one Inspector source per destination. This tag has two optional parameters, **Output reference** and **Origin hint**, that let a gateway-scoped key tell observations apart.

**Output reference** determines which checkpoint a tag instance observes:

- Leave it empty to observe at the **gateway checkpoint** — after gateway-level transformations, before any individual output's own transformations.
- Set it to a destination's reference from Avo (e.g. `meta-x7k2q`) to observe **that output's checkpoint** — after that output's transformations.

To observe an output's checkpoint, fire this tag with the same trigger as the destination tag and add it to that destination's transformations. What this tag sends is the event as *this tag* sees it at that point — i.e. before the destination tag's own mapping runs, not the payload as it actually leaves the destination.

Both fields are optional and independent: `outputReference` alone determines the checkpoint, `originHint` (below) can be set or omitted at either checkpoint.

## Origin hint

**Origin hint** is a value identifying which source produced the event, e.g. `{{Event Data - platform}}`. Use the same field consistently across every Avo tag in the container, then map each value to a source in Avo.

- Values must be **low-cardinality** (e.g. `android`, `ios`, `web`) — never a user identifier, session ID, or anything else unique per user or per event.
- When Origin hint is set, the optional **App version** parameter is sent as the event's app version (or `null` when empty) — the container-level default never applies to a source-scoped event. Without Origin hint, App version overrides the default when set and falls back to it when empty.
- The tag does not validate this at runtime; it only trims and stringifies the value you provide, so getting this right is on the tag configuration, not the code.

> A customer's own event property literally named `outputReference` or `originHint` (with unrelated business meaning) is unaffected by this feature. It still appears in `eventProperties` exactly as before — the top-level `outputReference`/`originHint` fields described here come only from this tag's configuration, never from event data, and neither one overwrites or is affected by the other even though they share a key name.

## What the 200 means

An HTTP 200 response from Avo means the event was **accepted**, not necessarily that it was fully processed. A workspace's Inspector event cap can silently drop an accepted event without changing the response status code.

In GTM Preview mode, this tag inspects the response body and logs a console warning when it indicates a drop — for example when the workspace's event limit has been exceeded — so this is visible while testing rather than a silent gap. This logging only runs in Preview mode; it does not change whether the tag reports success or failure to GTM (`gtmOnSuccess/gtmOnFailure` are driven solely by the HTTP status code, unchanged by this behavior).

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
