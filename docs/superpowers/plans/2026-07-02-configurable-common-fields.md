# Configurable Common-Field Exclusions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let users opt default-excluded common fields (e.g. `user_id`, `currency`) back into the event schema sent to Avo Inspector via a tag-configuration table, without modding the template.

**Architecture:** Everything lives in one file, `template.tpl`, a GTM server-side custom template with delimited sections (`___TEMPLATE_PARAMETERS___` = tag UI as JSON, `___SANDBOXED_JS_FOR_SERVER___` = tag code, `___TESTS___` = YAML test scenarios). A new `SIMPLE_TABLE` parameter provides an include-list; `extractSchema()` subtracts those names from its hardcoded `commonFields` exclusion list before filtering. Release metadata lives in `metadata.yaml`.

**Tech Stack:** GTM server-side template (sandboxed JavaScript — ES5.1-like, no `Date`/`RegExp`/crypto; APIs come from `require(...)`), GTM Template Editor for tests, YAML test scenarios embedded in the `.tpl`.

**Spec:** `docs/superpowers/specs/2026-07-02-configurable-common-fields-design.md`

## Global Constraints

- With `includeCommonFields` unset/empty, behavior must be byte-for-byte identical to today (regression pin in Task 1).
- Include matching: exact string match against the default list, after `trim()` of the row value. Unknown names / empty rows are ignored (fail-safe: field stays excluded).
- The include applies at every nesting level, mirroring how exclusion works today.
- `x-sst-` / `x-ga-` prefix filters stay unconditional — those keys can never be opted in.
- `user_id` must never be used as `anonymousId`/`streamId` regardless of this setting (existing test "Does not use user_id as anonymousId" must keep passing).
- No new GTM permissions (reading template parameters requires none) — do not touch `___SERVER_PERMISSIONS___`.
- Sandboxed JS: keep to the file's existing idiom (`let`/`const`, `var` loop indices, `getType()` instead of `typeof`, no arrow functions in new code except where the file already uses them).
- `libVersion` becomes `'2.1.0'` (Task 4).

## How to run the tests (all tasks)

There is no CLI test runner for `.tpl` files. Tests run in the **GTM Template Editor**:

1. Open a **server** container at tagmanager.google.com → Templates → New (or a scratch dev template — do NOT trust any existing editor draft; the live editor copy has drifted from this repo before).
2. Menu (⋮) → Import → select the repo's `template.tpl` from the current branch (or paste its full contents).
3. Tests tab → **Run All Tests**.

Baseline before this plan: **13 scenarios, all passing**. After this plan: **17 scenarios, all passing**.

If you are an agent that cannot reach the GTM editor: still perform the test-authoring and implementation steps exactly as written, state clearly that the editor runs were NOT performed, and leave the editor verification to the human. Do not claim tests pass.

---

### Task 1: Regression test pinning default exclusion behavior

**Files:**
- Modify: `template.tpl` — `___TESTS___` section; append after the last scenario ("Surfaces failedEventIds when a value violates the spec (dev)", ends line ~1365, just before `___NOTES___`)

**Interfaces:**
- Consumes: current `extractSchema()` behavior (excludes `commonFields` names at every level).
- Produces: scenario name "Excludes common fields from the schema by default" — later tasks must keep it passing.

- [ ] **Step 1: Append the regression scenario to `___TESTS___`**

Insert before the `___NOTES___` line, keeping one blank line before `___NOTES___` (match the two-space YAML indentation of existing scenarios exactly):

```yaml
- name: Excludes common fields from the schema by default
  code: |-
    const mockData = { inspectorKey: "test-key", environment: "prod" };

    mock('getAllEventData', function() {
      return {
        event_name: 'purchase',
        client_id: 'c1',
        page_hostname: 'example.com',
        user_id: 'user-1',
        currency: 'USD',
        value: 42,
        custom_prop: 'hello'
      };
    });
    mock('getClientName', function() { return 'test_client'; });
    mock('getContainerVersion', function() { return { previewMode: false }; });

    let capturedTrackBody = null;
    mock('sendHttpRequest', function(url, options, body) {
      if (url.indexOf('/inspector/gtm/v1/track') !== -1) { capturedTrackBody = body; }
      return { then: function(onResolve) { onResolve({ statusCode: 200 }); return { catch: function() {} }; } };
    });

    runCode(mockData);

    assertThat(capturedTrackBody).isNotEqualTo(null);
    const props = JSON.parse(capturedTrackBody)[0].eventProperties;
    let names = [];
    for (let i = 0; i < props.length; i++) { names.push(props[i].propertyName); }
    assertThat(names.indexOf('user_id')).isEqualTo(-1);
    assertThat(names.indexOf('currency')).isEqualTo(-1);
    assertThat(names.indexOf('value')).isEqualTo(-1);
    assertThat(names.indexOf('client_id')).isEqualTo(-1);
    assertThat(names.indexOf('page_hostname')).isEqualTo(-1);
    assertThat(names.indexOf('custom_prop')).isNotEqualTo(-1);
```

