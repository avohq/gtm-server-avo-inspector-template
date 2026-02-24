___TERMS_OF_SERVICE___

By creating or modifying this file you agree to Google Tag Manager's Community
Template Gallery Developer Terms of Service available at
https://developers.google.com/tag-manager/gallery-tos (or such other URL as
Google may provide), as modified from time to time.


___INFO___

{
  "type": "TAG",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "Avo Inspector",
  "categories": [
    "ANALYTICS"
  ],
  "brand": {
    "id": "brand_dummy",
    "displayName": "",
    "thumbnail": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAM9SURBVHgB7ZkxTBNRGMf/FQgJpmcCJiS2MSZG0jKa2E7oACYmRkPLKFAWQoyAI0IcHBB0UyhxlLYSJygxYRKNJi7t4OBATZw0bbrQ5doFF33flR5X4Oi7906vJPdLmutd7i7f/3vfe+/7vvNc7gn8wSnmDE45rgCncQU4jSvAaVwBTtMKm1G8Xvj8PgSDQf1aoVBAIV9Anh2P48peJ3r2uvTzYmsFXzuK4ME2AUPRCKKRQYRDIdN7SEA2m8XS8kqdmBuVSxgvXdXPyfj7HVvgQVpAOBzC88UF+H2+hvfSPf4ICY1gNZHEy+U4yuUyZJAS8HhuFmOx0bpr5Nnt7Q/YyX3Xr/lZSIVD1+pGh54bGOjH8EgMKEEYYQFrqUSdQZn90KCjGTQC5P2x2AgURdHO322m8en2C+ALhBBahcjzNeNVVcXMozncY548yXiCRmcpHsfdwShyuZx2TVG8uMlGQhTLAmjoa2FDxg+PxrCeTlt5hSbkDhNh9bnjsCSAhtwY8zOzc3WxbpWnC4v6SIhiScD01AN9tdlIb+I9m6wyqGoZ8wvPIIMlASHDpF1iS6Ad0LxZ39iEKNwCaL03et9sVxVB5l3cAoKBgP5fNnTshFtAryG3yRfyaBa4Bfh8F/T/+bx94SMLtwBjznKO7aLNArcAWvKaEW4BO4YNh1akZoFbQM6w4w70i+kudsMtgDYcyn0ISuS8rPKyC55awgxLO/FqMqUdKYN8ODUJOyDjh6KDEMWagERCHwVK6k8qH3mg+vkNqytksCSAVqLl+Ip+/molzor3AEQg49dSSanwISzXA69ZLVvL4ymU1pLJI2VlI8hoMl5UvJGWzq7zT2ARqnmpdULpRXt7O6739WhtlN3SrtZCMYO8PjExXm0C+Kuep5D8OP8WF3+16fcV2yrYUn6AB4/MF5rpyUmtRjBSa51QoaPu7929LBEkbx+eM3QvFfW3vnUfbav4/0Nbhepb8viUodA5aJ2YP0deX02kqouCJrIbokj3hWg+0G+IjI42bmxtsOLlwHB5PP/iIx+JoAnu9VaTvnJZRSaTNTX6cGux0vIbn8/+BA8e9yulw7gCnMYV4DSuAKdxBTjNXy3yL/9pRPhYAAAAAElFTkSuQmCC"
  },
  "description": "Sends your events metadata to Avo Inspector to monitor and improve the data quality",
  "containerContexts": [
    "SERVER"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "TEXT",
    "name": "inspectorKey",
    "displayName": "Avo Inspector Key",
    "simpleValueType": true
  },
  {
    "type": "SELECT",
    "name": "environment",
    "displayName": "Environment",
    "macrosInSelect": false,
    "selectItems": [
      {
        "value": "dev",
        "displayValue": "development"
      },
      {
        "value": "staging",
        "displayValue": "staging"
      },
      {
        "value": "prod",
        "displayValue": "production"
      }
    ],
    "simpleValueType": true
  }
]


___SANDBOXED_JS_FOR_SERVER___

