# GTM Server tag Avo Inspector template

Use this template to let Avo Inspector monitor the health of your tracking and help you improve it.

Learn more about Avo Inspector [here](https://www.avo.app/docs/data-design/start-using-inspector)

> Note: No user data is sent to Avo.

## Event Validation (dev/staging only)

In development and staging environments, events are validated against the tracking plan spec fetched from the Avo API. The spec is fetched per request using the `/trackingPlan/eventSpec` endpoint, matching the same approach used by the Android and iOS Inspector SDKs.

Validation includes constraint checks:

- **Type checking** -- verifies the property value type matches the spec
- **Required/optional** -- fails if a required property is missing
- **Pinned values** -- exact match required for specific event/variant combinations
- **Allowed values** -- value must be in the allowed set
- **Min/max ranges** -- numeric bounds checking

Regex validation is not supported in GTM Server's sandboxed JavaScript environment and is silently skipped.

In production, events are sent directly without spec fetching or validation, optimizing for throughput.

If the spec fetch fails in dev/staging, the event is still sent without validation metadata.

## Encryption Limitation

**Encryption is NOT supported in the GTM Server template.**

GTM Server uses a sandboxed JavaScript environment that does not provide access to cryptographic APIs (such as `crypto.subtle`, Node.js `crypto`, or any equivalent). As a result, property value encryption cannot be implemented in this context. Without encryption, property values are not sent to Avo.

If property value validation is a requirement, consider using a client-side SDK or a server-side SDK in a non-sandboxed environment instead.

## How to publish an update

https://developers.google.com/tag-platform/tag-manager/templates/gallery#update_your_template