- [ ] **Step 2: Run the suite in the GTM Template Editor**

Run: import `template.tpl` → Tests → Run All Tests.
Expected: **14/14 pass** (this scenario pins current behavior, so it passes before any code change).

- [ ] **Step 3: Commit**

```bash
git add template.tpl
git commit -m "test: pin default common-field exclusion behavior"
```

---

### Task 2: `includeCommonFields` UI parameter

**Files:**
- Modify: `template.tpl` — `___TEMPLATE_PARAMETERS___` section (lines 34–62)

**Interfaces:**
- Produces: `data.includeCommonFields` — `undefined` (tags configured before this parameter existed / left empty) **or** an array of rows `{ fieldName: string }`. Task 3's implementation and tests rely on this exact name and row shape.

- [ ] **Step 1: Add the SIMPLE_TABLE parameter**

In `___TEMPLATE_PARAMETERS___`, add a comma after the closing brace of the `environment` SELECT object and insert before the closing `]`:

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

- [ ] **Step 2: Verify the template still loads and tests still pass**

Run: import `template.tpl` into the Template Editor. Check the Fields tab renders "Common fields to include in Inspector schemas" as an empty table with an "Add field" button, then Tests → Run All Tests.
Expected: template imports without JSON errors; **14/14 pass** (parameter is not read by code yet).

- [ ] **Step 3: Commit**

```bash
git add template.tpl
git commit -m "feat: add includeCommonFields table to tag configuration"
```

---

### Task 3: Include-list subtraction in `extractSchema` (TDD)

**Files:**
- Modify: `template.tpl` — `___TESTS___` section (append 3 scenarios) and `extractSchema()` in `___SANDBOXED_JS_FOR_SERVER___` (the `commonFields` literal ends at line ~495)

**Interfaces:**
- Consumes: `data.includeCommonFields` rows `{ fieldName: string }` from Task 2; `commonFields` `let`-declared array in `extractSchema()`.
- Produces: `extractSchema()` honoring the include list at every nesting level. No new function names — the subtraction is inline in `extractSchema()`.

- [ ] **Step 1: Append three failing scenarios to `___TESTS___`**

Insert after Task 1's scenario, before `___NOTES___`:

