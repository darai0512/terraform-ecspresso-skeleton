// $node rateLimit.test.js
const fs = require('node:fs')
const js = fs.readFileSync(__dirname + '/rateLimit.js', 'utf-8')
eval(js)
// evalがヤダなら 元ファイルの関数をglobal定義してrequire('./rateLimit')
const assert = require('node:assert').strict

const event = {
    "version": "1.0",
    "context": {
        "eventType": "viewer-request"
    },
    "viewer": {
        "ip": "1.2.3.4"
    },
    "request": {
        "method": "POST",
        "uri": "/sample",
        "headers": {
            "authorization": {
                "value": "Basic aG9nZQo="
            }
        },
        "cookies": {},
        "querystring": {}
    }
}
const expected = {
   "headers": {
       "authorization": {
           "value": "Basic aG9nZQo="
       },
       "rate-limit": {
           "value": "high"
       }
   },
   "method": "POST",
       "querystring": {},
   "uri": "/sample",
       "cookies": {}
}
handler(event).then(r => {
    assert.deepEqual(r, expected)
}).catch(e => assert(false, e))
