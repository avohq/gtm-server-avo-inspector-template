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
const logToConsole = require('logToConsole');
const getAllEventData = require('getAllEventData');
const getClientName = require('getClientName');
const sendHttpRequest = require('sendHttpRequest');

let sessionId = "";

let gtmEvent = getAllEventData();

logToConsole(gtmEvent);

let schemasToSend = [];
logToConsole(schemasToSend);
const sessionBody = handleSession(gtmEvent);
if (sessionBody && schemasToSend.length == 0) {
  schemasToSend.push(sessionBody);
}
logToConsole(schemasToSend);

const eventBody = handleEvent(gtmEvent);
schemasToSend.push(eventBody);
logToConsole(schemasToSend);

if (schemasToSend.length > 0) {
  sendData(schemasToSend);
} else {
  data.gtmOnSuccess();
}

function generateBaseBody(gtmEvent) {
  return {
    apiKey: data.inspectorKey,
    appName:
      gtmEvent.page_hostname != null ? gtmEvent.page_hostname : 'unnamed GTM server-side tag',
    env: data.environment,
    appVersion: 'unversioned GTM server-side tag',
    libVersion: '1.0.0',
    libPlatform: getClientName(), 
    messageId: uniqueid(gtmEvent.event_name),
    createdAt: getTimestampMillis().toString(),
    avoFunction: false
  };
}

function handleSession(gtmEvent) {
  let sessionBody = generateBaseBody(gtmEvent);
  sessionBody.type = 'sessionStarted';
  sessionBody.sessionId = uniqueid();
  
  sessionId = sessionBody.sessionId;

  return sessionBody;
}

function handleEvent(gtmEvent) {
  let eventBody = generateBaseBody(gtmEvent);
  eventBody.type = 'event';
  eventBody.eventName = gtmEvent.event_name;
  logToConsole(eventBody);
  eventBody.eventProperties = extractSchema(gtmEvent);
  eventBody.sessionId = sessionId;
  logToConsole("2", eventBody);

  return eventBody;
}

function sendData(body) {
  const endpoint = 'https://api.avo.app/inspector/gtm/v1/track';
  const postBody = JSON.stringify(body);

  logToConsole("Sending", postBody);
  
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
     logToConsole("Network request result: ", result.body ? result.body : result, "code", result.statusCode);
    if (result.statusCode >= 200 && result.statusCode < 300) {
      logToConsole("data.gtmOnSuccess()");
      data.gtmOnSuccess();
    } else {
      logToConsole("Failed with", result.status);
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
        logToConsole("checking", key, "common", commonFields);
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
  },
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
  }
]


___TESTS___

scenarios: []


___NOTES___

Created on 07/05/2023, 13:31:37