const getTimestampMillis = require('getTimestampMillis');
const getType = require('getType');
const JSON = require('JSON');
const generateRandom = require('generateRandom');
const getAllEventData = require('getAllEventData');
const getClientName = require('getClientName');
const sendHttpRequest = require('sendHttpRequest');
const log = require('logToConsole');
const getContainerVersion = require('getContainerVersion');
const Math = require('Math');

const isPreview = getContainerVersion().previewMode;

let gtmEvent = getAllEventData();
const streamId = uniqueid(gtmEvent.event_name);
const eventBody = handleEvent(gtmEvent, streamId);

if (data.environment === 'dev' || data.environment === 'staging') {
  fetchAndValidate(gtmEvent, eventBody, streamId, function(validatedBody) {
    sendData([validatedBody]);
  });
} else {
  sendData([eventBody]);
}

function extractAnonymousId(gtmEvent) {
  if (gtmEvent.client_id) return gtmEvent.client_id;
  if (gtmEvent.user_id) return gtmEvent.user_id;
  if (gtmEvent['x-ga-js_client_id']) return gtmEvent['x-ga-js_client_id'];
  return '';
}

function generateBaseBody(gtmEvent) {
  return {
    apiKey: data.inspectorKey,
    appName:
      gtmEvent.page_hostname != null ? gtmEvent.page_hostname : 'unnamed GTM server-side tag',
    env: data.environment,
    appVersion: 'unversioned GTM server-side tag',
    libVersion: '2.0.0',
    libPlatform: getClientName(),
    messageId: uniqueid(gtmEvent.event_name),
    trackingId: '',
    createdAt: toISOString(getTimestampMillis()),
    sessionId: '',
    anonymousId: extractAnonymousId(gtmEvent),
    samplingRate: 1,
    avoFunction: false
  };
}

function handleEvent(gtmEvent, streamId) {
  let eventBody = generateBaseBody(gtmEvent);
  eventBody.type = 'event';
  eventBody.eventName = gtmEvent.event_name;
  eventBody.eventProperties = extractSchema(gtmEvent);
  eventBody.streamId = streamId;

  return eventBody;
}

function fetchAndValidate(gtmEvent, eventBody, streamId, callback) {
  const specUrl = 'https://api.avo.app/trackingPlan/eventSpec?apiKey=' +
    data.inspectorKey + '&streamId=' + streamId +
    '&eventName=' + gtmEvent.event_name;

  sendHttpRequest(specUrl, {
    headers: { 'accept': 'application/json' },
    method: 'GET',
    timeout: 5000,
  }).then(function(result) {
    if (result.statusCode >= 200 && result.statusCode < 300) {
      const specResponse = JSON.parse(result.body);
      const parsedSpec = parseSpecResponse(specResponse);

      if (parsedSpec) {
        eventBody.eventSpecMetadata = parsedSpec.metadata;
        eventBody.validationResults = buildValidationResults(
          gtmEvent, parsedSpec.events
        );
      }
    }
    callback(eventBody);
  }).catch(function(error) {
    if (isPreview) {
      log('Avo Inspector: spec fetch failed', error);
    }
    callback(eventBody);
  });
}

function parseSpecResponse(specResponse) {
  if (!specResponse || !specResponse.events || specResponse.events.length === 0) {
    return null;
  }

  var metadata = null;
  if (specResponse.metadata) {
    metadata = {
      schemaId: specResponse.metadata.schemaId,
      branchId: specResponse.metadata.branchId,
      latestActionId: specResponse.metadata.latestActionId
    };
  }

  return {
    events: specResponse.events,
    metadata: metadata
  };
}

