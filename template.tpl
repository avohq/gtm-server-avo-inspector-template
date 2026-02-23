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
    "id": "avo",
    "displayName": "",
    "thumbnail": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAM9SURBVHgB7ZkxTBNRGMf/FQgJpmcCJiS2MSZG0jKa2E7oACYmRkPLKFAWQoyAI0IcHBB0UyhxlLYSJygxYRKNJi7t4OBATZw0bbrQ5doFF33flR5X4Oi7906vJPdLmutd7i7f/3vfe+/7vvNc7gn8wSnmDE45rgCncQU4jSvAaVwBTtMKm1G8Xvj8PgSDQf1aoVBAIV9Anh2P48peJ3r2uvTzYmsFXzuK4ME2AUPRCKKRQYRDIdN7SEA2m8XS8kqdmBuVSxgvXdXPyfj7HVvgQVpAOBzC88UF+H2+hvfSPf4ICY1gNZHEy+U4yuUyZJAS8HhuFmOx0bpr5Nnt7Q/YyX3Xr/lZSIVD1+pGh54bGOjH8EgMKEEYYQFrqUSdQZn90KCjGTQC5P2x2AgURdHO322m8en2C+ALhBBahcjzNeNVVcXMozncY548yXiCRmcpHsfdwShyuZx2TVG8uMlGQhTLAmjoa2FDxg+PxrCeTlt5hSbkDhNh9bnjsCSAhtwY8zOzc3WxbpWnC4v6SIhiScD01AN9tdlIb+I9m6wyqGoZ8wvPIIMlASHDpF1iS6Ad0LxZ39iEKNwCaL03et9sVxVB5l3cAoKBgP5fNnTshFtAryG3yRfyaBa4Bfh8F/T/+bx94SMLtwBjznKO7aLNArcAWvKaEW4BO4YNh1akZoFbQM6w4w70i+cudsMtgDYcyn0ISuS8rPKyC55awgxLO/FqMqUdKYN8ODUJOyDjh6KDEMWagERCHwVK6k4qH3mg+vkNqytksCSAVqLl+Ip+/molzor3AEQg49dSSanwISzXA69ZLVvL4ymU1pLJI2VlI8hoMl5UvJGWzq7zT2ARqnmpdULpRXt7O6739WltlN3SrtZCMYO8PjExXm0C+Kuep5D8OP8WF3+16fcV2yrYUn6AB4/MF5rpyUmtRjBSa51QoaPu7969LBEkbx+eM3QvFfW3vnUfbav4/0Nbhepb8viUodA5aJ2YP0deX02kqouCJrIbokj3hWg+0G+IjI42bmxtsOLlwHB5PP/iIx+JoAnu9VaTvnJZRSaTNTX6cGux0vIbn8/+BA8e9yulw7gCnMYV4DSuAKdxBTjNXy3yL/9pRPhYAAAAAElFTkSuQmCC"
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

let gtmEvent = getAllEventData();
const eventBody = handleEvent(gtmEvent);
validateEvent(gtmEvent, eventBody, function(validatedBody) {
  sendData([validatedBody]);
});

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
    createdAt: getTimestampMillis().toString(),
    anonymousId: extractAnonymousId(gtmEvent),
    avoFunction: false
  };
}

function handleEvent(gtmEvent) {
  let eventBody = generateBaseBody(gtmEvent);
  eventBody.type = 'event';
  eventBody.eventName = gtmEvent.event_name;
  eventBody.eventProperties = extractSchema(gtmEvent);

  return eventBody;
}

function validateEvent(gtmEvent, eventBody, callback) {
  const specUrl = 'https://api.avo.app/inspector/v1/spec?apiKey=' + data.inspectorKey + '&env=' + data.environment;

  sendHttpRequest(specUrl, {
    headers: { 'accept': 'application/json' },
    method: 'GET',
    timeout: 500,
  }).then((result) => {
    if (result.statusCode >= 200 && result.statusCode < 300) {
      const spec = JSON.parse(result.body);
      const eventSpec = findEventSpec(spec, gtmEvent.event_name);
      if (eventSpec) {
        eventBody.streamId = uniqueid(gtmEvent.event_name);
        eventBody.eventSpecMetadata = {
          eventId: eventSpec.id,
          eventHash: eventSpec.hash
        };
        eventBody.validationResults = validateProperties(gtmEvent, eventSpec);
      }
    }
    callback(eventBody);
  }).catch(function() {
    callback(eventBody);
  });
}

function findEventSpec(spec, eventName) {
  if (!spec || !spec.events) return null;
  for (var i = 0; i < spec.events.length; i++) {
    if (spec.events[i].name === eventName) return spec.events[i];
  }
  return null;
}

function validateProperties(gtmEvent, eventSpec) {
  var results = [];
  if (!eventSpec.properties) return results;
  for (var i = 0; i < eventSpec.properties.length; i++) {
    var prop = eventSpec.properties[i];
    var actualValue = gtmEvent[prop.name];
    var actualType = getPropValueType(actualValue);
    results.push({
      propertyName: prop.name,
      expectedType: prop.type,
      actualType: actualType,
      valid: prop.type === actualType || (prop.optional && actualType === 'null')
    });
  }
  return results;
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
  }, postBody).then((result) => {
    if (result.statusCode >= 200 && result.statusCode < 300) {
      data.gtmOnSuccess();
    } else {
      data.gtmOnFailure();
    }
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
        "publicId": "logging",
        "versionId": "1"
      },
      "param": [
        {
          "key": "environments",
          "value": {
            "type": 1,
            "string": "debug"
          }
        }
      ]
    },
    "isRequired": true
  },
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
- name: Sends an event with anonymousId and no session
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

    mock('sendHttpRequest', function(url, options, body) {
      if (url.indexOf('/inspector/v1/spec') !== -1) {
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
    assertApi('sendHttpRequest').wasCalledWith(
      'https://api.avo.app/inspector/v1/spec?apiKey=test-key&env=dev',
      { headers: { accept: 'application/json' }, method: 'GET', timeout: 500 }
    );

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


___NOTES___

Created on 07/05/2023, 13:31:37


