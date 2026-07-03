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