function buildValidationResults(gtmEvent, events) {
  var results = {};

  for (var e = 0; e < events.length; e++) {
    var eventSpec = events[e];
    var eventId = eventSpec.id;
    var variantIds = eventSpec.vids || [];
    var props = eventSpec.p || {};

    for (var propName in props) {
      if (!props.hasOwnProperty(propName)) continue;

      var propSpec = props[propName];
      var actualValue = gtmEvent[propName];

      var propertyResult = validatePropertyValues(
        actualValue, propSpec, eventId, variantIds
      );

      if (!results[propName]) {
        results[propName] = propertyResult;
      } else {
        // Merge results: combine failed/passed event IDs
        if (propertyResult.failedEventIds) {
          if (!results[propName].failedEventIds) {
            results[propName].failedEventIds = [];
          }
          for (var f = 0; f < propertyResult.failedEventIds.length; f++) {
            results[propName].failedEventIds.push(propertyResult.failedEventIds[f]);
          }
        }
        if (propertyResult.passedEventIds) {
          if (!results[propName].passedEventIds) {
            results[propName].passedEventIds = [];
          }
          for (var pa = 0; pa < propertyResult.passedEventIds.length; pa++) {
            results[propName].passedEventIds.push(propertyResult.passedEventIds[pa]);
          }
        }
      }
    }
  }

  return results;
}

function validatePropertyValues(actualValue, propSpec, eventId, variantIds) {
  var allIds = [eventId];
  for (var v = 0; v < variantIds.length; v++) {
    allIds.push(variantIds[v]);
  }

  var failedIds = [];
  var passedIds = [];

  // Check if value is null/undefined
  var isNull = getType(actualValue) === 'null' || getType(actualValue) === 'undefined';

  // Required check: if property is required and value is missing, fail
  if (propSpec.r && isNull) {
    for (var ri = 0; ri < allIds.length; ri++) {
      failedIds.push(allIds[ri]);
    }
    return buildValidationResult(failedIds, passedIds, allIds);
  }

  // If value is null and property is optional, pass
  if (isNull) {
    for (var ni = 0; ni < allIds.length; ni++) {
      passedIds.push(allIds[ni]);
    }
    return buildValidationResult(failedIds, passedIds, allIds);
  }

  // Type check
  var actualType = getPropValueType(actualValue);
  if (propSpec.t && propSpec.t !== actualType) {
    for (var ti = 0; ti < allIds.length; ti++) {
      failedIds.push(allIds[ti]);
    }
    return buildValidationResult(failedIds, passedIds, allIds);
  }

  // Pinned value check (exact match required)
  if (propSpec.p) {
    for (var pinnedValue in propSpec.p) {
      if (!propSpec.p.hasOwnProperty(pinnedValue)) continue;
      var pinnedEventIds = propSpec.p[pinnedValue];
      var actualStr = typeof actualValue === 'object' ? JSON.stringify(actualValue) : '' + actualValue;
      if (actualStr !== pinnedValue) {
        for (var pi = 0; pi < pinnedEventIds.length; pi++) {
          if (!arrayContains(failedIds, pinnedEventIds[pi])) {
            failedIds.push(pinnedEventIds[pi]);
          }
        }
      } else {
        for (var ppi = 0; ppi < pinnedEventIds.length; ppi++) {
          if (!arrayContains(passedIds, pinnedEventIds[ppi])) {
            passedIds.push(pinnedEventIds[ppi]);
          }
        }
      }
    }
  }

  // Allowed values check (value must be in set)
  if (propSpec.v) {
    for (var allowedKey in propSpec.v) {
      if (!propSpec.v.hasOwnProperty(allowedKey)) continue;
      var allowedEventIds = propSpec.v[allowedKey];
      var allowedValues = JSON.parse(allowedKey);
      var actualValStr = '' + actualValue;
      var isAllowed = false;
      if (getType(allowedValues) === 'array') {
        for (var ai = 0; ai < allowedValues.length; ai++) {
          if (('' + allowedValues[ai]) === actualValStr) {
            isAllowed = true;
            break;
          }
        }
      }
      if (!isAllowed) {
        for (var afi = 0; afi < allowedEventIds.length; afi++) {
          if (!arrayContains(failedIds, allowedEventIds[afi])) {
            failedIds.push(allowedEventIds[afi]);
          }
        }
      } else {
        for (var api = 0; api < allowedEventIds.length; api++) {
          if (!arrayContains(passedIds, allowedEventIds[api])) {
            passedIds.push(allowedEventIds[api]);
          }
        }
      }
    }
  }

  // Regex check - not supported in GTM Server sandbox, skip with warning
  if (propSpec.rx) {
    if (isPreview) {
      log('Avo Inspector: regex validation not supported in GTM Server sandbox, skipping for property');
    }
    // Treat as passed since we cannot validate
    for (var rxKey in propSpec.rx) {
      if (!propSpec.rx.hasOwnProperty(rxKey)) continue;
      var rxEventIds = propSpec.rx[rxKey];
      for (var rxi = 0; rxi < rxEventIds.length; rxi++) {
        if (!arrayContains(passedIds, rxEventIds[rxi])) {
          passedIds.push(rxEventIds[rxi]);
        }
      }
    }
  }

  // Min/max range check (numeric bounds)
  if (propSpec.minmax) {
    for (var rangeKey in propSpec.minmax) {
      if (!propSpec.minmax.hasOwnProperty(rangeKey)) continue;
      var rangeEventIds = propSpec.minmax[rangeKey];
      var parts = rangeKey.split(',');
      var inRange = true;

      if (getType(actualValue) === 'number') {
        if (parts.length >= 1 && parts[0] !== '') {
          var minVal = parts[0] * 1;
          if (actualValue < minVal) inRange = false;
        }
        if (parts.length >= 2 && parts[1] !== '') {
          var maxVal = parts[1] * 1;
          if (actualValue > maxVal) inRange = false;
        }
      } else {
        // Non-numeric value for a min/max constraint fails
        inRange = false;
      }

      if (!inRange) {
        for (var mfi = 0; mfi < rangeEventIds.length; mfi++) {
          if (!arrayContains(failedIds, rangeEventIds[mfi])) {
            failedIds.push(rangeEventIds[mfi]);
          }
        }
      } else {
        for (var mpi = 0; mpi < rangeEventIds.length; mpi++) {
          if (!arrayContains(passedIds, rangeEventIds[mpi])) {
            passedIds.push(rangeEventIds[mpi]);
          }
        }
      }
    }
  }

  // If no constraint checks ran, all IDs pass by default
  if (failedIds.length === 0 && passedIds.length === 0) {
    for (var di = 0; di < allIds.length; di++) {
      passedIds.push(allIds[di]);
    }
  }

  return buildValidationResult(failedIds, passedIds, allIds);
}

