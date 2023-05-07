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
  "categories": ["ANALYTICS"],
  "brand": {
    "id": "brand_dummy",
    "displayName": ""
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

// API reference https://developers.google.com/tag-platform/tag-manager/server-side/api
const getTimestampMillis = require('getTimestampMillis');
const getType = require('getType');
const JSON = require('JSON');
const generateRandom = require('generateRandom');
const logToConsole = require('logToConsole');
const getAllEventData = require('getAllEventData');
const getClientName = require('getClientName');
const sendHttpRequest = require('sendHttpRequest');

// Body
let sessionId = "";

let gtmEvent = getAllEventData();

logToConsole(gtmEvent);

let schemasToSend = [];

const sessionBody = handleSession(gtmEvent);
if (sessionBody && schemasToSend.length == 0) {
  schemasToSend.push(sessionBody);
}

const eventBody = handleEvent(gtmEvent);
schemasToSend.push(eventBody);

if (schemasToSend.length > 0) {
  sendData(schemasToSend);
} else {
  data.gtmOnSuccess();
}

// Functions
function generateBaseBody(gtmEvent) {
  return {
    appName:
      gtmEvent.page_hostname != null ? gtmEvent.page_hostname : 'unnamed GTM server-side tag',
    appVersion: 'unversioned GTM server-side tag',
    libVersion: '1.0.0',
    libPlatform: getClientName(), 
    messageId: uniqueid(),
    trackingId: gtmEvent.client_id != null ? gtmEvent.client_id : gtmEvent.user_id,
    createdAt: getTimestampMillis(), // TODO GTM env does not have access to Date, so it's tricky to convert this into ISO. Can we do it on the server? Should be as easy as `new Date(createdAt).toISOString()`
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
  eventBody.eventProperties = extractSchema(gtmEvent);
  eventBody.sessionId = sessionId;

  return eventBody;
}

function sendData(body) {
  const endpoint = 'https://api.avo.app/inspector/v1/track'; // TODO prepare 'https://api.avo.app/inspector/gtm/v1/track' to accept inspector payloads from GTM

  const postBody = JSON.stringify(body);

  logToConsole("Sending", postBody);
  
  sendHttpRequest(endpoint, {
    headers: {
      'accept': 'application/json',
      'content-type': 'application/json',
      'api-key': data.inspectorKey,
      'env': data.environment, // "dev", "staging", "prod"
    },
    method: 'POST',
    timeout: 500, // TODO verify if default timeout works for us
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
];

function extractSchema(gtmEvent) {
  if (getType(gtmEvent) === 'undefined' || getType(gtmEvent) === 'null') {
    return [];
  }

  let mapping = object => {
    if (getType(object) === 'object') {
      let mappedResult = [];
      for (var key in object) {
        if (object.hasOwnProperty(key) && !commonFields.includes(key)) {
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

function getPropValueType(propValue) {
  let propType = getType(propValue);
  if (propType === 'null' || propType === 'undefined') {
    return 'null';
  } else if (propType === 'string') {
    return 'string';
  } else if (propType === 'number') {
    // TODO we are not using it in JS, right?
/*     if ((propValue + '').indexOf('.') >= 0) {
      return 'float';
    } else { */
    return 'int';
 //   }
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

function uniqueid() {
  return getTimestampMillis().toString(36) + generateRandom(0, 1000000000).toString(36).substring(2);
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
- name: Sends an event
  code: |-
    const mockData = {
      whatevet: "0",
      shouldNotChange: "1"
    };

    runCode(mockData);

    assertApi('sendHttpRequest').wasCalled();


___NOTES___

Created on 07/05/2023, 13:31:37


