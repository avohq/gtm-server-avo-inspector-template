# GTM Server tag Avo Inspector template

Use this template to let Avo Inspector monitor the health of your tracking and help you improve it.

Learn more about Avo Inspector [here](https://www.avo.app/docs/data-design/start-using-inspector)

> Note: No user data is sent to Avo.

## Anonymous ID / Stream ID

The template automatically resolves an anonymous ID from the event data to use as the stream identifier. It checks the following fields in priority order:

1. `client_id`
2. `x-ga-js_client_id`

`user_id` is intentionally excluded — it is typically a known, authenticated identifier and would break anonymity. If none of the above are present, an empty string is used.

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