```yaml
- name: Includes opted-in common fields in the schema
  code: |-
    const mockData = {
      inspectorKey: "test-key",
      environment: "prod",
      includeCommonFields: [
        { fieldName: 'user_id' },
        { fieldName: 'currency' },
        { fieldName: ' value ' }
      ]
    };

    mock('getAllEventData', function() {
      return {
        event_name: 'purchase',
        client_id: 'c1',
        page_hostname: 'example.com',
        user_id: 'user-1',
        currency: 'USD',
        value: 42
      };
    });
    mock('getClientName', function() { return 'test_client'; });
    mock('getContainerVersion', function() { return { previewMode: false }; });

    let capturedTrackBody = null;
    mock('sendHttpRequest', function(url, options, body) {
      if (url.indexOf('/inspector/gtm/v1/track') !== -1) { capturedTrackBody = body; }
      return { then: function(onResolve) { onResolve({ statusCode: 200 }); return { catch: function() {} }; } };
    });

    runCode(mockData);

    assertThat(capturedTrackBody).isNotEqualTo(null);
    const parsed = JSON.parse(capturedTrackBody);
    const props = parsed[0].eventProperties;
    let userIdProp = null;
    let currencyProp = null;
    let valueProp = null;
    let clientIdProp = null;
    for (let i = 0; i < props.length; i++) {
      if (props[i].propertyName === 'user_id') userIdProp = props[i];
      if (props[i].propertyName === 'currency') currencyProp = props[i];
      if (props[i].propertyName === 'value') valueProp = props[i];
      if (props[i].propertyName === 'client_id') clientIdProp = props[i];
    }
    assertThat(userIdProp).isNotEqualTo(null);
    assertThat(userIdProp.propertyType).isEqualTo('string');
    assertThat(currencyProp).isNotEqualTo(null);
    assertThat(currencyProp.propertyType).isEqualTo('string');
    // ' value ' row proves fieldName is trimmed before matching
    assertThat(valueProp).isNotEqualTo(null);
    assertThat(valueProp.propertyType).isEqualTo('int');
    // common fields NOT listed stay excluded
    assertThat(clientIdProp).isEqualTo(null);
    // anonymity unaffected: user_id never becomes the stream/anonymous id
    assertThat(parsed[0].anonymousId).isEqualTo('c1');
    assertThat(parsed[0].streamId).isEqualTo('c1');

- name: Opted-in common field also appears inside nested objects
  code: |-
    const mockData = {
      inspectorKey: "test-key",
      environment: "prod",
      includeCommonFields: [ { fieldName: 'currency' } ]
    };

    mock('getAllEventData', function() {
      return {
        event_name: 'purchase',
        client_id: 'c1',
        page_hostname: 'example.com',
        items: [ { currency: 'USD', price: 9 } ]
      };
    });
    mock('getClientName', function() { return 'test_client'; });
    mock('getContainerVersion', function() { return { previewMode: false }; });

    let capturedTrackBody = null;
    mock('sendHttpRequest', function(url, options, body) {
      if (url.indexOf('/inspector/gtm/v1/track') !== -1) { capturedTrackBody = body; }
      return { then: function(onResolve) { onResolve({ statusCode: 200 }); return { catch: function() {} }; } };
    });

    runCode(mockData);

    assertThat(capturedTrackBody).isNotEqualTo(null);
    const props = JSON.parse(capturedTrackBody)[0].eventProperties;
    let itemsProp = null;
    for (let i = 0; i < props.length; i++) {
      if (props[i].propertyName === 'items') itemsProp = props[i];
    }
    assertThat(itemsProp).isNotEqualTo(null);
    // items.children[0] is the element schema (double-bracketed, see list-of-objects tests)
    const elementEntries = itemsProp.children[0];
    let currencyEntry = null;
    let priceEntry = null;
    for (let j = 0; j < elementEntries.length; j++) {
      if (elementEntries[j].propertyName === 'currency') currencyEntry = elementEntries[j];
      if (elementEntries[j].propertyName === 'price') priceEntry = elementEntries[j];
    }
    assertThat(currencyEntry).isNotEqualTo(null);
    assertThat(currencyEntry.propertyType).isEqualTo('string');
    assertThat(priceEntry).isNotEqualTo(null);

- name: Unknown or empty include rows change nothing
  code: |-
    const mockData = {
      inspectorKey: "test-key",
      environment: "prod",
      includeCommonFields: [
        { fieldName: 'userid' },
        { fieldName: '' },
        { fieldName: '   ' },
        { fieldName: 'not_a_common_field' }
      ]
    };

    mock('getAllEventData', function() {
      return {
        event_name: 'purchase',
        client_id: 'c1',
        page_hostname: 'example.com',
        user_id: 'user-1',
        currency: 'USD',
        custom_prop: 'hello'
      };
    });
    mock('getClientName', function() { return 'test_client'; });
    mock('getContainerVersion', function() { return { previewMode: false }; });

    let capturedTrackBody = null;
    mock('sendHttpRequest', function(url, options, body) {
      if (url.indexOf('/inspector/gtm/v1/track') !== -1) { capturedTrackBody = body; }
      return { then: function(onResolve) { onResolve({ statusCode: 200 }); return { catch: function() {} }; } };
    });

    runCode(mockData);

    assertThat(capturedTrackBody).isNotEqualTo(null);
    const props = JSON.parse(capturedTrackBody)[0].eventProperties;
    let names = [];
    for (let i = 0; i < props.length; i++) { names.push(props[i].propertyName); }
    assertThat(names.indexOf('user_id')).isEqualTo(-1);
    assertThat(names.indexOf('currency')).isEqualTo(-1);
    assertThat(names.indexOf('custom_prop')).isNotEqualTo(-1);
```

- [ ] **Step 2: Run the suite — verify the new scenarios fail correctly**

Run: Template Editor → Tests → Run All Tests.
Expected: **15/17 pass.** "Includes opted-in common fields in the schema" and "Opted-in common field also appears inside nested objects" FAIL (the include list is ignored, so `userIdProp`/`currencyEntry` are null). "Unknown or empty include rows change nothing" PASSES already — it pins fail-safe behavior and must stay green after implementation.

- [ ] **Step 3: Implement the subtraction in `extractSchema`**

In `extractSchema()`, immediately after the closing `];` of the `commonFields` array literal (line ~495) and before `let mapping = ...`, insert:

```js
  // Subtract user-opted-in fields (tag config) from the default exclusion
  // list. Exact match after trim; unknown names match nothing (fail-safe).
  // The x-sst-/x-ga- prefix filter below stays unconditional.
  const included = data.includeCommonFields;
  if (getType(included) === 'array' && included.length > 0) {
    let filtered = [];
    for (var ci = 0; ci < commonFields.length; ci++) {
      let keep = true;
      for (var ii = 0; ii < included.length; ii++) {
        var row = included[ii];
        if (row && getType(row.fieldName) === 'string' &&
            row.fieldName.trim() === commonFields[ci]) {
          keep = false;
          break;
        }
      }
      if (keep) filtered.push(commonFields[ci]);
    }
    commonFields = filtered;
  }
```

(`commonFields` is `let`-declared, so reassignment is fine. `extractSchema` runs once per event; 27 × rows comparisons is negligible.)

- [ ] **Step 4: Run the suite — verify everything passes**

Run: Template Editor → Tests → Run All Tests.
Expected: **17/17 pass**, including the Task 1 regression pin and the pre-existing "Does not use user_id as anonymousId (must stay anonymous)".

- [ ] **Step 5: Commit**

```bash
git add template.tpl
git commit -m "feat: make common-field exclusions configurable via includeCommonFields"
```

---

### Task 4: Release prep — libVersion, INFO description, README, metadata.yaml

**Files:**
- Modify: `template.tpl` — `generateBaseBody()` line ~106 and the `___INFO___` `description` (line 25)
- Modify: `README.md` — new section after "Anonymous ID / Stream ID"
- Modify: `metadata.yaml` — new top version entry

**Interfaces:**
- Consumes: feature shipped in Tasks 2–3 (parameter display name is quoted in the README — keep them in sync).
- Produces: release-ready branch; `metadata.yaml` placeholder sha to be replaced post-merge.

- [ ] **Step 1: Bump libVersion**

In `generateBaseBody()` change:

```js
    libVersion: '2.0.0',
```

to:

```js
    libVersion: '2.1.0',
```

- [ ] **Step 2: Extend the `___INFO___` description**

Change the `description` value (line 25) to:

```json
  "description": "Sends event metadata to Avo Inspector for tracking health monitoring. Resolves anonymous ID from event data as stream ID. Validates events against the tracking plan in dev/staging environments. Common GTM/GA4 fields are excluded from schemas by default and can be opted back in via tag configuration.",
```

(Leave `"version": 1` in `___INFO___` untouched — the gallery versions by commit sha, not this field.)

- [ ] **Step 3: Add README section**

In `README.md`, insert between the "Anonymous ID / Stream ID" section (ends line 16) and "## Event Validation (dev/staging only)":

```markdown
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
```

- [ ] **Step 4: Add metadata.yaml version entry**

Replace:

```yaml
versions:
  # Latest version
  - sha: e93efa7800f0dd4b636ded1ddfa3f738fc7bf677
```

with:

```yaml
versions:
  # Latest version
  # NOTE: placeholder sha — replace with the real merge commit sha after this PR merges.
  - sha: 0000000000000000000000000000000000000000
    changeNotes: |2
      Feature: configurable common-field exclusions. New "Common fields to include in Inspector schemas" tag parameter opts default-excluded fields (e.g. user_id, currency) back into the Inspector event schema. Defaults unchanged when the table is empty; only property names and types are ever sent. libVersion 2.1.0.
  # Older versions
  - sha: e93efa7800f0dd4b636ded1ddfa3f738fc7bf677
```

(Keep the existing `changeNotes` under the e93efa7 entry exactly as they are; only the `# Latest version` / `# Older versions` comments move.)

- [ ] **Step 5: Final full verification**

Run: Template Editor → import `template.tpl` → Tests → Run All Tests. Also `git diff master --stat` to confirm only `template.tpl`, `README.md`, `metadata.yaml`, and `docs/superpowers/**` changed.
Expected: **17/17 pass**; diff touches only those files.

- [ ] **Step 6: Commit**

```bash
git add template.tpl README.md metadata.yaml
git commit -m "release: libVersion 2.1.0, docs and version entry for configurable common fields"
```

---

## Post-merge follow-up (not part of this branch)

1. Replace the placeholder sha in `metadata.yaml` with the real merge commit sha (see memory: release flow) in a follow-up commit/PR.
2. Tell Dave B: update the template from the gallery (re-link), then add `user_id` and `currency` rows to "Common fields to include in Inspector schemas" — no re-modding needed.