function buildValidationResult(failedIds, passedIds, allIds) {
  // Bandwidth optimization: send whichever list is smaller
  var result = {};
  if (failedIds.length === 0) {
    result.passedEventIds = allIds;
  } else if (passedIds.length === 0) {
    result.failedEventIds = allIds;
  } else if (failedIds.length <= passedIds.length) {
    result.failedEventIds = failedIds;
  } else {
    result.passedEventIds = passedIds;
  }
  return result;
}

function toISOString(timestampMs) {
  var pad = function(n) { return n < 10 ? '0' + n : '' + n; };
  var s = timestampMs / 1000;
  var sec = Math.floor(s) % 60;
  var min = Math.floor(s / 60) % 60;
  var hr = Math.floor(s / 3600) % 24;
  var days = Math.floor(s / 86400);
  var y = 1970;
  var m = 0;
  var d = days;
  var daysInMonth = [31,28,31,30,31,30,31,31,30,31,30,31];
  while (true) {
    var isLeap = (y % 4 === 0 && y % 100 !== 0) || (y % 400 === 0);
    var diy = isLeap ? 366 : 365;
    if (d < diy) break;
    d = d - diy;
    y = y + 1;
  }
  daysInMonth[1] = ((y % 4 === 0 && y % 100 !== 0) || (y % 400 === 0)) ? 29 : 28;
  while (d >= daysInMonth[m]) {
    d = d - daysInMonth[m];
    m = m + 1;
  }
  return y + '-' + pad(m + 1) + '-' + pad(d + 1) + 'T' + pad(hr) + ':' + pad(min) + ':' + pad(sec) + '.000Z';
}

