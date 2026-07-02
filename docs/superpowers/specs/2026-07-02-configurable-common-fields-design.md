# Configurable common-field exclusions — design

**Date:** 2026-07-02
**Status:** Awaiting user review
**Context:** Customer request (Dave B). They modded template version 72047 (unlinking it from gallery updates) to stop the tag from excluding `user_id` and `currency` from Inspector schemas. With the list-of-objects fix shipping, they'd have to re-mod after updating. Ask: make the excluded common fields configurable in the template UI, excluded by default.

## Problem

`extractSchema()` in `template.tpl` hardcodes a `commonFields` list of 27 standard GTM/GA4 field names (`client_id`, `currency`, `user_id`, `value`, `page_*`, `user_data.*`, `x-ga-*`, …). Any event key matching an entry — at any nesting level — is dropped from the schema sent to Avo Inspector. Users who want Inspector to see some of these fields (commonly `user_id` and `currency`) must edit the template code, which permanently unlinks their copy from gallery updates.

## Goals

- A user can opt specific default-excluded fields back into Inspector schemas from the tag configuration UI — no template modding.
- Default behavior is byte-for-byte identical to today: with the new parameter unset, schemas are unchanged.
- Future additions to the default exclusion list still reach all users automatically.

## Non-goals

- Adding *extra* exclusions beyond the defaults (nobody has asked; can be layered on later).
- Making the `x-sst-` / `x-ga-` prefix filters configurable — those drop GTM-internal plumbing keys and stay unconditional. (Three `x-ga-*` entries in the default list are therefore effectively un-includable; the help text says so.)
- Changing stream-ID / anonymity behavior: `user_id` is never used as `anonymousId`/`streamId` regardless of this setting. Including it only adds its **name and type** to the schema — Inspector never receives property values.

## Approaches considered

1. **Include-list override (chosen).** Keep the default list hardcoded; add a UI table of field names to *include* (stop excluding). Empty table = current behavior. Defaults keep evolving with template updates. Smallest UI, covers the request.
2. **Checkbox per field.** Most discoverable, but 27 checkboxes bloat the tag UI and every new common field requires a template UI change.
3. **Fully editable exclusion list.** A table pre-populated with the defaults. Maximum control, but users can accidentally delete defaults, and GTM freezes parameter values at tag-config time, so shipped updates to the default list would never reach configured tags.

## Design

### 1. Template parameter (`___TEMPLATE_PARAMETERS___`)

Add one `SIMPLE_TABLE` parameter after `environment`:

```json
{
  "type": "SIMPLE_TABLE",
  "name": "includeCommonFields",
  "displayName": "Common fields to include in Inspector schemas",
  "help": "By default this tag excludes standard GTM/GA4 common fields (e.g. client_id, currency, user_id, value, page_location, user_data.email_address) from the event schema sent to Avo Inspector. Add a field name here to include it. Only property names and types are sent to Inspector — never values. Fields prefixed x-ga- or x-sst- are always excluded.",
  "simpleTableColumns": [
    {
      "defaultValue": "",
      "displayName": "Field name",
      "name": "fieldName",
      "type": "TEXT",
      "isUnique": true
    }
  ],
  "newRowButtonText": "Add field"
}
```

The tag code receives this as `data.includeCommonFields`: an array of `{fieldName: string}` rows, or `undefined` on tags configured before the parameter existed.

### 2. Sandboxed JS (`extractSchema`)

After the `commonFields` literal, subtract the user's include list:

```js
const included = data.includeCommonFields;
if (getType(included) === 'array' && included.length > 0) {
  let filtered = [];
  for (var ci = 0; ci < commonFields.length; ci++) {
    let keep = true;
    for (var ii = 0; ii < included.length; ii++) {
      // final code trims fieldName before comparing (see semantics below)
      if (included[ii] && included[ii].fieldName === commonFields[ci]) {
        keep = false;
        break;
      }
    }
    if (keep) filtered.push(commonFields[ci]);
  }
  commonFields = filtered;
}
```

Semantics:

- Exact string match against the default list. A typo or a name not in the default list matches nothing and changes nothing (fail-safe: field stays excluded). Trim whitespace from `fieldName` before comparing to forgive copy-paste.
- The include applies at **every nesting level**, mirroring how the exclusion works today (e.g. including `currency` also un-hides a `currency` key inside `items[]` objects).
- The `x-sst-` / `x-ga-` prefix check remains a separate, unconditional condition.
- No new permissions: reading template parameters requires none.

### 3. Version metadata

- Bump `libVersion` in `generateBaseBody` from `2.0.0` to `2.1.0` (new feature, payload shape unchanged).
- `metadata.yaml`: add a new top entry with placeholder sha per the release flow; set the real sha after merge.

### 4. Docs

README: add a short "Excluded common fields" section listing the defaults and explaining the include parameter; clarify that the existing `user_id` note concerns anonymous-ID resolution and is unaffected by including `user_id` in schemas.

## Error handling

- `data.includeCommonFields` undefined / not an array / empty → defaults used untouched.
- Rows with empty or whitespace-only `fieldName` → ignored.
- No user input reaches the network request or URLs; the parameter only filters a local constant, so there is no injection surface.

## Testing (`___TESTS___` scenarios)

1. **Regression:** no `includeCommonFields` in `mockData` → `user_id`/`currency` absent from `eventProperties` (pins current behavior).
2. **Opt-in:** `includeCommonFields: [{fieldName: 'user_id'}, {fieldName: 'currency'}]` → both appear in `eventProperties` with correct types, **and** `anonymousId`/`streamId` still resolve from `client_id` (user_id must not leak into stream identity).
3. **Nested:** with `currency` included, a `currency` key inside an `items[]` element appears in that object's `children`.
4. **Fail-safe:** rows with a typo (`userid`) and an empty `fieldName` → schema identical to default.

## Open items for reviewer

- Config scope: this design implements the include-list override only (option 1). If you want "both directions" (extra exclusions too), say so and I'll extend the design.
- `libVersion` 2.1.0 bump — confirm you want the payload to advertise it.
