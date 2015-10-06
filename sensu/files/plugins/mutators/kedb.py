#!/usr/bin/env python

import sys
import requests
import json

event = json.load(sys.stdin)

#if event.get('occurences') == 1:

host = event.get('kedb_host', 'localhost')
port = event.get('kedb_port', 6754)
url = 'http://%s:%s/handle/' % (host, port)
#print 'URL============================='
#print url
payload = {
    'event': event,
}

file = open("/tmp/payload", "w")
file.write(json.dumps(payload))
file.close

#print 'PAYLOAD============================='
#print payload
response = requests.post(url, data=json.dumps(payload))
#print 'RESPONSE============================='
#print response
#print 'RESPONSE-DATA=========================='

file = open("/tmp/payload_response", "w")
file.write(json.dumps(response.json()))
file.close

if response.status_code == 200:
    event = response.json()

print json.dumps(event)

sys.exit(0)