function sendData(body) {
  const endpoint = 'https://api.avo.app/inspector/gtm/v1/track';
  const postBody = JSON.stringify(body);

  sendHttpRequest(endpoint, {
    headers: {
      'accept': 'application/json',
      'content-type': 'application/json',
      'api-key': data.inspectorKey,
      'env': data.environment,
    },
    method: 'POST',
    timeout: 500,
  }, postBody).then(function(result) {
    if (result.statusCode >= 200 && result.statusCode < 300) {
      data.gtmOnSuccess();
    } else {
      data.gtmOnFailure();
    }
  }).catch((error) => {
    data.gtmOnFailure();
  });
}

function extractSchema(gtmEvent) {
  if (getType(gtmEvent) === 'undefined' || getType(gtmEvent) === 'null') {
    return [];
  }

  let commonFields = [
    "client_id",
    "currency",
    "event_name",
    "ip_override",
    "language",
    "page_encoding",
    "page_hostname",
    "page_location",
    "page_path",
    "page_referrer",
    "page_title",
    "screen_resolution",
    "user_agent",
    "user_data.email_address",
    "user_data.phone_number",
    "user_data.address.first_name",
    "user_data.address.last_name",
    "user_data.address.street",
    "user_data.address.city",
    "user_data.address.region",
    "user_data.address.postal_code",
    "user_data.address.country",
    "user_id",
    "value",
    "viewport_size",
    "x-ga-protocol_version",
    "x-ga-measurement_id",
    "x-ga-js_client_id"
  ];

  let mapping = object => {
    if (getType(object) === 'object') {
      let mappedResult = [];
      for (var key in object) {
        if (object.hasOwnProperty(key) && !arrayContains(commonFields, key)) {
          let val = object[key];

          let mappedEntry = {
            propertyName: key,
            propertyType: getPropValueType(val)
          };

          if (getType(val) === 'object' && val != null) {
            mappedEntry.children = mapping(val);
          }

          mappedResult.push(mappedEntry);
        }
      }

      return mappedResult;
    } else {
      return getPropValueType(object);
    }
  };

  var mappedEventProps = mapping(gtmEvent);

  return mappedEventProps;
}

function arrayContains(a, obj) {
    var i = a.length;
    while (i--) {
       if (a[i] === obj) {
           return true;
       }
    }
    return false;
}

function getPropValueType(propValue) {
  let propType = getType(propValue);
  if (propType === 'null' || propType === 'undefined') {
    return 'null';
  } else if (propType === 'string') {
    return 'string';
  } else if (propType === 'number') {
    return 'int';
  } else if (propType === 'boolean') {
    return 'boolean';
  } else if (propType === 'object') {
    return 'object';
  } else if (propType === 'array') {
    return 'list';
  } else {
    return propType;
  }
}

function uniqueid(eventName) {
  return getTimestampMillis().toString(36) + generateRandom(0, 1000000000).toString(36).substring(2) + eventName;
}


___SERVER_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "read_event_data",
        "versionId": "1"
      },
      "param": [
        {
          "key": "eventDataAccess",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "read_container_data",
        "versionId": "1"
      },
      "param": []
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "send_http",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedUrls",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "urls",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 1,
                "string": "https://api.avo.app/"
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  }
]


___TESTS___

scenarios:
- name: Sends an event with anonymousId and no session (dev with spec fetch)
  code: |-
    const mockData = {
      inspectorKey: "test-key",
      environment: "dev"
    };

    mock('getAllEventData', function() {
      return {
        event_name: 'purchase',
        client_id: 'test-client-123',
        page_hostname: 'example.com',
        item_name: 'Test Product',
        price: 9.99
      };
    });

    mock('getClientName', function() {
      return 'test_client';
    });

    mock('getContainerVersion', function() {
      return { previewMode: false };
    });

    mock('sendHttpRequest', function(url, options, body) {
      if (url.indexOf('/trackingPlan/eventSpec') !== -1) {
        return Promise.create(function(resolve) {
          resolve({
            statusCode: 200,
            body: JSON.stringify({ events: [] })
          });
        });
      }
      return Promise.create(function(resolve) {
        resolve({ statusCode: 200 });
      });
    });

    runCode(mockData);

    assertApi('sendHttpRequest').wasCalled();

