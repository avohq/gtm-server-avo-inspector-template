# GTM Server tag Avo Inspector template

Use this template to let Avo Inspector monitor the health of your tracking and help you improve it.

Learn more about Avo Inspector [here](https://www.avo.app/docs/data-design/start-using-inspector)

> Note: No user data is sent to Avo.

## Anonymous ID (Model D)

This template uses a best-effort server-side approach to determine an anonymous ID for each event. The extraction follows this priority order:

1. `client_id` -- the GA4 client ID passed from the browser
2. `user_id` -- the user ID if set by the application
3. `x-ga-js_client_id` -- the GA4 JavaScript client ID header
4. Empty string fallback if none of the above are available

No session tracking is performed. Each tag execution is stateless.

## Event Validation

Events are validated against the tracking plan spec fetched from the Avo API on each tag execution. Because GTM Server tags are stateless (no cross-request memory), the spec is fetched per request -- there is no LRU cache or persistent storage between executions.

Validated events include:

- `streamId` -- a unique identifier for the validation stream
- `eventSpecMetadata` -- the event ID and hash from the tracking plan spec
- `validationResults` -- per-property validation results comparing expected vs actual types

If the spec fetch fails or the event is not found in the spec, the event is still sent without validation metadata.

## Encryption Limitation

**Encryption is NOT supported in the GTM Server template.**

GTM Server uses a sandboxed JavaScript environment that does not provide access to cryptographic APIs (such as `crypto.subtle`, Node.js `crypto`, or any equivalent). As a result, payload encryption cannot be implemented in this context.

If encryption is a requirement, consider using a server-side SDK in a non-sandboxed environment instead.

## How to publish an update

https://developers.google.com/tag-platform/tag-manager/templates/gallery#update_your_template