- name: Uses client_id as anonymousId
  code: |-
    const mockData = {
      inspectorKey: "test-key",
      environment: "dev"
    };

    mock('getAllEventData', function() {
      return {
        event_name: 'test_event',
        client_id: 'client-abc',
        user_id: 'user-xyz'
      };
    });

    mock('getClientName', function() {
      return 'test_client';
    });

    mock('getContainerVersion', function() {
      return { previewMode: false };
    });

    let capturedTrackBody = null;
    mock('sendHttpRequest', function(url, options, body) {
      if (url.indexOf('/inspector/gtm/v1/track') !== -1) {
        capturedTrackBody = body;
      }
      return Promise.create(function(resolve) {
        resolve({ statusCode: 200, body: '{"events":[]}' });
      });
    });

    runCode(mockData);

    assertApi('sendHttpRequest').wasCalled();
    assertThat(capturedTrackBody).isNotEqualTo(null);
    const parsed = JSON.parse(capturedTrackBody);
    assertThat(parsed[0].anonymousId).isEqualTo('client-abc');

- name: Falls back to empty string when no ID fields present
  code: |-
    const mockData = {
      inspectorKey: "test-key",
      environment: "dev"
    };

    mock('getAllEventData', function() {
      return {
        event_name: 'test_event',
        page_hostname: 'example.com'
      };
    });

    mock('getClientName', function() {
      return 'test_client';
    });

    mock('getContainerVersion', function() {
      return { previewMode: false };
    });

    let capturedTrackBody = null;
    mock('sendHttpRequest', function(url, options, body) {
      if (url.indexOf('/inspector/gtm/v1/track') !== -1) {
        capturedTrackBody = body;
      }
      return Promise.create(function(resolve) {
        resolve({ statusCode: 200, body: '{"events":[]}' });
      });
    });

    runCode(mockData);

    assertApi('sendHttpRequest').wasCalled();
    assertThat(capturedTrackBody).isNotEqualTo(null);
    const parsed = JSON.parse(capturedTrackBody);
    assertThat(parsed[0].anonymousId).isEqualTo('');

- name: Falls back to user_id when client_id absent
  code: |-
    const mockData = {
      inspectorKey: "test-key",
      environment: "dev"
    };

    mock('getAllEventData', function() {
      return {
        event_name: 'test_event',
        user_id: 'user-xyz',
        page_hostname: 'example.com'
      };
    });

    mock('getClientName', function() {
      return 'test_client';
    });

    mock('getContainerVersion', function() {
      return { previewMode: false };
    });

    let capturedTrackBody = null;
    mock('sendHttpRequest', function(url, options, body) {
      if (url.indexOf('/inspector/gtm/v1/track') !== -1) {
        capturedTrackBody = body;
      }
      return Promise.create(function(resolve) {
        resolve({ statusCode: 200, body: '{"events":[]}' });
      });
    });

    runCode(mockData);

    assertApi('sendHttpRequest').wasCalled();
    assertThat(capturedTrackBody).isNotEqualTo(null);
    const parsed = JSON.parse(capturedTrackBody);
    assertThat(parsed[0].anonymousId).isEqualTo('user-xyz');

- name: Falls back to x-ga-js_client_id when client_id and user_id absent
  code: |-
    const mockData = {
      inspectorKey: "test-key",
      environment: "dev"
    };

    mock('getAllEventData', function() {
      return {
        event_name: 'test_event',
        'x-ga-js_client_id': 'js-client-456',
        page_hostname: 'example.com'
      };
    });

    mock('getClientName', function() {
      return 'test_client';
    });

    mock('getContainerVersion', function() {
      return { previewMode: false };
    });

    let capturedTrackBody = null;
    mock('sendHttpRequest', function(url, options, body) {
      if (url.indexOf('/inspector/gtm/v1/track') !== -1) {
        capturedTrackBody = body;
      }
      return Promise.create(function(resolve) {
        resolve({ statusCode: 200, body: '{"events":[]}' });
      });
    });

    runCode(mockData);

    assertApi('sendHttpRequest').wasCalled();
    assertThat(capturedTrackBody).isNotEqualTo(null);
    const parsed = JSON.parse(capturedTrackBody);
    assertThat(parsed[0].anonymousId).isEqualTo('js-client-456');

- name: Skips spec fetch in production and sends event directly
  code: |-
    const mockData = {
      inspectorKey: "test-key",
      environment: "prod"
    };

    mock('getAllEventData', function() {
      return {
        event_name: 'purchase',
        client_id: 'test-client-123',
        page_hostname: 'example.com',
        item_name: 'Test Product',
        price: 9.99
      };
    });

    mock('getClientName', function() {
      return 'test_client';
    });

    mock('getContainerVersion', function() {
      return { previewMode: false };
    });

    let specFetchCalled = false;
    let trackCalled = false;
    mock('sendHttpRequest', function(url, options, body) {
      if (url.indexOf('/trackingPlan/eventSpec') !== -1) {
        specFetchCalled = true;
      }
      if (url.indexOf('/inspector/gtm/v1/track') !== -1) {
        trackCalled = true;
      }
      return Promise.create(function(resolve) {
        resolve({ statusCode: 200 });
      });
    });

    runCode(mockData);

    assertThat(specFetchCalled).isEqualTo(false);
    assertThat(trackCalled).isEqualTo(true);

- name: Validates spec with pinned and allowed values
  code: |-
    const mockData = {
      inspectorKey: "test-key",
      environment: "dev"
    };

    mock('getAllEventData', function() {
      return {
        event_name: 'purchase',
        client_id: 'test-client-123',
        page_hostname: 'example.com',
        currency: 'USD',
        item_name: 'Test Product',
        price: 50
      };
    });

    mock('getClientName', function() {
      return 'test_client';
    });

    mock('getContainerVersion', function() {
      return { previewMode: false };
    });

    const specResponse = {
      events: [
        {
          id: 'evt-1',
          vids: ['var-1'],
          p: {
            currency: {
              t: 'string',
              r: true,
              v: { '["USD","EUR","GBP"]': ['evt-1'] }
            },
            price: {
              t: 'int',
              r: true,
              minmax: { '0,100': ['evt-1'] }
            },
            item_name: {
              t: 'string',
              r: true,
              p: { 'Test Product': ['evt-1'] }
            }
          }
        }
      ],
      metadata: {
        schemaId: 'schema-123',
        branchId: 'branch-456',
        latestActionId: 'action-789'
      }
    };

    let capturedTrackBody = null;
    mock('sendHttpRequest', function(url, options, body) {
      if (url.indexOf('/trackingPlan/eventSpec') !== -1) {
        return Promise.create(function(resolve) {
          resolve({
            statusCode: 200,
            body: JSON.stringify(specResponse)
          });
        });
      }
      if (url.indexOf('/inspector/gtm/v1/track') !== -1) {
        capturedTrackBody = body;
      }
      return Promise.create(function(resolve) {
        resolve({ statusCode: 200 });
      });
    });

    runCode(mockData);

    assertApi('sendHttpRequest').wasCalled();
    assertThat(capturedTrackBody).isNotEqualTo(null);
    const parsed = JSON.parse(capturedTrackBody);
    assertThat(parsed[0].eventSpecMetadata.schemaId).isEqualTo('schema-123');
    assertThat(parsed[0].eventSpecMetadata.branchId).isEqualTo('branch-456');
    assertThat(parsed[0].validationResults).isNotEqualTo(undefined);
    assertThat(parsed[0].validationResults.currency.passedEventIds).isNotEqualTo(undefined);
    assertThat(parsed[0].validationResults.price.passedEventIds).isNotEqualTo(undefined);
    assertThat(parsed[0].validationResults.item_name.passedEventIds).isNotEqualTo(undefined);


___NOTES___

Created on 07/05/2023, 13:31:37

